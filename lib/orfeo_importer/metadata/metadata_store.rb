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
        @model.fields_gen.each { |field| @field_by_name[field.name] = field }
        @model.fields_spe.each { |field| @field_by_name[field.name] = field }
        @gen_by_field = {}
        @spe_by_field = []
      end

      # Parse metadata from a TEI document (represented as a DOM
      # tree).
      def read_tei(xmldoc)
        @model.fields_gen.each do |field|
          val = XPath.first(xmldoc, field.xpath)
          add field, val if val
        end
        @model.fields_spe.each do |field|
          counter = 0
          XPath.each(xmldoc, field.xpath) do |val|
            if val
              add field, val, counter
            end
            counter += 1
          end
        end
      end

      def add(field, value, sp_counter = nil)
        raise 'not a field' unless field.is_a? MetadataField
        if sp_counter.nil?
          @gen_by_field[field] = value
        else
          @spe_by_field[sp_counter] ||= {}
          @spe_by_field[sp_counter][field] = value
        end
      end

      def field(name)
        @field_by_name[name]
      end

      def gen_by_name(name)
        @gen_by_field[@field_by_name[name]]
      end

      def spe_by_name(name, num)
        @spe_by_field[num][@field_by_name[name]]
      end

      def value_by_field(field)
        @value_by_field[field]
      end
      
      # Loop through specific metadata groups (i.e. speakers) and
      # yield an enumerator to each one in turn, along with the number
      # of the group.
      def enumerators_spe(&block)
        @spe_by_field.each_with_index do |hash, i|
          yield each_spe_num(i), i
        end
      end

      # Iterate through general metadata.
      def each_gen(&block)
        return enum_for(:each_gen) unless block_given?
        @gen_by_field.each do |k, v|
          block.yield k, v
        end
      end

      # Iterate through specific metadata of the given speaker.
      def each_spe_num(num, &block)
        unless block_given?
          return Enumerator.new do |y|
            @spe_by_field[num].each do |k, v|
              y.yield k, v
            end
          end
        end

        @spe_by_field[num].each do |k, v|
          block.yield k, v
        end
      end

      # Iterate through all speaker metadata, yielding triplets of the
      # form (group number, key, value).
      def each_spe(&block)
        @spe_by_field.each_with_index do |hash, i|
          hash.each do |k, v|
            block.yield i, k, v
          end
        end
      end
    end
  end
end
