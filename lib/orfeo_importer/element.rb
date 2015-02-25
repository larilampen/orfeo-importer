# -*- coding: utf-8 -*-

module OrfeoImporter

  ##
  # The items that make up the sample (i.e. nodes and edges) are all
  # elements. Each element has a component number (not necessarily
  # unique).
  class Element
    attr :component_number
    @@num = 0

    def initialize
      set_component
    end

    def set_component
      @component_number=@@num
      @@num += 1
    end

    def keep_component
      @component_number=@@num
    end

    def self.shift_next_component
      @@num += 1
    end

    def self.reset_components
      @@num = 0
    end
  end
end
