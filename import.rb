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
# 1. Set default values (if any).
args = { }

# 2. If defeaults are defined in YAML file, read them.
args.merge!(YAML.load_file('settings.yaml')) if File.exist? 'settings.yaml'

# 3. Read command line parameters.
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-i FILE", "--input=FILE", "Sets input file or directory") do |f|
    args[:input] = f
  end
  opts.on("-x URL", "--solr=URL", "Sets location of Solr index server") do |u|
    args[:solr] = u
  end
  opts.on("-a DIR", "--annisdir=DIR", "Sets output directory for ANNIS") do |u|
    args[:annis_dir] = u
  end
  opts.on("-u URL", "--annisurl=URL", "Sets base URL of ANNIS") do |u|
    args[:annis_url] = u
  end
  opts.on("-s DIR", "--samplesdir=DIR", "Sets output directory for sample pages") do |u|
    args[:samples_dir] = u
  end
  opts.on("-v URL", "--samplesurl=URL", "Sets base URL where sample pages are hosted") do |u|
    args[:samples_url] = u
  end
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    puts
    puts 'Note:'
    puts "  - If input is a directory, all files in it and any subdirectories will be processed."
    puts "  - If you don't specify at least one of Solr URL, ANNIS directory or samples directory,"
    puts "    Solr output will be omitted and directories 'output/annis' and 'output/web' under"
    puts '    the current directory used as outputs. Otherwise only those outputs are created'
    puts '    that have outputs defined on the command line.'
    puts "  - Specifying the base URL causes the directory 'files' (stylesheets and other "
    puts "    auxiliary files) to be referred using that URL instead of relative links."
    puts "  - Default values may be defined in the file settings.yaml"
    puts "    (they can be overridden by command line options)."
    exit
  end
end.parse!

# 4. Special case: if no outputs at all are defined, use defaults.
unless args.key?(:samples_dir) || args.key?(:annis_dir) || args.key?(:solr)
  args[:samples_dir] = 'output/web'
  args[:annis_dir] = 'output/annis'
end

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

corpus = OrfeoImporter::Corpus.new(corpname, md, 'data/corpora', args[:samples_url], args[:annis_url])


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
corpus.output_annis File.join(args[:annis_dir], corpname) if args.key? :annis_dir
if args.key? :samples_dir
  outdir = File.join(args[:samples_dir], corpname)
  corpus.copy_files outdir
  corpus.output_html outdir
end
corpus.index_solr args[:solr] if args.key? :solr
