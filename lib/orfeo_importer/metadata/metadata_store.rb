# -*- coding: utf-8 -*-

require 'rexml/document'
include REXML

module OrfeoImporter
  module Metadata

    ##
    # The metadata fields and the corresponding values associated with
    # a single sample (and the speakers within it).
    class MetadataStore
      def initialize(model)
        @model = model
        @field_by_name = {}
        @model.fields.each { |field| @field_by_name[field.name] = field }
        @val_by_field = {}
        @num_spe = 0
      end

      # Parse metadata from a TEI document (represented as a DOM
      # tree).
      def read_tei(xmldoc)
        # Note that line breaks must be removed from metadata values.
        @model.fields.each do |field|
          if field.multi_valued?
            val = []
            XPath.each(xmldoc, field.xpath) do |n|
              text = n.to_s.gsub(/[\n\r]/, '').strip
              # To maintain ordering, all multi-valued elements are stored even if empty.
              val << text
            end
            # The number of speakers is the highest number of speaker-level values available.
            @num_spe = val.size if val.size > @num_spe
          else
            val = XPath.first(xmldoc, field.xpath).to_s.gsub(/[\n\r]/, '').strip
          end
          @val_by_field[field] = val unless val.empty?
        end
      end

      def field(name)
        @field_by_name[name]
      end

      def by_name(name)
        @val_by_field[@field_by_name[name]]
      end

      def by_field(field)
        @val_by_field[field]
      end

      # Loop through specific metadata groups (i.e. speakers) and
      # yield an enumerator to each one in turn, along with the number
      # of the group.
      def enumerators_spe(&block)
        @num_spe.times do |i|
          yield each_spe_num(i), i
        end
      end

      # Iterate through all metadata.
      def each(&block)
        return enum_for(:each) unless block_given?
        @val_by_field.each do |k, v|
          block.yield k, v
        end
      end

      # Iterate through general metadata.
      def each_gen(&block)
        return enum_for(:each_gen) unless block_given?
        @val_by_field.reject{ |k, v| k.specific? }.each do |k, v|
          block.yield k, v
        end
      end

      # Iterate through speaker metadata.
      def each_spe(&block)
        return enum_for(:each_spe) unless block_given?
        @val_by_field.select{ |k, v| k.specific? }.each do |k, v|
          block.yield k, v
        end
      end

      # Iterate through speaker metadata of the given speaker only.
      def each_spe_num(num, &block)
        unless block_given?
          return Enumerator.new do |y|
            each_spe do |k, v|
              y.yield k, v[num]
            end
          end
        end
        each_spe do |k, v|
          block.yield k, v[num]
        end
      end
    end
  end
end
