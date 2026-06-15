# ─── FractalDSL — Guile + Python renderer ────────────────────────────────
FROM archlinux:latest

LABEL description="FractalDSL: backend Guile/Scheme + renderer Python"

# ─── dependências do sistema ──────────────────────────────────────────────
RUN pacman -Syu --noconfirm \
    guile \
    python \
    python-pip \
    && rm -rf /var/cache/pacman/pkg/*

# ─── dependências Python ──────────────────────────────────────────────────
RUN pip install --break-system-packages \
    numpy \
    matplotlib

# ─── copia o projeto ─────────────────────────────────────────────────────
WORKDIR /fractal
COPY guile/  ./guile/
COPY python/ ./python/

# ─── diretório de saída ───────────────────────────────────────────────────
RUN mkdir -p /fractal/output

# ─── script de entrada padrão ────────────────────────────────────────────
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
