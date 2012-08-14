(function() {

  $(function() {
    var blacklistReInit, changeListState, customListAdd, customListRemove, getCustomList, listInitializer, loadAvailableLists, unlock;
    loadAvailableLists = function() {
      var _this = this;
      if (localStorage["efSettings"] === "undefined" || typeof localStorage["efSettings"] === "undefined") {
        console.log("set timeout");
        chrome.extension.sendRequest({
          "action": "getAvailableLists"
        }, function(response) {
          return console.log("response", response);
        });
        return setTimeout(function() {
          return loadAvailableLists();
        }, 1000);
      } else {
        return listInitializer();
      }
    };
    changeListState = function(name, state) {
      return chrome.extension.sendRequest({
        "action": "changeListState",
        "listName": name,
        "listState": state
      });
    };
    blacklistReInit = function() {
      return chrome.extension.sendRequest({
        "action": "reInit"
      });
    };
    listInitializer = function() {
      var name, settings, xhr, xhrs, _i, _len, _ref, _results;
      settings = JSON.parse(localStorage["efSettings"]);
      xhr = new XMLHttpRequest();
      console.log("list initializer start");
      _ref = settings.myAvailableLists;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        name = _ref[_i];
        xhrs = {};
        xhr.open("GET", "lists/" + name, false);
        xhr.onreadystatechange = function() {
          var checkbox, checked, col, colsHtml, curCol, desc, descRow, descTr, detailCols, detailRow, detailTr, listObj, state, toggleBtn, url, urlColumn, urls, _j, _k, _len2, _len3, _ref2;
          if (xhr.readyState === 4) {
            listObj = JSON.parse(xhr.responseText);
            checked = "";
            state = false;
            if (settings.enabledLists) {
              state = settings.enabledLists[name];
              if (state) checked = "checked='checked'";
            }
            console.log(listObj);
            descTr = $("<tr></tr>");
            checkbox = $("<td><input type='checkbox' class='list' name='n_" + name + "' list_name='" + name + "' " + checked + "/> <label for='n_" + name + "'>" + listObj.name + "</label></td> ");
            desc = $("<td><div id='desc_" + name + "'>" + listObj.description + "</div></td>");
            descRow = descTr.append(checkbox).append(desc);
            detailTr = $("<tr></tr>");
            detailCols = [];
            curCol = 0;
            _ref2 = listObj.content;
            for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
              url = _ref2[_j];
              if (detailCols[curCol] === void 0) detailCols[curCol] = [];
              detailCols[curCol].push(url);
              curCol++;
              if (curCol === 4) curCol = 0;
            }
            colsHtml = $("<div id='urls_" + name + "' class='urls'></div>");
            toggleBtn = $("<div class='toggle_urls_btn'>\n    Show list contents\n</div>").button({
              icons: {
                primary: 'ui-icon-zoomin'
              }
            });
            colsHtml.append(toggleBtn);
            for (_k = 0, _len3 = detailCols.length; _k < _len3; _k++) {
              col = detailCols[_k];
              urlColumn = "<div class='urls_column'>" + (col.join('<br />')) + "</div>";
              colsHtml.append(urlColumn);
            }
            urls = $("<td colspan='2'></td>").append(colsHtml);
            detailRow = detailTr.append(urls);
            $('#selected_lists > tbody:last').append(descRow);
            return $('#selected_lists > tbody:last').append(detailRow);
          }
        };
        _results.push(xhr.send());
      }
      return _results;
    };
    getCustomList = function(gclCallback) {
      return chrome.extension.sendRequest({
        "action": "getLists"
      }, function(lists) {
        var destination, item, listContents, removeBtn, type, _i, _len, _results;
        _results = [];
        for (type in lists) {
          listContents = lists[type];
          console.log(type, listContents);
          destination = $("#my_" + type + "_inner");
          destination.children().remove();
          for (_i = 0, _len = listContents.length; _i < _len; _i++) {
            item = listContents[_i];
            removeBtn = $("<a class='remove_" + (type.replace("s", "")) + "_item remove_item' href='#' item='" + item + "'>\n  " + item + "\n</a>").wrap('<div class="btn_wrapper"></div>');
            destination.append(removeBtn);
          }
          $(".remove_item").button({
            icons: {
              secondary: "ui-icon-circle-close"
            }
          });
          if (gclCallback) {
            _results.push(gclCallback());
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      });
    };
    customListAdd = function(type, entry) {
      return chrome.extension.sendRequest({
        "action": "addToBlacklist",
        "type": type,
        "entry": entry
      }, function(response) {
        getCustomList();
        return blacklistReInit();
      });
    };
    customListRemove = function(type, entry) {
      return chrome.extension.sendRequest({
        "action": "rmFromBlacklist",
        "type": type,
        "entry": entry
      }, function(response) {
        getCustomList();
        return blacklistReInit();
      });
    };
    unlock = function() {
      loadAvailableLists();
      return getCustomList(function() {
        $("#body_wrapper").show();
        return $("#lockdown").hide();
      });
    };
    console.log("password length", localStorage["password"].length);
    if (localStorage["password"].length === 0) {
      console.log("unlocking");
      unlock();
    }
    $('#nav_tabs').tabs();
    $('.remove_url_item').live('click', function() {
      customListRemove("url", $(this).attr("item"));
      return $(this).remove();
    });
    $(".list").live("change", function() {
      var state;
      state = $(this).is(':checked');
      return changeListState($(this).attr('list_name'), state);
    });
    $('.remove_keyword_item').live('click', function() {
      customListRemove("keyword", $(this).attr("item"));
      return $(this).remove();
    });
    $('#add_new_url').click(function() {
      if ($('#new_url_add').val().length === 0) {
        alert("Url field is emptry");
        return false;
      }
      customListAdd("url", $('#new_url_add').val());
      return getCustomList();
    });
    $('#add_new_keyword').click(function() {
      if ($('#new_keyword_add').val().length === 0) {
        alert("Keyword field is emptry");
        return false;
      }
      customListAdd("keyword", $('#new_keyword_add').val());
      return getCustomList();
    });
    $('.toggle_urls_btn').live('click', function() {
      var urlColumns;
      urlColumns = $(this).parent().children(".urls_column");
      console.log(urlColumns);
      if (!urlColumns.is(":visible")) {
        urlColumns.slideDown();
        $(".ui-icon", this).removeClass("ui-icon-zoomin").addClass("ui-icon-zoomout");
        $(".ui-button-text", this).text("Hide list contents");
      } else {
        urlColumns.slideUp();
        $(".ui-icon", this).removeClass("ui-icon-zoomout").addClass("ui-icon-zoomin");
        $(".ui-button-text", this).text("Show list contents");
      }
      return false;
    });
    $('#lockdown_password').keyup(function() {
      var hashedPass;
      hashedPass = CryptoJS.PBKDF2($(this).val(), localStorage["obfuKey"], {
        keySize: 256 / 32,
        iterations: 10
      }).toString();
      if (hashedPass === localStorage["password"]) {
        unlock();
        return $(this).remove();
      }
    });
    return $('input[type="submit"]').button();
  });

}).call(this);
