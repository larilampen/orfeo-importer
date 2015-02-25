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


# License

GPL v3; see file LICENSE for full text of the license.
