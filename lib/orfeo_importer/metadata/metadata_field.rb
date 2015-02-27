# -*- coding: utf-8 -*-

module OrfeoImporter
  module Metadata

    ##
    # A single metadata field.
    class MetadataField
      attr :name
      attr :desc
      attr :xpath

      def initialize(name, xpath, display = nil, desc = nil)
        @name = name
        @xpath = xpath
        @display = display
        @desc = desc
      end

      # Facets and "searchable" fields are indexable.
      def indexable?
        @display == 'f' || @display == 's' || @display == 'i'
      end

      def to_s
        return desc unless desc.nil? || desc.empty?
        name
      end
    end
  end
end
