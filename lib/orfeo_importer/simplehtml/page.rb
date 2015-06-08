# -*- coding: utf-8 -*-

require 'date'

module OrfeoImporter
module SimpleHtml

  ##
  # A single HTML page of a specific look. This is
  # not at all general at the moment.
  class Page
    attr :out
    attr :counter

    def initialize(pagetitle, subtitle, files_dir, filename = nil, headerstuff = "")
      @counter = 1
      @files_dir = files_dir
      if filename.nil?
        @out = $stdout
      else
        @out = File.new(filename, "w")
      end
      out.puts <<-EOS
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"><head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<meta http-equiv="X-UA-Compatible" content="IE=edge"/>
<title>#{pagetitle}</title>
<link rel="stylesheet" type="text/css" media="all" href="#{@files_dir}/stmt_screen_v2.css"/>
<link rel="stylesheet" type="text/css" media="all" href="#{@files_dir}/stmt_grid_fluid_max.css"/>
<script src="#{@files_dir}/stmt_v2.js" type="text/javascript" language="Javascript"></script>
<script src="#{@files_dir}/progressbar.min.js" type="text/javascript" language="Javascript"></script>
<script src="#{@files_dir}/jquery.js" type="text/javascript" language="Javascript"></script>
#{headerstuff}
<script type="text/javascript">
$(function(){
	$('.summaryRow').click(function() {
		$(this).closest('tbody').next('.detailRows').toggle('fast');
		$(this).find('span').text(function(_, value) {
			return value == '-' ? '+' : '-';
		});
	});
});
</script>
</head>

<body>
<div class="container_12">
<div class="grid_2 stmt_header"><img src="#{@files_dir}/logo-orfeo.png" align="left" id="logo_img" alt="Orfeo"/></div>
<div class="grid_8 stmt_header2 center"><br/><h1>#{pagetitle}</h1><br/>#{subtitle}</div>
<div class="grid_2 stmt_header">&nbsp;</div>
<div class="clear"></div>
&nbsp;
<div class="clear"></div>
<div class="grid_3 stmt_header">&nbsp;</div>
<div class="grid_6 stmt_header center"><a href="http://www.projet-orfeo.fr/">Projet ORFEO</a> &nbsp; &copy; 2015 CNRS<br/>Corpus participants: <a href="http://www.projet-rhapsodie.fr/">Rhapsodie</a>, <a href="http://www.cnrtl.fr/corpus/tcof/">TCOF</a>, ...</div>
<div class="grid_3 stmt_header right hideonprint"><a href="" target="_blank">Aide</a>&nbsp;|&nbsp;<a href="javascript:expand_contract_all ( 1 );">Tout afficher</a>&nbsp;|&nbsp;<a href="javascript:expand_contract_all ( 0 );">Tout cacher</a>&nbsp;|&nbsp;<a id="print" href="javascript:printStmt ( );">Imprimer</a></div>
<div class="clear"></div>
EOS
    end

    # Create with specified title, and optionally a javascript
    # function to call on open/close event (it will be passed a
    # boolean argument: true if panel has just been opened, false if
    # it has just been closed). Yields an output stream that the
    # content of the panel can be written into.
    # Returns the name of the panel (which is a linkable anchor).
    def panel(title, callback = nil)
      id = "panel#{counter}"

      if callback.nil?
        onclick_event = "javascript:showHide(&#39;#{id}&#39;);"
      else
        onclick_event = "javascript:#{callback}(showHide(&#39;#{id}&#39;));"
      end

      @counter += 1
      @out.puts '<div class="grid_12">'
      @out.puts "<a name=\"#{id}\"/>"
      @out.puts "<div><img src=\"#{@files_dir}/icon_help.png\" alt=\"Aide\" style=\"padding: 5px;\" title=\"Aide\" onclick=\"javascript:openWin(&#39;http://x/information.htm&#39;)\" align=\"right\"/></div>"
      @out.puts "<div class=\"sectionHeadingClosed\" id=\"#{id}_head\" onclick=\"#{onclick_event}\">#{title}</div>"
      @out.puts "<div class=\"clear\"></div>"
      @out.puts "<div id=\"#{id}_body\" style=\"display: none; position: absolute;\">"

      yield @out if block_given?

      @out.puts '<div class="space_10"></div>'
      @out.puts '</div>'
      @out.puts '</div>'
      @out.puts '<div class="clear"></div><br/>'
      id
    end

    # Output a panel with key-value information taken from the
    # specified method. (The :each method of a standard hash works
    # well here.)
    def infopanel(title, enumerator)
      panel(title) do |o|
        o.puts '<table cellpadding="0" cellspacing="0">'
        o.puts '<tbody>'
        enumerator.each do |key, val|
          if val.is_a?(Array) && val.size == 1
            val = val[0]
          end
          if val.is_a? Array
	    val_nonempty = val.reject{ |x| x.empty? }
            val_nonempty.each_with_index do |v, i|
              o.puts '<tr>'
              o.puts "<td class=\"noleftborder\" rowspan=\"#{val_nonempty.size}\">#{key}</td>" if i == 0
              o.puts "<td>#{v}</td>"
              o.puts '</tr>'
            end
          else
            o.puts '<tr>'
            o.puts "<td class=\"noleftborder\">#{key}</td>"
            o.puts "<td>#{val}</td>"
            o.puts '</tr>'
          end
        end
        o.puts '</tbody></table>'
      end
    end

    def close()
      @out.puts "<div class=\"clear\"></div><br/><br/><div class=\"grid_12 center\">Page générée le #{Time.now.strftime('%d/%m/%Y, %H h %M')}</div>"
      @out.puts '</div>'
      @out.puts '</body>'
      @out.puts '</html>'

      @out.close unless @out == $stdout
    end
  end
end
end
