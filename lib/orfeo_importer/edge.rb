# -*- coding: utf-8 -*-

module OrfeoImporter

  ##
  # An edge is a connection (e.g. dependency) between two nodes.
  class Edge < Element
    attr_accessor :a
    attr_accessor :b
    attr :text

    def initialize(a, b, text)
      super()
      @a = a
      @b = b
      @text = text
    end

    def to_s
      "#{@a} --> #{@b} <<#{@component_number}>>"
    end

    # Currently all edges belong to dependency trees, but this may be
    # expaned in the future.
    def name
      'dep'
    end

    def component
      "#{@component_number}\tp\tdefault_ns\tdep"
    end
  end
end
