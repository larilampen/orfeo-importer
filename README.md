# orfeo-importer

This program imports texts with linguistic annotations and generates
outputs based on selected features of the annotated text. It reads
files in CoNLL 2007, Macaon and TEI formats, generally merging
information from several files (e.g. dependency trees from CoNLL or
Macaon, metadata from TEI, time alignment information from TEI or
Macaon). It then produces output in three formats: relAnnis 3.2 for
importing into [ANNIS](http://annis-tools.org/); HTML as stand-alone
pages for each sample; and index values for Apache Solr for text
search, best suited for use with the associated Solr-based
[web search interface](https://github.com/larilampen/orfeo-search).

This program was created within the project [ANR
ORFEO](http://www.projet-orfeo.fr/). (The project is unrelated to a
number of similarly named projects such as the [Orfeo
ToolBox](https://www.orfeo-toolbox.org/) library.)


# Dependencies

Metadata is handled by a orfeo-metadata, a Ruby gem in a
[separate repository](https://github.com/orfeo-treebank/orfeo-metadata),
which should be installed first before running this importer. The gem
contains a default metadata model, but new ones can be defined using a
simple column-based text file. See the metadata repository for
details. **Note:** The metadata definitions used by the importer must
match those used by the text search interface for the latter to
function at all.

The directory [data/files](data/files) includes Javascript components
by other authors:

 - [jQuery](http://jquery.com/) is used for a lot of things
 - [ProgressBar.js](http://kimmobrunfeldt.github.io/progressbar.js/) is used for the load progress indicator
 - [Arborator](http://arborator.ilpga.fr/) is used to draw dependency trees; it in turn uses [Raphaël](http://raphaeljs.com/)
 - [HTML5 Audio Read-Along](https://github.com/westonruter/html5-audio-read-along) is used for the aligned audio player


# Configuration files

A file can be created for each corpus to define extra information to
be displayed.

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
