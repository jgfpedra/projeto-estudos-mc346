#!/usr/bin/env python3
"""
render_fractal.py — lê o CSV gerado pelo backend Guile e salva PNG.

Uso:
    python render_fractal.py sierpinski.csv sierpinski.png --color green
    python render_fractal.py barnsley.csv   barnsley.png   --color limegreen
    python render_fractal.py ilha.csv       ilha.png       --color teal --bg "#0a1a2f"
"""

import argparse
import csv
import sys
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap


# ─── paletas temáticas ────────────────────────────────────────────────────

PALETTES = {
    "green":     ["#0a1a0a", "#1a4a1a", "#2ecc71", "#a8f5a2"],
    "ocean":     ["#020d18", "#0a3d5c", "#1a7abf", "#7fd4f4"],
    "fire":      ["#1a0000", "#7a1a00", "#e05c00", "#ffe066"],
    "teal":      ["#020f0f", "#064a4a", "#0abfbf", "#afffff"],
    "limegreen": ["#0a1a04", "#2a5a0a", "#7ddb2d", "#d4ffaa"],
    "mono":      ["#000000", "#444444", "#aaaaaa", "#ffffff"],
}


def load_points(csv_path: str):
    xs, ys = [], []
    with open(csv_path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            xs.append(float(row["x"]))
            ys.append(float(row["y"]))
    return np.array(xs), np.array(ys)


def make_cmap(palette_name: str):
    colors = PALETTES.get(palette_name, PALETTES["mono"])
    return LinearSegmentedColormap.from_list("fractal", colors, N=512)


def render(csv_path: str, out_path: str, palette: str = "mono",
           bg: str = "#000000", dpi: int = 300, size: int = 2048,
           alpha: float = 0.6, point_size: float = 0.3):

    xs, ys = load_points(csv_path)
    print(f"  {len(xs):,} pontos carregados de {csv_path}")

    # histograma 2D para density coloring
    bins = size // 4
    h, xedges, yedges = np.histogram2d(xs, ys, bins=bins)
    h = np.log1p(h)          # escala logarítmica para contraste

    fig, ax = plt.subplots(figsize=(size / dpi, size / dpi), dpi=dpi)
    fig.patch.set_facecolor(bg)
    ax.set_facecolor(bg)
    ax.set_aspect("equal")
    ax.axis("off")

    cmap = make_cmap(palette)

    # renderiza como imagem de densidade
    extent = [xedges[0], xedges[-1], yedges[0], yedges[-1]]
    ax.imshow(h.T, origin="lower", extent=extent,
              cmap=cmap, alpha=alpha, interpolation="bilinear")

    # sobrepõe scatter leve para detalhes finos
    ax.scatter(xs, ys, s=point_size, c="white", alpha=0.08, linewidths=0)

    plt.tight_layout(pad=0)
    fig.savefig(out_path, dpi=dpi, bbox_inches="tight",
                facecolor=bg, format="png")
    plt.close(fig)
    print(f"  → salvo em {out_path}")


def main():
    parser = argparse.ArgumentParser(description="Renderiza fractal CSV → PNG")
    parser.add_argument("csv",    help="arquivo CSV gerado pelo backend Guile")
    parser.add_argument("output", help="arquivo PNG de saída")
    parser.add_argument("--color",  default="mono",
                        choices=list(PALETTES.keys()),
                        help="paleta de cores")
    parser.add_argument("--bg",     default="#000000", help="cor de fundo hex")
    parser.add_argument("--dpi",    type=int, default=300)
    parser.add_argument("--size",   type=int, default=2048,
                        help="largura/altura em pixels")
    parser.add_argument("--alpha",  type=float, default=0.6)
    parser.add_argument("--pt",     type=float, default=0.3,
                        help="tamanho do ponto no scatter")
    args = parser.parse_args()

    if not Path(args.csv).exists():
        print(f"Erro: {args.csv} não encontrado.", file=sys.stderr)
        sys.exit(1)

    render(args.csv, args.output,
           palette=args.color, bg=args.bg,
           dpi=args.dpi, size=args.size,
           alpha=args.alpha, point_size=args.pt)


if __name__ == "__main__":
    main()
