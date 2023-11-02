# Une configuration traject pour les notices bibliographiques
# du don Gingras
# Voir https://github.com/traject/traject

# To have access to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have access to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats


# In this case for simplicity we provide all our settings, including
# solr connection details, in this one file. But you could choose
# to separate them into antoher config file; divide things between
# files however you like, you can call traject with as many
# config files as you like, `traject -c one.rb -c two.rb -c etc.rb`
settings do
  # Il faut passer ces paramètres en ligne de commande
  #provide "solr.url", "http://localhost:8983/solr/blacklight-core"
  #provide "solr_writer.commit_on_close", "true"
  #provide "local.images_dir", "/Users/sevignma/dev/gingras/data/Gingras_numerisations/"
  #provide "local.images_url", "http://localhost:8183/iiif/3/"
  #provide "local.images_url_suffix", "/full/!1024,1024/0/default.jpg"
  #provide "local.thumbnails_url", "http://localhost:8183/iiif/3/"
  #provide "local.thumbnails_url_suffix", "/full/200,/0/default.jpg"
end

# Les numéros de contrôle
# Ignorées: 003, 005, 006, 
# L'identifiant, que l'on prend tel quel dans le 001 (c'est le OCN)
to_field "id", extract_marc("001", :first => true, :trim_punctuation => true)

# Les documents numérisés

# D'abord la présence ou non, pour une facette
to_field "with_images_ssim" do |rec, acc|
  ocn_digits = rec.fields("001").first.value.scan(/\d+/).first
  files = Dir.glob(settings["local.images_dir"] + ocn_digits + "*")
  if files.length > 0
    acc << "Oui"
  else
    acc << "Non"
  end
end

# Ensuite les URLs, pour l'affichage
to_field "images_url_ssim" do |rec, acc|
  ocn_digits = rec.fields("001").first.value.scan(/\d+/).first
  files = Dir.glob(settings["local.images_dir"] + ocn_digits + "*")
  files.each do |fi|
    acc << settings["local.images_url"] + File.basename(File.new(fi)) + settings["local.images_url_suffix"]
#    acc << "http://localhost:8183/iiif/3/" + File.basename(File.new(fi)) + "/full/200,/0/default.jpg"
#    acc << "https://bib.umontreal.ca/fileadmin/_processed_/d/6/csm_1710e0e22c088e5d590cb37b897e38b313eed1cc_d19060d40c.jpg"
  end
end
# Ensuite les URLs, pour les thumbnails
to_field "thumbnails_url_ssim" do |rec, acc|
  ocn_digits = rec.fields("001").first.value.scan(/\d+/).first
  files = Dir.glob(settings["local.images_dir"] + ocn_digits + "*")
  files.each do |fi|
    acc << settings["local.thumbnails_url"] + File.basename(File.new(fi)) + settings["local.thumbnails_url_suffix"]
#    acc << "http://localhost:8183/iiif/3/" + File.basename(File.new(fi)) + "/full/200,/0/default.jpg"
#    acc << "https://bib.umontreal.ca/fileadmin/_processed_/d/6/csm_1710e0e22c088e5d590cb37b897e38b313eed1cc_d19060d40c.jpg"
  end
end

# Le format, assez complexe, on va commencer par la position 0 du 007
# voir https://www.marc21.ca/M21/BIB/B011-007.html
# TODO: autres valeurs de 007?
to_field "format", extract_marc("007[0]"), translation_map("gingras-poc-format")

# Le 008 contient plusieurs informations codées
# Voir https://www.marc21.ca/M21/BIB/B027-008.html
to_field "language_ssim", extract_marc("008[35-37]:041a:041b:041d:041e:041f:041g:041h:041i:041j:041k:041m:041n:041p:041q:041r:041t"), translation_map("gingras-poc-langues")

# Numéros de contrôles (01X - 09X)
# Ignorées: 010, 015, 016, 017, 019, 024, 025, 027, 029, 030, 033, 035,
# 037, 040, 042, 043, 044, 045, 046, 049, 052, 055, 060, 066, 070, 072,
# 080, 082, 083, 084, 086, 088, 090, 092, 096

# ISBN et autres numéros ou codes
to_field "isbn_tsim", extract_marc("020a")
to_field "publisher_number_ssim", extract_marc("028abq")
to_field "music_form_ssim", extract_marc("047a"), translation_map("gingras-poc-formes-musicales")
to_field "interpret_ssim", extract_marc("048a"), translation_map("gingras-poc-instruments")
to_field "soliste_ssim", extract_marc("048b"), translation_map("gingras-poc-instruments")

# Cotes (on reprend la logique du marc_indexer de Blakclight)
to_field "lc_callnum_ssm", extract_marc("050ab", :first => true)

first_letter = lambda {|rec, acc| acc.map!{|x| x[0]} }
to_field "lc_1letter_ssim", extract_marc("050ab", :first => true)

alpha_pat = /\A([A-Z]{1,3})\d.*\Z/
alpha_only = lambda do |rec, acc|
  acc.map! do |x|
    (m = alpha_pat.match(x)) ? m[1] : nil
  end
  acc.compact! # eliminate nils
end
to_field "lc_alpha_ssim", extract_marc("050a"), alpha_only, first_only
to_field "lc_b4cutter_ssim", extract_marc("050a"), first_only

# Le format utilise notamment le 007
# voir https://github.com/projectblacklight/blacklight-marc/blob/2b9da5dfb0f58fc13aed5557a87b27813ad302b4/lib/blacklight/marc/indexer/formats.rb#L155
# to_field "format", get_format

# Le MARC en XML (pour la vue catalogueur)
to_field "marc_ss", serialized_marc(:format => "xml")

# Le champ plein texte
# Si on ne fait pas la boucle avec le join on a une occurence
# du champ pour chaque champ MARC
to_field "all_text_timv", extract_all_marc_values do |r, acc|
  acc.replace [acc.join(' ')]
end



# Les titres et collections

# Le titre comme tel
to_field 'title_tsim', extract_marc('245', :trim_punctuation => true)

# Titre uniforme
to_field 'title_uniform_tsim', extract_marc('240')

# Les titres alternatifs
to_field "title_addl_tsim", extract_marc("242:243:246")

# Les éditions, zones bibliographiques, ... (26x-28X)
# Ignorées: 257, 263
to_field "edition_ssm", extract_marc("250ab")
to_field "musicalprint_ssm", extract_marc("254a")
to_field "published_ssm", extract_marc("260abcefgk:264abc", :trim_punctuation => true)
to_field "pub_date_si", marc_publication_date
to_field "pub_date_ssim", marc_publication_date


# Le titre pour le tri
# TODO: retire par exemple le "the" en début de titre,
# et n'inclut pas toutes les sous-zones. À voir si on en a vraiment
# besoin.
to_field "title_si", marc_sortable_title

# La collection
to_field "collection_tsim", extract_marc("490")


# Les zones de description matérielle (3XX)
# Ignorés: 351, 365, 370, 380

# Description matérielle
to_field "material_type_ssm", extract_marc("300")

# Durée d'exécution (encodée, genre 001355 pour 13 min. 55.)
# TODO: semble aussi présente en 500, utile ici?
to_field "duration_ssm", extract_marc("306a")

# Type de contenu
# Voir https://www.marc21.ca/M21/COD/RDA-CON-MARC.html
to_field "content_type_ssim", extract_marc("336b"), translation_map("gingras-poc-types-contenus")

# Type de média
# https://www.marc21.ca/M21/COD/RDA-MED-MARC.html
to_field "media_type_ssim", extract_marc("337b"), translation_map("gingras-poc-types-medias")

# Type de support
# Voir https://www.marc21.ca/M21/COD/RDA-SM-MARC.html
to_field "carrier_type_ssim", extract_marc("338b"), translation_map("gingras-poc-types-supports")

# Support matériel
to_field "physical_medium_ssm", extract_marc("340abdfg", :trim_punctuation => true)

# Caractéristiques sonores
to_field "sound_characteristics_ssm", extract_marc("344abcdefghif")

# Caractéristiques vidéos
to_field "video_characteristics_ssm", extract_marc("346ab")

# Caractéristiques de fichier numérique
to_field "file_characteristics_ssm", extract_marc("347abcdef")

# Caractéristiques de la musique notée
to_field "notated_music_characteristics_ssm", extract_marc("348abcd")

# Distribution d'exécution d'une oeuvre
to_field "medium_performance_ssim", extract_marc("382a")
to_field "medium_performance_ssim", extract_marc("382b")
to_field "medium_performance_ssim", extract_marc("382d")

# Numéro d'identification de l'oeuvre musicale
to_field "numeric_designation_ssm", extract_marc("383abcde")

# Tonalité
to_field "key_ssm", extract_marc("384a")

# Caractéristiques du créateur
to_field "creator_characteristics_ssim", extract_marc("386abimn")

to_field "title_series_ssim", extract_marc("440a:490a:800abcdt:400abcd:810abcdt:410abcd:811acdeft:411acdef:830adfgklmnoprst:760ast:762ast"), trim_punctuation
to_field "series_facet_ssim", marc_series_facet

# Les vedettes principales (auteurs, ..., zones 1XX)

to_field "author_tsim", extract_marc("100abcdgqu:110abcdgnu:111acdegjnqu:130afgklmnoprs", :trim_punctuation => true)
to_field "author_ssm", extract_marc("100abcdgqu:110abcdgnu:111acdegjnqu:130afgklmnoprs", :trim_punctuation => true)
to_field "author_si", marc_sortable_author

# On va aller chercher quelques rôles particuliers
# TODO: il y en a en théorie beaucoup plus, voir ceux qui sont
# utilisés et intéressants
# Voir https://www.marc21.ca/M21/COD/REL-C.html

# Les compositeurs auront $e=composer et/ou $4=cmp
to_field "author_composer_ssim" do |rec, acc|
  rec.fields("100").each do |f|
    d_e = f["e"]
    d_4 = f["4"]
    if d_e == "composer" || d_4 == "cmp"
      acc << [f["a"], f["d"]].join(" ")
    end
  end
  rec.fields("110").each do |f|
    d_e = f["e"]
    d_4 = f["4"]
    if d_e == "composer" || d_4 == "cmp"
      acc << [f["a"], f["b"]].join(" ")
    end
  end
  rec.fields("700").each do |f|
    d_e = f["e"]
    d_4 = f["4"]
    if d_e == "composer" || d_4 == "cmp"
      acc << [f["a"], f["d"]].join(" ")
    end
  end
  rec.fields("710").each do |f|
    d_e = f["e"]
    d_4 = f["4"]
    if d_e == "composer" || d_4 == "cmp"
      acc << [f["a"], f["d"]].join(" ")
    end
  end
end

# Les interprètes auront $4=prf
to_field "author_interpret_ssim" do |rec, acc|
  rec.fields("100").each do |f|
    d_4 = f["4"]
    if d_4 == "prf"
      acc << [f["a"], f["d"]].join(" ")
    end
  end
  rec.fields("110").each do |f|
    d_4 = f["4"]
    if d_4 == "prf"
      acc << [f["a"], f["b"]].join(" ")
    end
  end
  rec.fields("700").each do |f|
    d_4 = f["4"]
    if d_4 == "prf"
      acc << [f["a"], f["d"]].join(" ")
    end
  end
  rec.fields("710").each do |f|
    d_4 = f["4"]
    if d_4 == "prf"
      acc << [f["a"], f["d"]].join(" ")
    end
  end
end

# Les vedettes secondaires (70X - 75X)

# Auteurs génériques comme tels
to_field "author_addl_tsim", extract_marc("700abcegqu:710abcdegnu:711acdegjnqu:720a:730agiklmnopr:740anp:752adf", :trim_punctuation => true)


# Les sujets (6XX)

# D'abord un sujet en général
to_field "subject_tsim", extract_marc(
  %W(
      600abcdefghijklmnopqrstuvwxyz
      610abvxyz
      611acdnvx
      630avx
      647acd
      648a
      650acdgvxyz
      651avxyz
      653a
      655avxyz
      695a
  ).join(":")
)
to_field "subject_ssim", extract_marc(
  %W(
      600abcdefghijklmnopqrstuvwxyz
      610abvxyz
      611acdnvx
      630avx
      647acd
      648a
      650acdgvxyz
      651avxyz
      653a
      655avxyz
      695a
  ).join(":"), :trim_punctuation => true
)

# Ensuite les sujets spécifiques

to_field "subject_person_ssim", extract_marc("600abcdefghijklmnopqrstuvwxyz", :trim_punctuation => true)
to_field "subject_collect_ssim", extract_marc("610abvxyz", :trim_punctuation => true)
to_field "subject_meeting_ssim", extract_marc("611acdnvx", :trim_punctuation => true)
to_field "subject_title_ssim", extract_marc("630avx", :trim_punctuation => true)
to_field "subject_event_ssim", extract_marc("647acd", :trim_punctuation => true)
to_field "subject_chrono_ssim", extract_marc("648a", :trim_punctuation => true)
to_field "subject_name_ssim", extract_marc("650acdgvxyz", :trim_punctuation => true)
to_field "subject_geo_ssim", extract_marc("651avxyz", :trim_punctuation => true)
to_field "subject_genre_ssim", extract_marc("655avxyz", :trim_punctuation => true)
to_field "subject_local_ssim", extract_marc("695a", :trim_punctuation => true)

# Les notes

to_field "notes_ssim", extract_marc(
  %W(
    500a
    501a
    502a
    504a
    505agrt
    506ac
    508a
    510ac
    511a
    518adop
    520ac
    521a
    525a
    530a
    533abcdn
    534acop
    536a
    538a
    544a
    541ac
    542g
    545a
    546ab
    550a
    561a
    562a
    580a
    583ackz
    586a
    588a
    591abcd
    592abf
    593a
    597acinqtw
    599abcdginrt
  ).join(":")
)

# Les liaisons

to_field "pieces_ssm", extract_marc("774:adgtw")

# La mention du fonds Claude Gingras
to_field "fonds_ssm", extract_marc("799a")

# Les vedettes secondaires de collection (80X-83X)
to_field "collection_ssm", extract_marc("830afhnpvxw")

# Les URL (856)
to_field "link_ssm", extract_marc("856u3")
to_field "url_ssm", extract_marc("856u")

