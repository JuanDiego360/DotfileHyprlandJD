#!/usr/bin/env bash

# Clear screen
clear

echo "========================================================"
echo "    ACTUALIZACIÓN Y RESPALDO DE DOTFILES EN GITHUB"
echo "========================================================"
echo

DOTFILES_DIR="$HOME/dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "❌ Error: El directorio $DOTFILES_DIR no existe."
    exit 1
fi

cd "$DOTFILES_DIR" || exit 1

# 1. Verificar si es un repositorio git, si no, inicializar
if [ ! -d ".git" ]; then
    echo "--> Inicializando repositorio Git local..."
    git init -b main
    git remote add origin git@github.com:JuanDiego360/DotfileHyprlandJD.git
fi

# Asegurar que el remote origin esté bien configurado
if ! git remote | grep -q "origin"; then
    git remote add origin git@github.com:JuanDiego360/DotfileHyprlandJD.git
else
    git remote set-url origin git@github.com:JuanDiego360/DotfileHyprlandJD.git
fi

# Asegurar que el remote upstream esté bien configurado
if ! git remote | grep -q "upstream"; then
    git remote add upstream https://github.com/ilyamiro/nixos-configuration.git
else
    git remote set-url upstream https://github.com/ilyamiro/nixos-configuration.git
fi

# 2. Añadir y hacer commit de los cambios locales
echo "--> Verificando cambios locales en tus dotfiles..."
if [ -n "$(git status --porcelain)" ]; then
    echo "   Encontrados cambios locales. Creando copia de seguridad..."
    git add -A
    git commit -m "Respaldo automático: $(date +'%Y-%m-%d %H:%M:%S')"
    
    echo "--> Subiendo tus cambios locales a GitHub..."
    if git push origin main; then
        echo "   ✅ Cambios locales subidos con éxito."
    else
        echo "   ⚠️ Advertencia: No se pudo subir a GitHub (¿problemas de red o llaves SSH?)."
        echo "   Continuando con la actualización local..."
    fi
else
    echo "   No hay cambios locales nuevos que respaldar."
fi

# 3. Bajar los cambios del repositorio remoto (ilyamiro/nixos-configuration)
echo
echo "--> Descargando e integrando cambios remotos de GitHub (nixos-configuration)..."
# Hacemos pull para combinar los cambios remotos de upstream/master.
# Usamos '--no-rebase' para permitir fusiones estándar.
# Añadimos '--allow-unrelated-histories' por diferencias de historial.
if git pull upstream master --no-rebase --allow-unrelated-histories; then
    echo "   ✅ Actualización remota completada con éxito."
else
    echo "❌ Error al hacer pull. Si hay conflictos de fusión, resuélvelos en esta terminal."
fi

echo
echo "========================================================"
echo "   Proceso finalizado. Presiona cualquier tecla para salir..."
echo "========================================================"
read -n 1 -s -r
