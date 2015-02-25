# -*- coding: utf-8 -*-

module OrfeoImporter

  ##
  # A rank corresponding to the textual span of a node.
  class SpanRank < Rank
    def num
      @node.node_id * 2 + 1
    end
  end
end
