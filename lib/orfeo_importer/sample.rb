# -*- coding: utf-8 -*-

$VERBOSE = true

require 'orfeo_metadata'
require 'fileutils'

require 'rexml/document'
include REXML

module OrfeoImporter

  ##
  # A sample is made up of graph nodes and edges which are also
  # contained within locutions (but the sample graph can be a single
  # locution).
  class Sample
    attr :loc
    attr :all_nodes
    attr :all_edges
    attr :all_ranks
    attr :corpus
    attr :name
    attr :audio_file
    attr :annis_audio_file
    attr :files
    attr :stack
    attr :has_alignment
    attr :has_dependencies
    attr :has_speakers
    attr :md_store

    def initialize(corpus, name, loc = [])
      @loc = loc
      @all_nodes = []
      @all_edges = []
      @all_ranks = []
      @files = []
      @has_alignment = false
      @has_dependencies = false
      @has_speakers = false
      @corpus = corpus
      @name = name
      @md_store = OrfeoMetadata::MetadataStore.new(corpus.md)
    end

    def add(item)
      raise 'not a locution' unless item.is_a? Locution
      @loc << item

      @all_nodes += item.nodes
      @all_edges += item.edges
    end

    # Reset component numbers for nodes and edges. These are used by
    # ANNIS to itemize "unique components" (see documentation for
    # details).
    def renumber_components
      # For nodes this is very straightforward.
      @all_nodes.each{ |node| node.set_component }

      # For edges, a component is a subgraph starting at a root node.
      @all_nodes.each do |node|
        next unless node.is_root
        next if node.edges.empty?
        node.edges.each do |edge|
          edge.keep_component
        end

        Element.shift_next_component 
      end
    end

    # ANNIS uses the order of traversal to reconstruct the document
    # graph. This method traverses the graph and updated rank numbers
    # (i.e. pre- and post-order traversal rank) of nodes and edges.
    def renumber_elements_rank(counter)
      # Compute rank and component numbers.
      @stack = TraversalOrderStack.new counter
      @all_nodes.each do |node|
        comp = node.component_number
        @stack.push SpanRank.new(node, comp)
        @stack.push Rank.new(node, comp)
        @stack.pop
        @stack.pop
      end
      ccc = -1
      @all_nodes.each do |node|
        if node.is_root
          ccc = stack.last_component + 1 if ccc == -1
          ccc = traverse_node node, nil, ccc
        end
      end
      return @stack.counter + 1
    end

    def list_all
      puts "There are #{@loc.size} locutions"
      @loc.each do |x|
        puts "Locution:"
        x.list_all
      end
    end

    # Place audio file in the correct directory, if applicable.
    # Returns true if audio file exists and alignment information
    # exists.
    def prepare_audio(outputdir)
      if @has_alignment && @audio_file
        mediadir = "#{outputdir}/#{@name}"
        FileUtils::mkdir_p mediadir
        FileUtils::cp @audio_file, mediadir
        @annis_audio_file = "#{@name}/#{File.basename @audio_file}"
        return true
      end
      @annis_audio_file = nil
      false
    end

    def output_annis_component(out)
      # One line per node.
      @all_nodes.each{ |node| out.puts node.component }

      # To find components, consider only edges from root nodes.
      @all_nodes.each do |node| 
        if node.is_root && !node.edges.empty?
          out.puts node.edges[0].component
        end
      end
    end

    def text
      str = ''
      @all_nodes.each_with_index do |x, i|
        str << x.text
        str << ' ' unless i == @all_nodes.length-1
      end
      return str
    end

    def output_annis_node(out, num, base)
      char = 0
      @all_nodes.each_with_index do |x, i|
        endpoint = char + x.text.length
        out.puts "#{base+2*i}\t#{num}\t#{num+1}\ttoken\tsTok#{i+1}\t#{char}\t#{endpoint}\t#{i}\tNULL\tNULL\tNULL\ttrue\t#{x.text}"
        out.puts "#{base+2*i+1}\t#{num}\t#{num+1}\tdefault_ns\tsSpan#{i+1}\t#{char}\t#{endpoint}\tNULL\tNULL\tNULL\tNULL\ttrue\tNULL"
        char = endpoint + 1
      end
      if @annis_audio_file
        out.puts "#{base+2*@all_nodes.size}\t#{num}\t#{num+1}\taudio\tzyy\t0\t#{char-1}\tNULL\tNULL\tNULL\tNULL\ttrue\tNULL"
        return 2*@all_nodes.size+1
      end
      return 2*@all_nodes.size
    end

    def output_annis_node_annotation(out, base)
      @all_nodes.each_with_index do |x, i|
        if x.features[:lemma]
          out.puts "#{base+2*i}\tsaltSemantics\tLEMMA\t#{x.features[:lemma]}"
        end
        if x.features[:pos]
          out.puts "#{base+2*i}\tsaltSemantics\tPOS\t#{x.features[:pos]}"
        end
        if x.features[:speaker]
          out.puts "#{base+2*i}\tdefault_ns\tspeaker\t#{x.features[:speaker]}"
        end
        if x.features[:morph]
          out.puts "#{base+2*i}\tdefault_ns\tmorph\t#{x.features[:morph]}"
        end
        if x.times
          out.puts "#{base+2*i}\tannis\ttime\t#{x.times.from}-#{x.times.to}"
        end
        out.puts "#{base+2*i+1}\tdefault_ns\tcat\tS"
      end
      if @annis_audio_file
        out.puts "#{base+2*@all_nodes.size}\taudio\taudio\t[ExtFile]#{@annis_audio_file}"
        return 2*@all_nodes.size+1
      end
      return 2*@all_nodes.size
    end

    def output_annis_edge_annotation(out)
      @stack.results.each do |rank|
        if (rank.parent) && (rank.instance_of? EdgeRank)
            out.puts rank.edge_annotation
        end
      end
    end

    def output_annis_rank(out)
      stack.results.each do |x|
        out.puts x
      end
    end

    # Read dependency tree from a CoNLL file.
    def read_conll(filename)
      File.open(filename) do |file|
        nodes=[]
        edges=[]
        count = 0
        file.each do |line|
          line.chomp!
          if line =~ /^\s*$/
            locution = Locution.new(nodes, edges)
            locution.relabel
            add locution
            nodes = []
            edges = []
          else
            fields = line.split(/\t/)
            if fields.size < 10
              puts "Warning: skipping malformed line #{line}"
              next
            end
            feat = {}
            n1 = Integer(fields[0]) - 1
            if fields[6] == '_'
              # If governor is empty, consider this a non-root
              # governorless token.
              n2 = -1
            else
              n2 = Integer(fields[6]) - 1
              # If the node is marked as root in conll, make a note of
              # that, but as a feature instead of an explicit edge.
              if n2 == -1
                feat[:root] = fields[7]
              end
            end
            feat[:pos] = fields[3] unless fields[3] == '_'
            feat[:lemma] = fields[2] unless fields[2] == '_'
            feat[:morph] = fields[5] unless fields[5] == '_'

            text = fields[1]
            # Multi-word tokens use # as separator.
            text.sub! '#',' '
            newnode = Node.new(text, n1, feat, [])

            if fields.size >= 12
              newnode.times = Timestamp.new(fields[10], fields[11])
              @has_alignment = true
              if fields.size >= 13
                newnode.features[:speaker] = fields[12]
                @has_speakers = true
              end
            end
            nodes[n1] = newnode

            edges << Edge.new(n1, n2, fields[7]) if n2 >= 0
          end
          count += 1
          
          puts "#{filename}: #{count} lines read" if count % 10000 == 0
        end

        # Don't forget the last locution of the file.
        unless nodes.empty?
          locution = Locution.new(nodes, edges)
          locution.relabel
          add locution
        end
      end
      @has_dependencies = true
    end

    # Read tree structure and time alignments from a .macaon file.
    def read_macaon(filename)
      xmldoc = Document.new File.new(filename)
      XPath.each(xmldoc, '/document/content/macaon/sentence') do |u|
        tokens = []
        timestamps = []
        counter = 0
        XPath.each(u, "./section[@type='prelex']/segs/seg[@stype='wtoken']") do |tok|
          tokens << tok.attributes['val']
          timestamps << Timestamp.new(tok.attributes['start'], tok.attributes['end'])
          counter += 1
        end

        nodes = []
        edges = []

        # TODO: Note this is a bit of a hack. The prelex tokens are in
        # reverse order vis-a-vis the morphological entries. But this
        # should not be assumed always -- they should be ordered based
        # on the actual timestamps.

        # FIRST PASS: Create nodes with all features, but no connections.
        XPath.each(u, "./section[@type='morpho']/segs/seg[@type='cat']") do |tok|
          counter -= 1
          feat = {}
          feat[:lemma] = tok.attributes['lemma'] if tok.attributes.key? 'lemma'
          feat[:pos] = tok.attributes['stype'] if tok.attributes.key? 'stype'
          if u.attributes.key? 'spk'
            @has_speakers = true
            feat[:speaker] = u.attributes['spk']
          end
          feat[:macaon_id] = tok.attributes['id'] if tok.attributes.key? 'id'
          node = Node.new(tokens[counter], counter, feat, [])
          node.times = timestamps[counter]
          nodes << node
        end

        # SECOND PASS: Add in edges.
        counter = 0
        XPath.each(u, "./section[@type='morpho']/segs/seg[@type='cat']") do |tok|
          if tok.attributes.key? 'gov'
            gov_id = tok.attributes['gov']
            gov = nodes.find{ |x| x.features[:macaon_id] == gov_id }
            if gov
              edges << Edge.new(nodes[counter], gov, tok.attributes['fct'])
            end
          else
            # Mark every node without a governor as a root. In some
            # cases some governorless nodes are considered roots while
            # others are not, but there is not enough information in
            # the Macaon files to make that distinction.
            nodes[counter].features[:root] = 'ROOT'
          end
          counter += 1
        end
        nodes.reverse!
        add Locution.new(nodes, edges)
      end
      puts "Done"
      @has_alignment = true
      @has_dependencies = true
    end

    # ----------------------------------------------------------------
    # Read time alignment from a DOM tree corresponding to a TEI file,
    # assuming the equivalent dependency tree has already been
    # initialized from a CoNLL file. Statistics will be updated if
    # provided.
    def read_tei_alignment(xmldoc, stats = nil)
      # First, parse aligned tokens into an array. Each entry is a
      # token with start and end times. Elements separated by hyphens
      # are collated but no other processing is done to the tokens at
      # this stage.
      ns = {'t' => 'http://www.tei-c.org/ns/1.0'}
      timestamps = []
      append=false
      XPath.each(xmldoc, '/t:TEI/t:text/t:body/t:u', ns) do |u|
        time = u.attributes['start']
        text = ''

        # A simpler loop would start with 'u.elements.each do |child|'
        # but due to the hyphen appearing as a text node (not inside
        # an element), that can't be used here.
        XPath.each(u, './node()', ns) do |child|
          if child.instance_of? REXML::Text
            if child.to_s == '-'
              text << '-'
              append = true
            end
          else
            if child.name == 'w'
              if append
                text << child.text
              else
                text = child.text
              end
            elsif child.name == 'anchor'
              newtime = child.attributes['synch']
              unless text.empty?
                timestamps << Timestamp.new(time.sub(/^#t/, ''), newtime.sub(/^#t/, ''), text)
                text = ''
              end
              time = newtime
              append = false
            end
          end
        end
      end

      # Loop through arrays of time-aligned tokens from the TEI file
      # (time) and tokens from the conll source (token). Due to
      # differences in tokenization, some normalization is necessary.
      time_idx = 0
      token_idx = 0
      while token_idx < @all_nodes.size && time_idx < timestamps.size
        ts = timestamps[time_idx]
        token = @all_nodes[token_idx]

        if ts.text == token.text
          stats.add "OK" if stats
          token.times = ts
          time_idx += 1
          token_idx += 1
        else
          tok_clean=token.text.gsub(/[^\p{Alnum}\p{Space}]/u, '')
          ts_clean=ts.text.gsub(/[^\p{Alnum}\p{Space}]/u, '')
          if tok_clean == ts_clean
            stats.add "OK" if stats
            token.times = ts
            time_idx += 1
            token_idx += 1
          elsif !(token.text =~ /[[:alnum:]]+/)
            stats.add "Skip token (no letters)" if stats
            token_idx += 1
          elsif token.text =~ / |-/
            parts = token.text.split(/[#-]/)
            if parts[0] == ts.text
              parts.each_with_index do |x, i|
                unless x == timestamps[time_idx + i].text
                  stats.add "Mismatch in multipart token (inner)" if stats
                  # We have no idea what to do now, so we'll try
                  # skipping the token.
                  token_idx += 1
                  next
                end
              end

              # Create new timestamp merging the starting point of the
              # first sub-token with the ending point of the last
              # sub-token.
              stats.add "OK" if stats
              token.times = Timestamp.new ts.from, timestamps[time_idx+parts.size-1].to
              time_idx += parts.size
              token_idx += 1
            else
              stats.add "Mismatch in multipart token (initial)" if stats
              # We have no idea what to do now, so we'll try
              # skipping the token.
              token_idx += 1
              next
            end
          else
            # This should not be necesssary, but it is added to
            # account for errors in source files where some tokens are
            # missing from the conll file but appear in the
            # corresponding TEI file.
            stats.add "Skip timestamp (no matching token)" if stats
            time_idx += 1
          end
        end
      end
      @has_alignment = true unless timestamps.empty?
      puts "OK (#{timestamps.size} timestamps -- #{@all_nodes.size} tokens)"
    end

    # Read a set of files, possibly in various formats, but all related
    # to a single sample.
    def read_files(files)
      @files = files

      # For audio, the *first* mp3 file in the list is used, or if
      # there are none, the first wav file.
      @audio_file = files.find{|x| x.end_with? '.mp3'}
      @audio_file ||= files.find{|x| x.end_with? '.wav'}

      # For each type, only the FIRST file of said type is considered.
      mac = files.find{ |x| x.end_with? '.macaon' }
      con = files.find{ |x| x.end_with?('.orfeo') || x.end_with?('.conll') }
      tei = files.find{ |x| x.end_with? '.xml' }
      tei_doc = nil

      # Read metadata from TEI file, if available.
      if tei
        tei_doc = Document.new File.new(tei)
        @md_store.read_tei tei_doc
      end
      @md_store.set_defaults self

      if mac
        read_macaon mac
      elsif con
        read_conll con
        if (!@has_alignment) && tei_doc
          stats = Stat.new "Statistics for input from TEI file #{tei}"
          read_tei_alignment tei_doc, stats
          stats.show unless stats.empty?
        end
      end
    end

    # Copy all source files into another directory.
    def copy_files(outputdir)
      @files.each do |file|
        FileUtils::cp file, outputdir
      end
    end

    def output_html(outputdir)
      FileUtils::cp @audio_file, outputdir if @audio_file

      if @name.nil?
        filename = File.join outputdir, 'sample.html'
      else
        filename = File.join outputdir, "#{@name}.html"
      end
      js_header = ''
      if @has_dependencies
        js_header << '<script type="text/javascript" src="files/raphael.js"></script>'
        js_header << '<script type="text/javascript" src="files/arborator.view.js"></script>'
      end

      sample_name = @md_store.by_name 'nomFichier'
      resume = @md_store.by_name 'resume'
      if resume
        page = SimpleHtml::Page.new(resume, "Un échantillon avec identifiant <strong>#{sample_name}</strong> dans le corpus <strong>#{@corpus}</strong>", filename, js_header)
      else
        page = SimpleHtml::Page.new(sample_name, "Un échantillon dans le corpus <strong>#{@corpus}</strong>", filename, js_header)
      end

      page.panel("Corpus #{@corpus}") do |out|
        if @corpus.long_name
          out.puts "<p>"
          unless @corpus.logo.empty?
            @corpus.copy_logo outputdir
            out.puts "<img src=\"#{@corpus.logo}\"/>"
            out.puts "<br clear=\"left\"/>"
          end
          out.puts @corpus.desc
          out.puts "</p>"

          out.puts "<p>"
          out.puts "<a href=\"#{@corpus.url}\" target=\"_blank\">Homepage</a>"
          out.puts "</p>"

          out.puts <<eos
          <form action="form.html">
            <p>Rechercher dans ce corpus: <input type="text" name="corpussearch">
            <input type="submit" value="Recherche simple">
            <input type="submit" value="Recherche avancée avec AQL">
            </p>
          </form>
eos
        else
          out.puts "<p>Il n'y a aucune information disponible pour ce corpus.</p>"
        end
      end

      page.infopanel "Métadonnées : general", @md_store.each_gen

      @md_store.enumerators_spe do |it, i|
        speaker = @md_store.by_name('identifiant')[i]
        speaker ||= "##{i}"
        page.infopanel "Métadonnées : locuteur #{speaker}", it
      end

      # The aligned audio player is only shown when alignments and an
      # audio file are available.
      if @has_alignment && @audio_file
        audio_type = (@audio_file.end_with? '.mp3') ? 'audio/mp3' : 'audio/wav'
        page.panel("Texte et audio") do |out|
          out.puts <<eof
            <p class="loading">
                <em>Loading audio…</em>
            </p>

            <p class="passage-audio" hidden>
                <audio id="passage-audio" class="passage" controls>
                    <source src="#{File.basename @audio_file}" type="#{audio_type}">
                    <em class="error"><strong>Error:</strong> Your browser doesn't appear to support HTML5 Audio.</em>
                </audio>
            </p>
            <p class="passage-audio-unavailable" hidden>
                <em class="error"><strong>Error:</strong> You will not be able to do the read-along audio because your browser is not able to play MP3, Ogg, or WAV audio formats.</em>
            </p>

            <p class="playback-rate" hidden title="Note that increaseing the reading rate will decrease accuracy of word highlights">
                <label for="playback-rate">Vitesse de lecture:</label>
                <input id="playback-rate" type="range" min="0.5" max="2.0" value="1.0" step="0.1" disabled onchange='this.nextElementSibling.textContent = String(Math.round(this.valueAsNumber * 10) / 10) + "\u00D7";'>
                <output>1&times;</output>
            </p>
            <p class="playback-rate-unavailable" hidden>
                <em>(It seems your browser does not support <code>HTMLMediaElement.playbackRate</code>, so you will not be able to change the speech rate.)</em>
            </p>
            <p class="autofocus-current-word" hidden>
                <input type="checkbox" id="autofocus-current-word" checked>
                <label for="autofocus-current-word">Surligner mot courant</label>
            </p>

            <noscript>
                <p class="error"><em><strong>Notice:</strong> JavaScript est nécessaire.</em></p>
            </noscript>
eof

          out.puts '<div id="passage-text" class="passage">'
          prev_speaker = nil
          @all_nodes.each_with_index do |x, i|
            if x.times.nil?
              out.print " #{x.text}"
            else
              beg = x.times.from.to_f
              dur = x.times.to.to_f - beg
              if @has_speakers
                speaker = (x.features.key? :speaker) ? x.features[:speaker] : '?'
                if speaker != prev_speaker
                  if prev_speaker.nil?
                    out.puts '<table>'
                  else
                    out.puts '</td></tr>'
                  end
                  out.print "<tr><td class=\"speaker\">#{speaker}:</td> <td class=\"speech\">"
                  prev_speaker = speaker
                end
              end
              out.print " <span data-dur=\"%.3f\" data-begin=\"%.3f\">#{x.text}</span>" % [dur, beg]
            end
          end
          if @has_speakers
            out.puts '</td></tr>'
            out.puts '</table>'
          end
          out.puts '</div>'

          out.puts '<script src="files/read-along.js"></script>'
          out.puts '<script src="files/read-along-main.js"></script>'
        end
      else
        page.panel("Texte") do |out|
          out.puts text
        end
      end

      if @has_dependencies
        page.panel("Arbres syntaxiques", 'initPanel') do |out|
          out.puts '<div class="progress" id="progress"></div>'
          out.puts '<script type="text/javascript">'

          @loc.each_with_index do |loc, i|
            out.puts "function drawTr#{i}() {"
            out.puts "  draw(\"holder#{i+1}\",{#{loc.arborator_tokens}}); "
            out.puts "  if (circle !== null) {"
            out.puts "    circle.set(#{(i+1).to_f/@loc.size});"
            if i+1 < @loc.size
              out.puts "    setTimeout(drawTr#{i+1}, 5);"
            else
              out.puts "    setTimeout(cleanProg, 300);"
            end
            out.puts '  }'
            out.puts '};'
          end

          out.puts "function cleanProg() {"
          out.puts "  if (circle !== null) {"
          out.puts "    circle.destroy();"
          out.puts "    circle = null;"
          out.puts "    hideTable(document.getElementById('progress'));"
          out.puts "  };"
          out.puts "}"

          out.puts 'var circle = null;'

          out.puts 'function initPanel(opened) {'
          out.puts "  if (opened) {"
          out.puts "    showTable(document.getElementById('progress'));"
          out.puts "    circle = new ProgressBar.Circle('#progress', {"
          out.puts "      color: '#2020d0',"
          out.puts '      strokeWidth: 5,'
          out.puts '      trailWidth: 1,'
          out.puts '      duration: 30,'
          out.puts '      text: {'
          out.puts "          value: '0'"
          out.puts '      },'
          out.puts '      step: function(state, bar) {'
          out.puts '          bar.setText((bar.value() * 100).toFixed(0));'
          out.puts '      }})'
          out.puts "    setTimeout(drawTr0, 10);"

          out.puts '  } else {'
          out.puts '    cleanProg();'
          out.puts '  }'
          out.puts '};'

          out.puts '</script>'

          @loc.each_with_index do |loc, i|
            out.puts "<div id='sentencediv#{i+1}' class='sentencediv' style=\"margin:10px;\">"
            out.puts "#{i+1}: #{loc}"
            out.puts '</div>'
            out.puts "<div id=\"holder#{i+1}\" class=\"svgholder\" style=\"overflow: auto;\"> </div>"
          end
        end
      end

      page.panel("Fichiers") do |out|
        out.puts '<table cellpadding="0" cellspacing="0">'
        out.puts '<tbody>'
        out.puts '<tr>'
        out.puts "<th align=\"left\" class=\"assetHeader nobottomborder\">Nom fichier</th>"
        out.puts "<th align=\"left\" class=\"assetHeader nobottomborder\">Lien</th>"
        out.puts "<th align=\"left\" class=\"assetHeader nobottomborder\">Taille (bytes)</th>"
        out.puts '</tr>'
        @files.each do |file|
          out.puts '<tr>'
          out.puts "<td class=\"noleftborder\">#{File.basename file}</td>"
          out.puts "<td><a href=\"#{File.basename file}\">fichier</a></td>"
          out.puts "<td>#{File.size file}</td>"
          out.puts '</tr>'
        end
        out.puts '</tbody></table>'
      end

      page.close
    end

    def index_solr(solr)
      index = {}
      @md_store.each do |field, value|
        if field.indexable?
          index[field.name.to_sym] = value
        end
      end

      # In addition to metadata, the text content must of course also
      # be indexed.
      index[:text] = text

      # A unique ID is mandatory. This is just the name of the input
      # file; maybe more is required to ensure it is unique.
      index[:id] = @name
      solr.add index
    end

    private
    def traverse_node(node, edge = nil, comp = 0)
      edges = node.edges

      # If a root node has no children, it is not traversed at all.
      return comp if edges.empty? && edge.nil?

      # The rank is created with a dummy component number; it is set
      # in post-traversal order (below).
      newrank = EdgeRank.new(node, 0, edge, 'dep') 
      @stack.push newrank
      edges.each do |next_edge|
        comp = traverse_node next_edge.a, next_edge, comp
      end
      @stack.pop

      newrank.comp = comp

      # If there is nothing more to traverse, the next root node will
      # define a separate component.
      comp += 1 if edge.nil?
      return comp
    end
  end
end
