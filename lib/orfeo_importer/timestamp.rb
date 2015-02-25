# -*- coding: utf-8 -*-

module OrfeoImporter

  ##
  # A time-aligned datum.
  class Timestamp
    attr_accessor :from
    attr_accessor :to
    attr_accessor :text

    def initialize(from, to, text = nil)
      @from = from
      @to = to
      @text = text
    end
  end
end
