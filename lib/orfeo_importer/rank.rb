# -*- coding: utf-8 -*-

module OrfeoImporter

  ##
  # Rank indicates the position of each node in a traversal of the
  # graph. (A single node can be encountered multiple times during
  # traversal and thus have multiple ranks.)
  class Rank
    attr_accessor :pre
    attr_accessor :post
    attr :node
    attr_accessor :parent
    attr_accessor :comp

    def initialize(node, comp)
      @node = node
      @comp = comp
      #      @parent = parent
    end

    def to_s
      rank
    end

    def num
      @node.node_id * 2
    end

    def type
      'c'
    end

    def rank
      "#{@pre}\t#{@post}\t#{num}\t#{@node.component_number}\t#{parent ? parent.pre : 'NULL'}"
    end
  end
end
