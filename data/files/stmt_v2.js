window.addEventListener('load', checkParams);

function sendEvent(el, evType) {
  if (el.fireEvent) {
    el.fireEvent('on'+evType);
  } else {
    var evObj = document.createEvent('Events');
    evObj.initEvent(evType, true, false);
    el.dispatchEvent(evObj);
  }
}

function sendClickEvent(el) {
  sendEvent(el, 'click');
}

function checkParams() {
  var query = getQueryParams(document.location.search);
  if ("from" in query && "to" in query) {
    highlightWords(parseInt(query.from), parseInt(query.to));
  } else if ("tree" in query) {
    jumpToTree(parseInt(query.tree));
  }
}

function jumpToTree(word) {
  // Open syntax tree panel.
  var tags = document.getElementsByTagName('div');
  for (var i=0; i < tags.length; i++) {
    if (tags[i].textContent.match(/^Arbr/)) {
      sendClickEvent(tags[i]);
    }
  }

  // Jump to tree.
  var treeNum = word_map[word][1];
  setTimeout(function() { document.getElementById('sentencediv'+treeNum).scrollIntoView(); }, 200);
}

function highlightWords(w_from, w_to) {
  // Open the text panel.
  var panel = null;
  var tags = document.getElementsByTagName('div');
  for (var i=0; i < tags.length; i++) {
    if (tags[i].textContent.match(/^Texte/)) {
      panel = tags[i];
      sendClickEvent(tags[i]);
    }
  }

  // Find words to highlight.
  for (var i=w_from; i<=w_to; i++) {
    var word = document.getElementById("tok"+word_map[i][0]);
    word.classList.add("highlight");
  }
}

function getQueryParams(qs) {
    qs = qs.split('+').join(' ');
    var params = {}, tokens;
    var re = /[?&]?([^=]+)=([^&]*)/g;

    while (tokens = re.exec(qs)) {
        params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
    }

    return params;
}

function printStmt () {
        window.print ( );
}

function showTable(bodyDiv) {
    if (bodyDiv != null) {
        bodyDiv.style.display = 'block';
        bodyDiv.style.position = '';
    }
}

function hideTable(bodyDiv) {
    if (bodyDiv != null) {
        bodyDiv.style.display = 'none';
        bodyDiv.style.position = 'absolute';
    }
}

function openSection(headingDiv) {
    if (headingDiv != null) {
        headingDiv.className = "sectionHeadingOpened";
    }
}

function closeSection(headingDiv) {
    if (headingDiv != null) {
        headingDiv.className = "sectionHeadingClosed";
    }
}

function showPanel(divId) {
    openSection(panelHead(divId));
    showTable(panelBody(divId));
}

function hidePanel(divId) {
    closeSection(panelHead(divId));
    hideTable(panelBody(divId));
}

function flashPanel(divId) {
    if (panelHead(divId).className == "sectionHeadingOpened") {
        panelHead(divId).className = "sectionHeadingHighlighted";
    } else {
        panelHead(divId).className = "sectionHeadingOpened";
    }
}

function showFlashPanel(divId) {
    showTable(panelBody(divId));
    panelHead(divId).className = "sectionHeadingHighlighted";
    for (var i=1; i < 10; i++) {
        setTimeout(function() { flashPanel(divId); }, 360*i);
    }
}

function panelHead(divId) {
    return document.getElementById(divId + "_head");
}
function panelBody(divId) {
    return document.getElementById(divId + "_body");
}

function showHide(divId) {
    if (panelBody(divId).style.display == "none") {
        showPanel(divId);
        return true;
    } else {
        hidePanel(divId);
        return false;
    }
}

function expand_contract_all (showOrHide) {
  var tags = document.getElementsByTagName('div');
  for (var i=0; i < tags.length; i++) {
    if (tags[i].id.indexOf("_head") >= 0) {
      if ((showOrHide == 1 && tags[i].className == "sectionHeadingClosed") ||
      (showOrHide == 0 && tags[i].className == "sectionHeadingOpened"))
      sendClickEvent(tags[i]);
    }
  }
}

function openWin (url) {
    newWindow = window.open(url, 'popUp', 'height=400, width=650, scrollbars=yes');
    if (window.focus) {
        newWindow.focus();
    }
    return false;
}
