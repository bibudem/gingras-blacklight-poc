#!/bin/sh

# Ce petit script copie les fichiers "translation_maps" vers le dossier
# "lib" du gem "traject"

# Définir ici le chemin vers le dossier lib du gem traject
LIBDIR="/opt/homebrew/lib/ruby/gems/3.2.0/gems/traject-3.8.1/lib"

SRCDIR="translation_maps"


echo "Copie des fichiers de $SRCDIR vers $LIBDIR"

# On le fait en sudo car le dossier semble protégé
sudo cp -R $SRCDIR/* $LIBDIR/$SRCDIR
