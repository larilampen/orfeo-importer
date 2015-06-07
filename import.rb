#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# This program reads linguistic annotation data from a number of
# source files and outputs to a number of target formats.
#
# Lari Lampen (CNRS), 2014-2015.

$VERBOSE = true

require 'find'
require 'optparse'
require 'yaml'

# Add directory lib/ to load path.
$: << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

require 'orfeo_importer'
require 'orfeo_metadata'


# -- Read arguments --
# 1. Set default values.
args = { outputdir: 'output' }

# 2. If defeaults are defined in YAML file, read them.
args.merge!(YAML.load_file('settings.yaml')) if File.exist? 'settings.yaml'

# 3. Read command line parameters.
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-i FILE", "--input=FILE", "Sets input file or directory") do |f|
    args[:input] = f
  end
  opts.on("-o DIR", "--output=DIR", "Sets output directory") do |f|
    args[:outputdir] = f
  end
  opts.on("-x URL", "--solr=URL", "Sets location of Solr index server") do |u|
    args[:solr] = u
  end
  opts.on("-a URL", "--annis=URL", "Sets base URL of ANNIS") do |u|
    args[:annis] = u
  end
  opts.on("-s URL", "--samples=URL", "Sets base URL where sample pages are hosted") do |u|
    args[:samples] = u
  end
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    puts
    puts 'Note:'
    puts "  - If input is a directory, all files in it and any subdirectories will be processed."
    puts "  - If output directory is omitted, 'output' under current directory is used."
    puts "  - Specifying the base URL causes the directory 'files' (stylesheets and other "
    puts "    auxiliary files) to be referred using that URL instead of relative links."
    puts "  - Default values may be defined in the file settings.yaml"
    puts "    (they can be overridden by command line options)."
    exit
  end
end.parse!

unless args.key? :input
  puts "An input file must be specified."
  abort "Try  '#{$0} --help' for usage options"
end

# -- Read configuration stuff --
md = OrfeoMetadata::MetadataModel.new
md.load

# Corpus name is the name of the (top) directory the files are in.
if File.directory? args[:input]
  corpname = File.basename args[:input]
else
  corpname = File.basename(File.expand_path('..', args[:input]))
end

corpus = OrfeoImporter::Corpus.new(corpname, md, 'data/corpora', args[:samples], args[:annis])


# -- Input --
Find.find(args[:input]) do |filepath|
  unless FileTest.directory?(filepath)
    files = []
    path = File.dirname filepath
    ext = File.extname filepath
    base = File.basename(filepath, ext)

    if ext == ".macaon" || ext == ".conll" || ext == '.orfeo'
      if File.zero? filepath
        puts "Skipping empty file #{filepath}"
        next
      end
      files << filepath
      ['.mp3', '.wav', '.xml', '.AvecHeader.xml', '.md.txt'].each do |ext|
        # Input files may be named inconsistently, e.g. sound files are
        # sometimes in all uppercase, so check for that too.
        if File.exist? File.join(path, base + ext)
          files << File.join(path, base + ext)
        elsif File.exist? File.join(path, base.upcase + ext)
          files << File.join(path, base.upcase + ext)
        end
      end
    end

    unless files.empty?
      puts "--- Input files found: ---"
      files.each_with_index{ |x, i| puts " #{i+1}. #{x}" }
      corpus.read_files File.basename(base), files unless files.empty?
    end
  end
end


# -- Update component/rank numbering (needed for relAnnis output) --
corpus.renumber_elements


# -- Output --
corpus.output_annis "#{args[:outputdir]}/annis/#{corpname}"
corpus.copy_files "#{args[:outputdir]}/web/#{corpname}"
corpus.output_html "#{args[:outputdir]}/web/#{corpname}"

corpus.index_solr args[:solr] if args.key? :solr
