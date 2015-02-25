# -*- coding: utf-8 -*-

module OrfeoImporter

  ##
  # A locution is one locutionary action. Note that in conll files,
  # they are separated by empty lines, but in relAnnis, locutions are
  # pretty much ignored.
  class Locution
    attr :nodes
    attr :edges

    def initialize(nodes = [], edges = [])
      @nodes = nodes
      @edges = edges
    end

    def relabel
      @edges.each do |edge|
        edge.a = nodes[edge.a]
        edge.a.is_root = false
        edge.b = nodes[edge.b]
      end
      @nodes.each do |node|
        node.edges = @edges.select{ |edge| edge.b == node }
      end
    end

#    def addEdge(item)
#      raise 'not an edge' unless item.is_a? Edge
#      @edges.add item
#    end

#    def addNode(item)
#      raise 'not a node' unless item.is_a? Node
#      @nodes.add item
#    end

    def list_all
      puts " Nodes (#{@nodes.size}):"
      @nodes.each{ |node| puts "  #{node}"}
      puts " Edges (#{@edges.size}):"
      @edges.each{ |edge| puts "  #{edge}"}      
    end

    # Output JSON tokens readable by Arborator.
    def arborator_tokens
      s = ''
      @nodes.each_with_index do |node, i|
        s << ",\n" unless s.empty?
        s << "\"#{i+1}\": {"
        a = []
        edg = @edges.select{ |e| e.a == node }
        ed = []
        if node.features[:root]
          ed << "\"0\": \"#{node.features[:root]}\""
        end
        edg.each do |e|
          ed << "\"#{e.b.token_number+1}\": \"#{e.text}\""
        end
        a << "\"gov\": {#{ed.join(', ')}}"
        if node.features[:pos]
          a << "\"cat\": \"#{node.features[:pos]}\""
        end
        lemma = node.features[:lemma]
        lemma ||= '-'
        a << "\"lemma\": \"#{lemma}\""
        a << "\"t\": \"#{node.text}\""
        s << a.join(', ')
        s << '}'
      end
      s
    end

    def to_s
      s=''
      @nodes.each{ |node| s << node.text << " " }
      s
    end
  end
end
