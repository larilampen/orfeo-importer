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
    end
  end
end
