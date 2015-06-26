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
