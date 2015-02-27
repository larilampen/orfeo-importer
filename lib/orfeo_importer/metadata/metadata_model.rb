# -*- coding: utf-8 -*-

module OrfeoImporter
  module Metadata

    ##
    # The set of all metadata fields, both sample level and speaker
    # level.
    class MetadataModel
      attr :fields_gen
      attr :fields_spe

      def initialize
        @fields_gen = []
        @fields_spe = []
      end

      def load(filename)
        # Skip the first line since it's used for headers.
        File.readlines(filename).drop(1).each do |line| 
          line.chomp!
          fields = line.split(/\t/)
          new_field = MetadataField.new(fields[0], fields[3], fields[4], fields[1])
          if fields[2] == 'g'
            fields_gen << new_field
          else
            fields_spe << new_field
          end
        end
      end

      # Output definitions of the indexable metadata fields in Solr
      # schema format (not a complete schema file, just the field
      # definitions).
      def output_schema(out)
        common = 'type="string" indexed="true" stored="true"'
        @fields_gen.each do |field|
          if field.indexable?
            out.puts "<field name=\"#{field.name}\" #{common} multiValued=\"false\"/>"
          end
        end
        @fields_spe.each do |field|
          if field.indexable?
            out.puts "<field name=\"#{field.name}\" #{common} multiValued=\"true\"/>"
          end
        end
      end
    end
  end
end
