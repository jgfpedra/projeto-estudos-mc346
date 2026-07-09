#!/usr/bin/env python3
"""
render_fractal.py — lê o CSV gerado pelo backend Guile e salva PNG.
"""

from matplotlib.colors import LinearSegmentedColormap
from matplotlib.path import Path as MplPath
import matplotlib.pyplot as plt
import argparse
import csv
import sys
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")


# ─── paletas temáticas ────────────────────────────────────────────────────

PALETTES = {
    "green":     ["#0a1a0a", "#1a4a1a", "#2ecc71", "#a8f5a2"],
    "ocean":     ["#020d18", "#0a3d5c", "#1a7abf", "#7fd4f4"],
    "fire":      ["#1a0000", "#7a1a00", "#e05c00", "#ffe066"],
    "teal":      ["#020f0f", "#064a4a", "#0abfbf", "#afffff"],
    "limegreen": ["#0a1a04", "#2a5a0a", "#7ddb2d", "#d4ffaa"],
    "mono":      ["#000000", "#444444", "#aaaaaa", "#ffffff"],
    "gradient":  ["#010a1a", "#0a3d5c", "#1a8fbf", "#5fd0c8",
                  "#a8e6a0", "#e8d98a", "#f5f0e0"],
}

STYLES = {
    "island": {
        "land_color": "#0f2e18",
        "palette":    "limegreen",
        "bg":         "#020d14",
        "clip_decor": True,
        "outline":    True,
    },
    "forest": {
        "land_color": "#0c2410",
        "palette":    "green",
        "bg":         "#040d04",
        "clip_decor": True,
        "outline":    False,
    },
    "mountain": {
        "land_color": "#4a4540",
        "palette":    "mono",
        "bg":         "#10141a",
        "clip_decor": True,
        "outline":    True,
    },
    "cloud": {
        "land_color": None,
        "palette":    "mono",
        "bg":         "#0a1622",
        "clip_decor": False,
        "outline":    False,
    },
}


def load_points(csv_path: str):
    """
    Returns four arrays: xs, ys, types, values.
    'types' contains the string in the 'type' column, or 'point' for
    old CSVs that don't have that column. 'values' holds the per-row
    numeric payload used by escape-time grids (0.0 elsewhere).
    """
    xs, ys, types, values = [], [], [], []
    with open(csv_path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            xs.append(float(row["x"]))
            ys.append(float(row["y"]))
            types.append(row.get("type", "point"))
            raw_value = row.get("value", "")
            values.append(float(raw_value)
                          if raw_value not in ("", None) else 0.0)
    return np.array(xs), np.array(ys), np.array(types), np.array(values)


def make_cmap(palette_name: str):
    colors = PALETTES.get(palette_name, PALETTES["mono"])
    return LinearSegmentedColormap.from_list("fractal", colors, N=512)


def render(csv_path: str, out_path: str, palette: str = None,
           bg: str = None, style: str = "island", dpi: int = 300,
           width: int = 2048, height: int = 2048,
           alpha: float = 0.6, point_size: float = 0.3):

    cfg = STYLES.get(style, STYLES["island"])
    palette = palette or cfg["palette"]
    bg = bg or cfg["bg"]

    xs, ys, types, values = load_points(csv_path)
    print(f"  {len(xs):,} pontos carregados de {csv_path}")

    fig, ax = plt.subplots(figsize=(width / dpi, height / dpi), dpi=dpi)
    fig.patch.set_facecolor(bg)
    ax.set_facecolor(bg)
    ax.axis("off")
    fig.subplots_adjust(left=0, right=1, top=1, bottom=0)

    unique_types = set(types)
    is_escape = "escape" in unique_types
    is_coastline = unique_types & {"coast", "decor"}

    if is_escape:
        px, py = xs.astype(int), ys.astype(int)
        grid_w, grid_h = px.max() + 1, py.max() + 1
        grid = np.zeros((grid_h, grid_w))
        grid[py, px] = values
        max_iter = grid.max()

        inside = grid >= max_iter
        # gamma for smoother bands
        norm = np.clip(grid / max_iter, 0, 1) ** 0.5
        cmap = make_cmap(palette or "gradient")
        rgba = cmap(norm)
        rgba[inside] = (0, 0, 0, 1)  # classic black interior (never escaped)

        ax.imshow(rgba, origin="lower", interpolation="bilinear")

    elif is_coastline:

        coast_mask = types == "coast"
        decor_mask = types == "decor"

        cx, cy = xs[coast_mask], ys[coast_mask]
        dx, dy = xs[decor_mask], ys[decor_mask]

        print(f"    coast: {coast_mask.sum():,} pts  |  decor: {
              decor_mask.sum():,} pts")

        has_polygon = coast_mask.sum() > 2
        cx_closed = cy_closed = None

        if has_polygon:
            cx_closed, cy_closed = np.append(cx, cx[0]), np.append(cy, cy[0])

            if cfg["clip_decor"]:
                # solid landmass + decoration clipped to its interior,
                # so vegetation never floats outside the boundary
                if cfg["land_color"]:
                    ax.fill(cx_closed, cy_closed,
                            color=cfg["land_color"], zorder=1)
                if dx.size > 0:
                    interior = MplPath(np.column_stack([cx,
                                                        cy])).contains_points(
                        np.column_stack([dx, dy]))
                    dx, dy = dx[interior], dy[interior]
            else:
                # no hard boundary: blend the contour itself into the
                # soft point cloud instead of drawing a solid shape
                dx, dy = np.append(dx, cx), np.append(dy, cy)

        # decoration: density heatmap in the chosen palette
        if dx.size > 0:
            bins = max(width, height) // 4
            h, xedges, yedges = np.histogram2d(dx, dy, bins=bins)
            h = np.log1p(h)
            cmap = make_cmap(palette)
            extent = [xedges[0], xedges[-1], yedges[0], yedges[-1]]
            ax.imshow(h.T, origin="lower", extent=extent,
                      cmap=cmap, alpha=alpha,
                      interpolation="bilinear", zorder=2)
            ax.scatter(dx, dy, s=point_size * 0.5, c="white",
                       alpha=0.06, linewidths=0, zorder=2)

        # coastline: bright continuous polygon outline on top
        if cfg["outline"] and has_polygon:
            ax.plot(cx_closed, cy_closed,
                    color="white", linewidth=0.6, alpha=0.9, zorder=10)

    else:
        # ── legacy mode: flat point cloud (ifs / equation fractals) ───────
        bins = max(width, height) // 4
        h, xedges, yedges = np.histogram2d(xs, ys, bins=bins)
        h = np.log1p(h)
        cmap = make_cmap(palette)
        extent = [xedges[0], xedges[-1], yedges[0], yedges[-1]]
        ax.imshow(h.T, origin="lower", extent=extent,
                  cmap=cmap, alpha=alpha, interpolation="bilinear")
        ax.scatter(xs, ys, s=point_size, c="white",
                   alpha=0.08, linewidths=0)

    fig.savefig(out_path, dpi=dpi, facecolor=bg, format="png")
    plt.close(fig)
    print(f"  → salvo em {out_path}")


def main():
    parser = argparse.ArgumentParser(description="Renderiza fractal CSV → PNG")
    parser.add_argument("csv",    help="arquivo CSV gerado pelo backend Guile")
    parser.add_argument("output", help="arquivo PNG de saída")
    parser.add_argument("--style",  default="island",
                        choices=list(STYLES.keys()),
                        help="""tipo de objeto (controla
                        preenchimento/recorte/contorno)""")
    parser.add_argument("--color",  default=None,
                        choices=list(PALETTES.keys()),
                        help="paleta de cores (padrão: a do --style)")
    parser.add_argument("--bg",     default=None,
                        help="cor de fundo hex (padrão: a do --style)")
    parser.add_argument("--dpi",    type=int, default=300)
    parser.add_argument("--width",  type=int, default=None)
    parser.add_argument("--height", type=int, default=None)
    parser.add_argument("--size",   type=int, default=2048,
                        help="""fallback quando
                        --width/--height não são informados""")
    parser.add_argument("--alpha",  type=float, default=0.6)
    parser.add_argument("--pt",     type=float, default=0.3,
                        help="tamanho do ponto no scatter")
    args = parser.parse_args()

    if not Path(args.csv).exists():
        print(f"Erro: {args.csv} não encontrado.", file=sys.stderr)
        sys.exit(1)
    width = args.width if args.width is not None else args.size
    height = args.height if args.height is not None else args.size

    render(args.csv, args.output,
           palette=args.color, bg=args.bg, style=args.style,
           dpi=args.dpi, width=width, height=height,
           alpha=args.alpha, point_size=args.pt)


if __name__ == "__main__":
    main()
