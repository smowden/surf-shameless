(function() {

  $(function() {
    var blacklistReInit, changeListState, customListAdd, customListRemove, getCustomList, listInitializer, loadAvailableLists;
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
            toggleBtn = $("<div class='toggle_urls_btn'>\n  <a href='#'>\n    <img src='images/show.png' class='toggle_urls_icon' />\n    <span class='toggle_urls_caption'>Show list contents</span>\n  </a>\n</div>");
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
    getCustomList = function(type) {
      var customListName, destination, item, td, _i, _len, _ref;
      console.log("get custom list called");
      console.log(type);
      if (type === "url") {
        customListName = "myCustomUrlList";
        destination = $("#my_urls > tbody:last");
      } else if (type === "keyword") {
        customListName = "myCustomKeywordList";
        destination = $("#my_keywords > tbody:last");
      }
      if (localStorage[customListName] !== "undefined" && typeof localStorage[customListName] !== "undefined" && localStorage[customListName] !== void 0) {
        _ref = JSON.parse(localStorage[customListName]);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          td = $("<td>\n  <span class='url'>" + item + "</span>\n  <a class='remove_" + type + "_item' href='javascript:void(0)'>\n    <img src='images/delete.png' />\n  </a>\n</td>");
          destination.append(td);
        }
      }
      return;
    };
    customListAdd = function(string, type) {
      var customListName, myCustomList;
      if (type === "url") {
        customListName = "myCustomUrlList";
      } else if (type === "keyword") {
        customListName = "myCustomKeywordList";
      }
      if (localStorage[customListName] === "undefined" || typeof localStorage[customListName] === "undefined" || localStorage[customListName] === void 0) {
        myCustomList = [];
      } else {
        myCustomList = JSON.parse(localStorage[customListName]);
      }
      myCustomList.push(string.replace("http://", "").replace("www.", ""));
      localStorage[customListName] = JSON.stringify(myCustomList);
      return blacklistReInit();
    };
    customListRemove = function(string, type) {
      var customListName, listIndex, myCustomList, removeItem;
      if (type === "url") {
        customListName = "myCustomUrlList";
      } else if (type === "keyword") {
        customListName = "myCustomKeywordList";
      }
      myCustomList = JSON.parse(localStorage[customListName]);
      if (myCustomList) {
        if (type === "url") {
          removeItem = string.replace("http://", "").replace("www.", "");
        }
        if (type === "keyword") removeItem = string;
        listIndex = myCustomList.indexOf(removeItem);
        myCustomList.splice(listIndex, 1);
        if (myCustomList.length > 0) {
          localStorage[customListName] = JSON.stringify(myCustomList);
        } else {
          localStorage[customListName] = void 0;
        }
      }
      return blacklistReInit();
    };
    $('#nav_tabs').tabs();
    $('.remove_url_item').live('click', function() {
      customListRemove($(this).text(), "url");
      return $(this).parent().remove();
    });
    $(".list").live("change", function() {
      var state;
      state = $(this).is(':checked');
      return changeListState($(this).attr('list_name'), state);
    });
    $('.remove_keyword_item').live('click', function() {
      customListRemove($(this).text(), "keyword");
      return $(this).parent().remove();
    });
    $('#add_new_url').click(function() {
      if ($('#new_url_add').val().length === 0) {
        alert("Url field is emptry");
        return false;
      }
      customListAdd($('#new_url_add').val(), "url");
      $("#my_urls tbody").html("");
      return getCustomList("url");
    });
    $('#add_new_keyword').click(function() {
      if ($('#new_keyword_add').val().length === 0) {
        alert("Keyword field is emptry");
        return false;
      }
      customListAdd($('#new_keyword_add').val(), "keyword");
      $("#my_keywords tbody").html("");
      return getCustomList("keyword");
    });
    $('.toggle_urls_btn a').toggle(function() {
      $(this).parent().parent().children(".urls_column").slideDown();
      $(".toggle_urls_icon", this).attr("src", "images/hide.png");
      return $(".toggle_urls_caption", this).text("Hide list contents");
    }, function() {
      $(this).parent().parent().children(".urls_column").slideUp();
      $(".toggle_urls_icon", this).attr("src", "images/show.png");
      return $(".toggle_urls_caption", this).text("Show list contents");
    });
    return $('#lockdown_password').keyup(function() {
      console.log($(this).val());
      if ($(this).val() === "password") {
        loadAvailableLists();
        getCustomList("url");
        getCustomList("keyword");
        $("#body_wrapper").show();
        return $("#lockdown").hide();
      }
    });
  });

}).call(this);
