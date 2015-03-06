# orfeo-importer

This program imports texts with linguistic annotations and generates
outputs based on selected features of the annotated text. It reads
files in CoNLL 2007, Macaon and TEI formats, generally merging
information from several files (e.g. dependency trees from CoNLL or
Macaon, metadata from TEI, time alignment information from TEI or
Macaon). It then produces output in three formats: relAnnis 3.2 for
importing into [ANNIS](http://annis-tools.org/); HTML as stand-alone
pages for each sample; and index values for Apache Solr for text
search.

This program was created within the project [ANR
ORFEO](http://www.projet-orfeo.fr/). (The project is unrelated to a
number of similarly named projects such as the [Orfeo
ToolBox](https://www.orfeo-toolbox.org/) library.)


# Dependencies

The directory [data/files](data/files) includes Javascript components
by other authors:

 - [jQuery](http://jquery.com/) is used for a lot of things
 - [ProgressBar.js](http://kimmobrunfeldt.github.io/progressbar.js/) is used for the load progress indicator
 - [Arborator](http://arborator.ilpga.fr/) is used to draw dependency trees; it in turn uses [Raphaël](http://raphaeljs.com/)
 - [HTML5 Audio Read-Along](https://github.com/westonruter/html5-audio-read-along) is used for the aligned audio player


# Configuration files

There is a single configuration file for metadata, and a file can be
created for each corpus to define extra information to be displayed.

## Metadata definition

The file [metadata.tsv](data/metadata.tsv) defines the metadata fields
to be extracted, indexed and displayed. These columns are used for
each field:

 - The *short name* of a field is ideally a single word with no
   non-ASCII characters.
 - The *long name* is a descriptive string displayed to users.
 - The *field type* can be **g** for a general field (i.e. one on the
   sample level); **gm** for a general field with multiple values; or
   **s** for a specific (or speaker level) field
 - The *indexing and search* column defines treatment of the field
   when using a text index (basically, Solr) and a corresponding
   search interface: **f** for a facet (indexed, then made available
   for selection in the search interface); **s** for a search target
   (indexed, then accessible for single-field text search); **i** for
   an indexed field (which is included in the text index but not
   separately visible in the search interface); and **o** to omit a
   field (which is not indexed)
 - The *XPath* column defines the XPath expression to be used to
   extract the value of the field from a TEI document. If the field is
   not multi-valued, only the first match is used; otherwise all
   matching values are extracted.

## Corpus information files

Contained in the directory [data/corpora](data/corpora), corpus
information files must be named corresponding to the directories where
input files appear, e.g. *example.txt* for information about a corpus
read in from a directory named *example*. The content is read line by
line, each line having different semantics. Currently there are four
lines:

 1. Name of the corpus, formatted for readability (e.g. "C-Oral-Rom"
    rather than "coralrom").
 1. URL to the homepage of the corpus or project
 1. Filename of a logo to be displayed for the corpus
 1. An abstract describing the corpus

Unused lines may be left empty, but must not be omitted to maintain
line numbering.

It is not obligatory to define corpus information for every corpus,
but in the absence of an information file, the corpus information
panel in the sample page will be virtually empty.


# License

GPL v3; see file LICENSE for full text of the license.
