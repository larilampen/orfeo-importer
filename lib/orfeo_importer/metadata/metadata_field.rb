# -*- coding: utf-8 -*-

module OrfeoImporter
  module Metadata

    ##
    # A single metadata field.
    class MetadataField
      attr :name
      attr :desc
      attr :xpath

      def initialize(name, xpath, indexable, specific, facet = false, search_target = false, multi_valued = false, desc = nil)
        @name = name
        @xpath = xpath
        @desc = desc
        @indexable = indexable
        @specific = specific
        @multi_valued = multi_valued
        @facet = facet
        @search_target = search_target
      end

      # Facets and "searchable" fields are indexable.
      def indexable?
        @indexable
      end

      def multi_valued?
        @multi_valued
      end

      def specific?
        @specific
      end

      def facet?
        @facet
      end

      def search_target?
        @search_target
      end

      def to_s
        return desc unless desc.nil? || desc.empty?
        name
      end
    end
  end
end
