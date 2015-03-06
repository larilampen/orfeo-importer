# -*- coding: utf-8 -*-

module OrfeoImporter

  ##
  # Simple stack that sets the pre- and post-traversal counters in
  # each of the inserted objects.
  class TraversalOrderStack
    attr :counter
    attr :results
    attr :last_component

    def initialize(counter = 0)
      reset counter
    end

    def reset(counter = 0)
      @stack = []
      @counter = counter - 1
      @results = []
      @last_component = nil
    end

    def push(item)
      @counter += 1
      item.pre = @counter
      item.parent = @stack.last unless @stack.empty?
      @stack.push item
    end

    def pop
      @counter += 1
      item = @stack.pop
      item.post = @counter
      @last_component = item.node.component_number if item.instance_of? Rank
      results.push item
      return item
    end
  end
end
