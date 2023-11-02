# gingras-blacklight-poc

Ce dépôt contient les fichiers nécessaires pour créer une preuve de concept pour la publication des notices du catalogue du don Claude-Gingras (Université de Montréal).

On y retrouve:

- Des notices bibliographiques en format MARC
- Un fichier Excel qui décrit quelques dizaines de boîtes d'archives
- Des images issues de la numérisation de certaines parties de documents

L'application permet de faire des recherches dans ce contenu et d'afficher les notices et, le cas échéant, les images associées.

## Blacklight

Il s'agit d'une application [Blacklight](http://projectblacklight.org). Une connaissance de cet outil ou de Ruby / Rails n'est pas essentielle, mais utile.

### Installation

**Solr**
: le moteur de recherche [Solr](https://solr.apache.org/guide/solr/latest/deployment-guide/installing-solr.html) est utilié par Blacklight. Vous devez l'installer et noter l'adresse pour accéder au serveur. Par défaut, c'est `http://localhost:8983/solr`. Cette preuve de concept a été créée avec la version 9.3 de Solr.

**Ruby, Rails, Java, nodejs, yarn**
: le [quickstart](https://github.com/projectblacklight/blacklight/wiki/Quickstart#dependencies) de Blacklight donne une bonne idée des outils et des versions de ce outils qui sont nécessaires pour une telle application. Pour l'instant, se contenter de suivre les instruction de la section "Dependencies".

À faire: poursuivre les informations d'installation

### Configuration

Les fichiers à modifier sont placés dans le dossier `blacklight` de ce dépôt, mais seulement les fichiers qui ont été modifiés. Ces *sources* ne sont donc pas automatiquement intégrées à l'application en service qui est installée dans un autre dossier.

Un script `copy-bl.sh` permet de copier les fichiers *sources* dans le dossier de l'application en service.


## Conversion des notices MARC

Blacklight suppose que vous avez des données indexées dans Solr. Pour cette preuve de concept, les données proviennent d'un lot de notices MARC. Pour les charger dans Solr, nous allons utiliser l'outil [Traject](https://github.com/traject/traject/tree/master).

Traject peut être installé comme tout *gem* Ruby:

```bash
gem install traject
```

C'est le dossier `conversion` qui contient les sources pour la conversion des notices de cette preuve de concept.

### Listes de valeurs

Traject peut utiliser des *translation maps* ou listes de valeurs pour traduire des codes en chaînes de caractères plus faciles à comprendre. Les fichiers qui contiennent ces listes de valeurs doivent être placés dans des sous-dossiers `translation_maps` d'un des dossiers d'installation de Traject.

Pour simplifier ce travail, un script `copy-maps.sh` est disponible et peut service d'exemple. Il copie le dossier `translation_maps` et tous son contenu dans un dossier de destination que vous pouvez définir dans la vairable `LIBDIR`.

### Lancement de la conversion

Pour lancer la conversion, Traject doit être exécuté et on doit lui fournir quelques paramètres. Voici, avec la version 3.8.1, les paramètres disponibles:

```bash

traject [options] -c configuration.rb [-c config2.rb] file.mrc
    -v, --version      print version information to stderr
    -d, --debug        Include debug log, -s log.level=debug
    -h, --help         print usage information to stderr
    -c, --conf         configuration file path (repeatable)
    -i, --indexer      Traject indexer class name or shortcut
    -s, --setting      settings: `-s key=value` (repeatable)
    -r, --reader       Set reader class, shortcut for -s reader_class_name=
    -o, --output_file  output file for Writer classes that write to files
    -w, --writer       Set writer class, shortcut for -s writer_class_name=
    -u, --solr         Set solr url, shortcut for -s solr.url=
    -t, --marc_type    xml, json or binary. shortcut for -s marc_source.type=
    -I, --load_path    append paths to ruby $LOAD_PATH
    -x, --command      alternate traject command: process (default); marcout; commit
    --stdin            read input from stdin
    --debug-mode       debug logging, single threaded, output human readable hashes


```

On doit donc nécessairement fournir un paramètre `c` pour fournir le fichier de configuration qui déterminer comment convertir, ainsi qu'un fichier à traiter. On peut également fournir quelques options.

Le fichier de configuration pour la conversion est `conversion/gingras_poc_config.rb`. Pour lancer la conversion avec une sortie dans un fichier Json (pour tester, on peut utiliser la commande suivante (elle est scindée en plusieurs lignes pour plus de clarté):

```bash

traject
    -s json_writer.pretty_print=true
    -s local.images_dir=/un/dossier/images
    -s local.images_url=http://localhost:8183/iiif/3/
    -s local.images_url_suffix=/full/max/0/default.jpg
    -s local.thumbnails_url=http://localhost:8183/iiif/3
    -s local.thumbnails_url_suffix=/full/1024,1024/0/default.jpg
    -w Traject::JsonWriter
    -o data/notices.json
    -c conversion/gingras_poc_config.rb
    data/gingras.mrc

```

Pour réellement indexer les notices dans un `core` de Solr, utiliser cette commande en prenant soin d'ajuster le paramètre `-u` vers votre instance de Solr, incluant le `core` souhaité:

```bash

traject
    -u http://localhost:8983/solr/blacklight-core
    -s solr_writer.commit_on_close=true
    -s local.images_dir=/un/dossier/images
    -s local.images_url=http://localhost:8183/iiif/3/
    -s local.images_url_suffix=/full/max/0/default.jpg
    -s local.thumbnails_url=http://localhost:8183/iiif/3
    -s local.thumbnails_url_suffix=/full/1024,1024/0/default.jpg
    -c conversion/gingras_poc_config.rb
    data/gingras.mrc

```