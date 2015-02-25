#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# This program reads linguistic annotation data from a number of
# source files and outputs to a number of target formats.
#
# Lari Lampen (CNRS), 2014-2015.

$VERBOSE = true

require 'find'

# Add directory lib/ to load path.
$: << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

require 'orfeo_importer'


# -- Read arguments --
if ARGV.length >= 1
  input=ARGV[0]
  outputdir = (ARGV.length >= 2) ? ARGV[1] : 'output'
else
  puts "Usage: #{$0} input [outputdir]"
  puts
  puts "If input is a directory, all files in it and any subdirectories will be processed. "
  puts "If output directory is omitted, 'output' under current directory is used."
  abort
end


# -- Read configuration stuff --
md = OrfeoImporter::Metadata::MetadataModel.new
md.load "data/metadata.tsv"

# Corpus name is the name of the (top) directory the files are in.
if File.directory? input
  corpname = File.basename input
else
  corpname = File.basename(File.expand_path('..', input))
end

corpus = OrfeoImporter::Corpus.new(corpname, md, 'data/corpora')


# -- Input --
Find.find(input) do |path|
  unless FileTest.directory?(path)
    files = []
    base = path.chomp(File.extname(path))

    if File.extname(path) == ".macaon" || File.extname(path) == ".conll"
      files << path
      ['.mp3', '.wav', '.AvecHeader.xml'].each do |ext|
        f = base + ext
        if File.exist? f
          puts "ADD: #{f}"
          files << f
        end
      end
    end

    puts "--- Input files found: ---"
    files.each_with_index{ |x, i| puts " #{i+1}. #{x}" }

    corpus.read_files File.basename(base), files unless files.empty?
  end
end


# -- Update component/rank numbering (needed for relAnnis output) --
corpus.renumber_elements


# -- Output --
corpus.output_annis "#{outputdir}/annis"
corpus.copy_files "#{outputdir}/web"
corpus.output_html "#{outputdir}/web"
corpus.index_solr 'http://localhost:8983/solr'
