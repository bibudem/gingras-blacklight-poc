#!/bin/sh

# Ce petit script copie les fichiers modifiés de Blacklight
# dans le dossier où l'application tourne

# Définir ici le chemin vers le dossier d'installation
INSTALL_DIR="../search_app"

SRCDIR="blacklight"


echo "Copie des fichiers de $SRCDIR vers $INSTALL_DIR"

# On le fait en sudo car le dossier semble protégé
cp -R $SRCDIR/* $INSTALL_DIR
