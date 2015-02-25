# -*- coding: utf-8 -*-

module OrfeoImporter

  ##
  # A rank defined by an actual edge (of a dependency tree or similar)
  # instead of a "virtual" relationship.
  class EdgeRank < Rank
    attr :edge
    attr :edgetype

    def initialize(node, comp, edge, edgetype)
      super(node, comp)
      @edge = edge
      @edgetype = edgetype
    end

    def type
      'p'
    end

    def rank
      "#{@pre}\t#{@post}\t#{num}\t#{comp}\t#{parent ? parent.pre : 'NULL'}"
    end

    def edge_annotation
      "#{@pre}\tdefault_ns\tdeprel\t#{@edge.text}"
    end
  end
end
