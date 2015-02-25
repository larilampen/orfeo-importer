# -*- coding: utf-8 -*-

module OrfeoImporter

  ##
  # A node is basically a token in the text.
  class Node < Element
    # Text content of the token.
    attr :text

    attr :node_id

    # Timestamp representing alignment of this node on a timeline.
    attr_accessor :times

    # Edges for which this node is the governor.
    attr_accessor :edges

    # Number in original locution context (unrelated to element
    # number).
    attr :token_number

    attr_accessor :is_root

    # Gets/Sets the hash containing features of the token (e.g. lemma,
    # part-of-speech, ...).
    attr_accessor :features

    @@nodenum = 0

    def initialize(text, token_number, features, edges)
      super()
      @text = text
      @token_number = token_number
      @features = features
      @is_root = true
      @edges = edges
      @node_id=@@nodenum
      @@nodenum += 1
    end

    def to_s
      str = "#{@token_number}. #{@text}"
      unless features.empty?
        str << " { "
        features.each do |x,y|
          str << "#{x}->#{y} "
        end
        str << "}"
      end
      str
    end

    def component
      "#{@component_number}\tc\tdefault_ns\tNULL"
    end
  end
end
