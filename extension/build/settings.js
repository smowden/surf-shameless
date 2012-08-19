(function() {

  $(function() {
    var blacklistReInit, changeListState, customListAdd, customListRemove, getCustomList, getPrivateBookmarks, listInitializer, loadAvailableLists, unlock;
    loadAvailableLists = function() {
      var _this = this;
      if (localStorage["efSettings"] === "undefined" || typeof localStorage["efSettings"] === "undefined") {
        chrome.extension.sendRequest({
          "action": "getAvailableLists"
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
    getPrivateBookmarks = function() {
      return chrome.extension.sendRequest({
        "action": "getBookmarks"
      }, function(bookmarks) {
        var bookmark, bookmarkRepr, _i, _len;
        $("#private_bookmarks").children().remove();
        if (bookmarks.length === 0) $("#no_bookmarks_warning").show();
        for (_i = 0, _len = bookmarks.length; _i < _len; _i++) {
          bookmark = bookmarks[_i];
          bookmarkRepr = "<li class=\"bookmark\">\n<a href=\"" + bookmark.url + "\" target=\"_blank\">" + bookmark.title + "</a>\n\n<div class=\"delete_bookmark_icon ui-state-default ui-corner-all\">\n             <span class=\"ui-icon ui-icon-closethick\"></span>\n\n</div>\n</li> ";
          $("#private_bookmarks").append(bookmarkRepr);
        }
        return $(".delete_bookmark_icon").hover(function() {
          return $(this).addClass('ui-state-hover');
        }, function() {
          return $(this).removeClass('ui-state-hover');
        });
      });
    };
    getCustomList = function(gclCallback) {
      return chrome.extension.sendRequest({
        "action": "getLists"
      }, function(lists) {
        var destination, item, listContents, removeBtn, type, _i, _len, _results;
        _results = [];
        for (type in lists) {
          listContents = lists[type];
          destination = $("#my_" + type + "_inner");
          destination.children().remove();
          for (_i = 0, _len = listContents.length; _i < _len; _i++) {
            item = listContents[_i];
            removeBtn = $("<a class='remove_" + (type.replace("s", "")) + "_item remove_item' href='#' item='" + item + "'>\n  " + item + "\n</a>");
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
        getPrivateBookmarks();
        $("#e_total_count").text(localStorage["totalRemoved"]);
        $("#body_wrapper").show();
        $("#lockdown").hide();
        if (localStorage["opMode"] === "1") {
          $("#op_mode_retroactive").attr("checked", "checked");
        } else {
          $("#op_mode_preventive").attr("checked", "checked");
        }
        if (JSON.parse(localStorage["allowRemote"]) === true) {
          return $("#ef_allow_remote").attr("checked", "checked");
        }
      });
    };
    if (localStorage["password"].length === 0) {
      $("#no_password_warning").show();
      unlock();
    }
    $('#nav_tabs').tabs();
    $('.remove_url_item').live('click', function() {
      customListRemove("url", $(this).attr("item"));
      return $(this).remove();
    });
    $('.delete_bookmark_icon').live("click", function() {
      chrome.extension.sendRequest({
        "action": "rmBookmark",
        "url": $("a", $(this).parent()).attr("href")
      });
      return $(this).parent().remove();
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
        alert("Url field is empty");
        return false;
      }
      customListAdd("url", $('#new_url_add').val());
      return getCustomList();
    });
    $('#add_new_keyword').click(function() {
      if ($('#new_keyword_add').val().length === 0) {
        alert("Keyword field is empty");
        return false;
      }
      customListAdd("keyword", $('#new_keyword_add').val());
      return getCustomList();
    });
    $('.toggle_urls_btn').live('click', function() {
      var urlColumns;
      urlColumns = $(this).parent().children(".urls_column");
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
    $('#show_hint').click(function() {
      if (localStorage["passwordHint"].length > 0) {
        return alert(localStorage["passwordHint"]);
      } else {
        return alert("there is no hint");
      }
    });
    $("#ef_allow_remote").change(function() {
      return localStorage["allowRemote"] = JSON.parse($("#ef_allow_remote").is(":checked"));
    });
    $("input[type='radio']").change(function() {
      var opMode;
      opMode = $("input[type='radio']:checked").val();
      if (opMode !== void 0) return localStorage["opMode"] = parseInt(opMode, 10);
    });
    $("#update_password").click(function() {
      localStorage["password"] = CryptoJS.PBKDF2($("#new_password").val(), localStorage["obfuKey"], {
        keySize: 256 / 32,
        iterations: 10
      }).toString();
      return alert("Password changed");
    });
    return $('input[type="submit"]').button();
  });

}).call(this);
