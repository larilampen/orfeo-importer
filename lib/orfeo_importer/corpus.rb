# -*- coding: utf-8 -*-

require 'fileutils'
require 'rsolr'

module OrfeoImporter

  ##
  # A corpus is a collection of samples with its own metadata
  # (although for the moment, that metadata only comprises name, logo,
  # homepage URL and textual description).
  class Corpus
    attr :name
    attr :md
    attr :long_name
    attr :url
    attr :logo
    attr :desc

    def initialize(name, md, infodir = nil)
      @samples = []
      @name = name
      @md = md
      @long_name = nil

      read_info infodir unless infodir.nil?
    end

    def read_info infodir
      corpfile = File.join infodir, "#{@name}.txt"
      if File.exist? corpfile
        corpinfo = File.readlines corpfile
        corpinfo.each{ |line| line.chomp! }
        @long_name = corpinfo[0]
        @url = corpinfo[1]
        @logo = corpinfo[2]
        @logo_path = File.join(infodir, @logo)
        @desc = corpinfo[3]
      end
    end

    def copy_logo(dir)
      return unless @logo
      return if @logo.empty?
      FileUtils::cp @logo_path, dir unless File.exist? File.join(dir, @logo)
    end

    def read_files(name, files)
      sample = Sample.new(self, name)
      sample.read_files files
      @samples << sample
    end

    # ANNIS numbers elements sequentially with nodes first.  This
    # method assigns new numbers to all nodes and edges. It then
    # traverses the graph and finds the rank numbers (i.e. pre- and
    # post-order traversal rank) of each node.
    def renumber_elements
      # Set component numbers for nodes and edges.
      Element.reset_components
      @samples.each do |sample|
        sample.renumber_components
      end

      # Make a depth-first traversal through the entire tree graph and
      # update pre-order and post-order counters.
      rank_counter = 0
      @samples.each do |sample|
        rank_counter = sample.renumber_elements_rank rank_counter
      end
    end


    # Output the full relANNIS file set into the specified directory.
    def output_annis(dir)
      FileUtils::mkdir_p dir

      # Copy audio files, if there are any.
      mediadir = "#{dir}/ExtData"
      @samples.each do |sample|
        sample.prepare_audio mediadir
      end

      output_file "#{dir}/text.tab", method(:output_annis_text)
      output_file "#{dir}/corpus_annotation.tab", method(:output_annis_corpus_annotation)
      output_file "#{dir}/resolver_vis_map.tab", method(:output_annis_resolver_vis_map)
      output_file "#{dir}/corpus.tab", method(:output_annis_corpus)
      output_file "#{dir}/node.tab", method(:output_annis_node)
      output_file "#{dir}/node_annotation.tab", method(:output_annis_node_annotation)
      output_file "#{dir}/component.tab", method(:output_annis_component)
      output_file "#{dir}/edge_annotation.tab", method(:output_annis_edge_annotation)
      output_file "#{dir}/rank.tab", method(:output_annis_rank)
    end

    def output_annis_text(out)
      @samples.each_with_index do |sample, i|
        out.puts "#{i}\tsText1\t#{sample.text}"
      end
    end

    def output_annis_corpus(out)
      out.puts "0\t#{@name}\tCORPUS\tNULL\t0\t#{@samples.size*2+1}"
      @samples.each_with_index do |sample, i|
        out.puts "#{i+1}\t#{sample.name}\tDOCUMENT\tNULL\t#{i*2+1}\t#{i*2+2}"
      end
    end

    def output_annis_corpus_annotation(out)
      # Note: corpus-level metadata could be inserted here with index
      # 0. However currently the incoming metadata is only grouped by
      # sample and speaker.
      @samples.each_with_index do |sample, i|
        # First off, just include all metadata fields.
        sample.md_store.each do |field, val|
          if field.multi_valued?
            val.each do |v|
              out.puts "#{i+1}\tNULL\t#{field.name}\t#{v}" unless v.empty?
            end
          else
            out.puts "#{i+1}\tNULL\t#{field.name}\t#{val}"
          end
        end

        # Second, create a collated entry for each speaker.
        sample.md_store.enumerators_spe do |it, j|
          s = []
          it.each{ |field, v| s << "#{field.name}=#{v}" unless v.nil? || v.empty? }
          unless s.empty?
            combined = s.sort.join("; ")
            out.puts "#{i+1}\tNULL\tloc_info\t#{combined}"
          end
        end
      end
    end

    def output_annis_edge_annotation(out)
      @samples.each do |sample|
        sample.output_annis_edge_annotation out
      end
    end

    def output_annis_rank(out)
      @samples.each do |sample|
        sample.output_annis_rank out
      end
    end

    def output_annis_node(out)
      count = 0
      @samples.each_with_index do |sample, i|
        count += sample.output_annis_node out, i, count
      end
    end

    def output_annis_node_annotation(out)
      count = 0
      @samples.each_with_index do |sample, i|
        count += sample.output_annis_node_annotation out, count
      end
    end

    def output_annis_component(out)
      @samples.each do |sample|
        sample.output_annis_component out
      end
    end

    def output_annis_resolver_vis_map(out)
      # The syntax tree and audio file panels are displayed if at
      # least one sample has those elements. This is a corpus level
      # setting in ANNIS, so we can't fine-tune it further.
      @samples.each do |sample|
        if sample.has_dependencies
          out.puts "#{@name}\tNULL\tdefault_ns\tnode\tarch_dependency\tArbre syntaxique\t0\tNULL"
          break
        end
      end
      @samples.each do |sample|
        if sample.annis_audio_file
          out.puts "#{@name}\tNULL\tdefault_ns\tnode\taudio\tLecteur audio\t0\tNULL"
          break
        end
      end
    end

    # Output sample pages into files (one for each sample).
    def output_html(dir)
      FileUtils::mkdir_p dir
      FileUtils::cp_r 'data/files', dir unless File.exist? "#{dir}/files"
      @samples.each do |sample|
        sample.output_html dir
      end
    end

    # Call one of the output methods and store results into file.
    def output_file(filename, method)
      File.open(filename, 'w') { |file| method.call(file) }
    end

    # Call one of the output methods and send results to standard
    # output stream.
    def output_stdout(method)
      method.call($stdout)
    end

    # Index all documents into the given Solr instance. It must have
    # been correctly intialized with keys in the schema matching each
    # of the indexable metadata fields.
    def index_solr(url)
      solr = RSolr.connect :url => url

      @samples.each do |sample|
        sample.index_solr solr
      end

      solr.commit
      solr.update :data => '<optimize/>'
    end

    # Tell all samples to copy their source files into the specified
    # directory.
    def copy_files(dir)
      FileUtils::mkdir_p dir
      @samples.each do |sample|
        sample.copy_files dir
      end
    end

    def to_s
      return @long_name if @long_name
      @name
    end
  end
end
