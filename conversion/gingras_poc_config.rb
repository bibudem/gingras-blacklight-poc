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
#  provide "solr.url", "http://localhost:8983/solr/blacklight-core"
#  provide "solr_writer.commit_on_close", "true"
end

# Les numéros de contrôle
# Ignorées: 003, 005, 006, 
# L'identifiant, que l'on prend tel quel dans le 001 (c'est le OCN)
to_field "id", extract_marc("001", :first => true, :trim_punctuation => true)

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


# An exact literal string, always this string:
#to_field "source",              literal("traject_test_last")

#to_field "marc_display",        serialized_marc(:format => "binary", :binary_escape => false, :allow_oversized => true)

#to_field "text",                extract_all_marc_values

#to_field "text_extra_boost_t",  extract_marc("505art")

#to_field "publisher_t",         extract_marc("260abef:261abef:262ab:264ab")

#to_field "language_facet",      marc_languages

#to_field "format",              marc_formats


#to_field "isbn_t",              extract_marc("020a:773z:776z:534z:556z")
#to_field "lccn",                extract_marc("010a")

#to_field "material_type_display", extract_marc("300a", :separator => nil, :trim_punctuation => true)

#to_field "title_t",             extract_marc("245ak")
#to_field "title1_t",            extract_marc("245abk")
#to_field "title2_t",            extract_marc("245nps:130:240abcdefgklmnopqrs:210ab:222ab:242abcehnp:243abcdefgklmnopqrs:246abcdefgnp:247abcdefgnp")
#to_field "title3_t",            extract_marc("700gklmnoprst:710fgklmnopqrst:711fgklnpst:730abdefgklmnopqrst:740anp:505t:780abcrst:785abcrst:773abrst")

# Note we can mention the same field twice, these
# ones will be added on to what's already there. Some custom
# logic for extracting 505$t, but only from 505 field that
# also has $r -- we consider that more likely to be a titleish string
#to_field "title3_t" do |record, accumulator|
#  record.each_by_tag('505') do |field|
#    if field['r']
#      accumulator.concat field.subfields.collect {|sf| sf.value if sf.code == 't'}.compact
#    end
#  end
#end

#to_field "title_display",       extract_marc("245abk", :trim_punctuation => true, :first => true)
#to_field "title_sort",          marc_sortable_title

#to_field "title_series_t",      extract_marc("440a:490a:800abcdt:400abcd:810abcdt:410abcd:811acdeft:411acdef:830adfgklmnoprst:760ast:762ast")
#to_field "series_facet",        marc_series_facet

#to_field "author_unstem",       extract_marc("100abcdgqu:110abcdgnu:111acdegjnqu")

#to_field "author2_unstem",      extract_marc("700abcdegqu:710abcdegnu:711acdegjnqu:720a:505r:245c:191abcdegqu")
#to_field "author_display",      extract_marc("100abcdq:110:111")
#to_field "author_sort",         marc_sortable_author


#to_field "author_facet",        extract_marc("100abcdq:110abcdgnu:111acdenqu:700abcdq:710abcdgnu:711acdenqu", :trim_punctuation => true)

#to_field "subject_t",           extract_marc("600:610:611:630:650:651avxyz:653aa:654abcvyz:655abcvxyz:690abcdxyz:691abxyz:692abxyz:693abxyz:656akvxyz:657avxyz:652axyz:658abcd")

#to_field "subject_topic_facet", extract_marc("600abcdtq:610abt:610x:611abt:611x:630aa:630x:648a:648x:650aa:650x:651a:651x:691a:691x:653aa:654ab:656aa:690a:690x",
#          :trim_punctuation => true, ) do |record, accumulator|
  #upcase first letter if needed, in MeSH sometimes inconsistently downcased
#  accumulator.collect! do |value|
#    value.gsub(/\A[a-z]/) do |m|
#      m.upcase
#    end
#  end
#end

#to_field "subject_geo_facet",   marc_geo_facet
#to_field "subject_era_facet",   marc_era_facet

# not doing this at present.
#to_field "subject_facet",     extract_marc("600:610:611:630:650:651:655:690")

#to_field "published_display", extract_marc("260a", :trim_punctuation => true)

#to_field "pub_date",          marc_publication_date

# An example of more complex ruby logic 'in line' in the config file--
# too much more complicated than this, and you'd probably want to extract
# it to an external routine to keep things tidy.
#
# Use traject's LCC to broad category routine, but then supply
# custom block to also use our local holdings 9xx info, and
# also classify sudoc-possessing records as 'Government Publication' discipline
#to_field "discipline_facet",  marc_lcc_to_broad_category(:default => nil) do |record, accumulator|
  # add in our local call numbers
#  Traject::MarcExtractor.cached("991:937").each_matching_line(record) do |field, spec, extractor|
      # we output call type 'processor' in subfield 'f' of our holdings
      # fields, that sort of maybe tells us if it's an LCC field.
      # When the data is right, which it often isn't.
#    call_type = field['f']
#    if call_type == "sudoc"
      # we choose to call it:
#      accumulator << "Government Publication"
#    elsif call_type.nil? ||
#          call_type == "lc" ||
#        Traject::Macros::Marc21Semantics::LCC_REGEX.match(field['a'])
      # run it through the map
#      s = field['a']
#      s = s.slice(0, 1) if s
#      accumulator << Traject::TranslationMap.new("lcc_top_level")[s]
#    end
#  end


  # If it's got an 086, we'll put it in "Government Publication", to be
  # consistent with when we do that from a local SuDoc call #.
#  if Traject::MarcExtractor.cached("086a").extract(record).length > 0
#    accumulator << "Government Publication"
#  end

  # uniq it in case we added the same thing twice with GovPub
#  accumulator.uniq!

#  if accumulator.empty?
#    accumulator << "Unknown"
#  end
#end

#to_field "instrumentation_facet",       marc_instrumentation_humanized
#to_field "instrumentation_code_unstem", marc_instrument_codes_normalized

#to_field "issn",                extract_marc("022a:022l:022y:773x:774x:776x", :separator => nil)
#to_field "issn_related",        extract_marc("490x:440x:800x:400x:410x:411x:810x:811x:830x:700x:710x:711x:730x:780x:785x:777x:543x:760x:762x:765x:767x:770x:772x:775x:786x:787x", :separator => nil)

#to_field "oclcnum_t",           oclcnum

#to_field "other_number_unstem", extract_marc("024a:028a")

