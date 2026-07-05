#!/bin/bash
set -e

DOTFILES_DIR="$HOME/dotfiles"
END4_PROFILE="$DOTFILES_DIR/setup-end4/.config"
ILYAMIRO_PROFILE="$DOTFILES_DIR/setup-ilyamiro/.config"

echo "=== Creador de Perfiles GNU Stow ==="

# 1. Crear carpeta del perfil original
mkdir -p "$END4_PROFILE"

# 2. Migrar configuraciones activas (si no son enlaces simbólicos)
configs=("hypr" "cava" "matugen")

for c in "${configs[@]}"; do
    SRC="$HOME/.config/$c"
    DEST="$END4_PROFILE/$c"
    
    if [ -e "$SRC" ]; then
        if [ -L "$SRC" ]; then
            echo "[Omitido] $c ya es un enlace simbólico."
        elif [ -d "$SRC" ]; then
            echo "[Migrando] Copiando y respaldando $c..."
            rm -rf "$DEST"
            cp -r "$SRC" "$DEST"
            mv "$SRC" "${SRC}.bak-stow"
            echo "-> Respaldado $c en ${c}.bak-stow"
        fi
    else
        echo "[Omitido] $c no existe en ~/.config"
    fi
done

echo ""
echo "=== Perfiles Stow listos ==="
echo "Para activar tus dotfiles originales (end-4):"
echo "  cd ~/dotfiles"
echo "  stow -v setup-end4"
echo ""
echo "Para cambiar al entorno estético (ilyamiro):"
echo "  cd ~/dotfiles"
echo "  stow -D setup-end4"
echo "  stow -v setup-ilyamiro"
echo ""
echo "Para regresar a tus dotfiles originales (end-4):"
echo "  cd ~/dotfiles"
echo "  stow -D setup-ilyamiro"
echo "  stow -v setup-end4"
