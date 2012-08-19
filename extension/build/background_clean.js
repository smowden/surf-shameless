(function() {
  var ContextMenu, InterceptMode, MyBlacklist, PrivateBookmarks, REMOTE_SERVER_URL, WipeMode, contextMenu, emptyList, interceptMode, myBlacklist, opMode, privateBookmarks, reloadAll, wipeMode,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  REMOTE_SERVER_URL = "http://shameless.codesuela.com/";

  MyBlacklist = (function() {
    var customBlacklist, joinedBlacklist, settings, totalEnabled;

    MyBlacklist.prototype.readyState = false;

    totalEnabled = 0;

    customBlacklist = void 0;

    joinedBlacklist = void 0;

    settings = {
      myAvailableLists: void 0,
      enabledLists: {},
      lastListUpdate: void 0
    };

    function MyBlacklist() {
      this.loadList = __bind(this.loadList, this);
      this.loadEnabledLists = __bind(this.loadEnabledLists, this);
      this.getAvailableLists = __bind(this.getAvailableLists, this);      this.init();
    }

    MyBlacklist.prototype.init = function() {
      /*
          as the name init suggestst this method (re)initializes the blacklist
          this means it populates the blacklistKeywords and blacklistUrls with the user defined keywords and urls
          and then proceeds to join them with the lists that the user enabled
          once initialization is done readyState is true
      */
      var storedSettings,
        _this = this;
      console.log("init...");
      storedSettings = this.loadSettings();
      if (storedSettings !== void 0) settings = storedSettings;
      console.log("settings", settings);
      customBlacklist = this.getCustomLists();
      joinedBlacklist = jQuery.extend(true, {}, customBlacklist);
      console.log("custom blacklist", customBlacklist);
      this.readyState = false;
      if (settings.myAvailableLists === void 0) {
        this.getAvailableLists();
        return setTimeout(function() {
          return _this.init();
        }, 100);
      } else {
        console.log("enabling lists...");
        return this.loadEnabledLists();
      }
    };

    MyBlacklist.prototype.getCustomLists = function() {
      var lists, possibleBlacklist;
      lists = {
        keywords: [],
        urls: []
      };
      possibleBlacklist = CryptoJS.AES.decrypt(localStorage["customBlacklist"], localStorage["obfuKey"]).toString(CryptoJS.enc.Utf8);
      if (possibleBlacklist.length > 0) {
        try {
          lists = JSON.parse(possibleBlacklist);
        } catch (e) {
          alert(e);
        }
      }
      return lists;
    };

    MyBlacklist.prototype.loadSettings = function() {
      var storedSettings;
      if (localStorage["efSettings"] !== void 0 && localStorage["efSettings"] !== "undefined") {
        storedSettings = JSON.parse(localStorage["efSettings"]);
        return storedSettings;
      }
    };

    MyBlacklist.prototype.saveSettings = function() {
      return localStorage["efSettings"] = JSON.stringify(settings);
    };

    MyBlacklist.prototype.storeObfuscatedBlacklist = function() {
      console.log("storing custom blacklist", customBlacklist);
      return localStorage["customBlacklist"] = CryptoJS.AES.encrypt(JSON.stringify(customBlacklist), localStorage["obfuKey"]).toString();
    };

    MyBlacklist.prototype.addToBlacklist = function(type, entry) {
      var hostname, parser;
      console.log("add to blacklist called with", type, entry);
      entry = entry.toLowerCase();
      if (type === "url") {
        if (entry.indexOf("http://") === -1 && entry.indexOf("https://") === -1) {
          entry = "http://" + entry;
        }
        parser = document.createElement('a');
        parser.href = entry;
        hostname = parser.hostname.replace("www.", "");
        if (customBlacklist.urls.indexOf(hostname) === -1) {
          customBlacklist.urls.push(hostname);
          this.storeObfuscatedBlacklist();
          if (JSON.parse(localStorage["allowRemote"])) {
            $.post("" + REMOTE_SERVER_URL + "submit/", {
              url: hostname
            });
          }
        }
        return hostname;
      } else if (type === "keyword") {
        if (customBlacklist.keywords.indexOf(entry) === -1) {
          customBlacklist.keywords.push(entry);
          return this.storeObfuscatedBlacklist();
        }
      }
    };

    MyBlacklist.prototype.removeFromBlacklist = function(type, entry) {
      var listIndex;
      console.log("removeFromBlacklist", type, entry);
      entry = entry.toLowerCase();
      listIndex = customBlacklist[type + "s"].indexOf(entry);
      if (listIndex >= 0) customBlacklist[type + "s"].splice(listIndex, 1);
      return this.storeObfuscatedBlacklist();
    };

    MyBlacklist.prototype.getBlacklist = function() {
      return joinedBlacklist;
    };

    MyBlacklist.prototype.getCustomList = function() {
      return customBlacklist;
    };

    MyBlacklist.prototype.isBlacklisted = function(string, type) {
      var lookupDir, s, _i, _len;
      string = string.toLowerCase();
      if (type === "url") lookupDir = joinedBlacklist.urls;
      if (type === "keyword") lookupDir = joinedBlacklist.keywords;
      for (_i = 0, _len = lookupDir.length; _i < _len; _i++) {
        s = lookupDir[_i];
        if (type === "url") {
          if (string.indexOf("http://www." + s) >= 0 || string.indexOf("http://" + s) >= 0 || string.indexOf("https://" + s) >= 0) {
            return true;
          }
        } else if (type === "keyword") {
          if (string.indexOf(s) >= 0) return true;
        }
      }
      return false;
    };

    MyBlacklist.prototype.getAvailableLists = function(availableLists, refresh) {
      if ((settings.myAvailableLists === void 0 && !availableLists) || refresh) {
        this.getLocalFile("lists/_available", this.getAvailableLists);
        return;
      } else {
        settings.myAvailableLists = availableLists;
        return this.saveSettings();
      }
    };

    MyBlacklist.prototype.loadEnabledLists = function() {
      var enabledListsIndex, listName, totalDisabled, _i, _len, _ref;
      if (settings.enabledLists) {
        console.log("enabledLists check");
        if (settings.myAvailableLists) {
          console.log("myAvailableLists check");
          totalEnabled = 0;
          console.log("available lists", settings.myAvailableLists);
          console.log("enabled lists", settings.enabledLists);
          enabledListsIndex = 0;
          totalDisabled = 0;
          _ref = settings.myAvailableLists;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            listName = _ref[_i];
            if (settings.enabledLists[listName]) {
              enabledListsIndex++;
              totalEnabled++;
              console.log("loading list " + listName);
              this.loadList(void 0, listName, enabledListsIndex);
            } else {
              totalDisabled++;
            }
          }
          if (totalEnabled === 0 && totalDisabled > 0) this.readyState = true;
          console.log("end of list enabler");
          return true;
        }
      }
      return this.readyState = true;
    };

    MyBlacklist.prototype.loadList = function(listObject, name, index) {
      if (!listObject) {
        return this.getLocalFile("lists/" + name, this.loadList, name, index);
      } else {
        if (listObject.type === "urls") {
          joinedBlacklist.urls = joinedBlacklist.urls.concat(listObject.content);
        } else if (listObject.type === "keywords") {
          joinedBlacklist.keywords = joinedBlacklist.keywords.concat(listObject.content);
        }
        console.log("joined blacklist", joinedBlacklist);
        if (index === totalEnabled) return this.readyState = true;
      }
    };

    MyBlacklist.prototype.setListState = function(name, state) {
      if (typeof state === "boolean") settings.enabledLists[name] = state;
      return this.saveSettings();
    };

    MyBlacklist.prototype.getLocalFile = function(path, callback, var1, var2) {
      var xhr,
        _this = this;
      xhr = new XMLHttpRequest();
      xhr.open("GET", path, true);
      xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
          return callback(JSON.parse(xhr.responseText), var1, var2);
        }
      };
      return xhr.send();
    };

    return MyBlacklist;

  })();

  WipeMode = (function() {
    var badRedirects, firstBadTabTime, openTabs;

    openTabs = [];

    badRedirects = [];

    firstBadTabTime = void 0;

    function WipeMode(myBlacklist) {
      this.myBlacklist = myBlacklist;
      this.tabAdded = __bind(this.tabAdded, this);
      this.init();
    }

    WipeMode.prototype.init = function() {
      var _this = this;
      console.log("waiting for readyness");
      if (!myBlacklist.readyState) {
        return setTimeout(function() {
          return _this.init();
        }, 100);
      } else {
        return this.wipeHistory(void 0, true);
      }
    };

    /*
      tabAdded, tabClosed and onRedirect keep track of whether blacklisted urls are currently open
      or whether redirects to blacklisted sites occured
      once all tabs with blacklisted urls are closed the history will be cleaned out
    */

    WipeMode.prototype.tabAdded = function(tabId, changeInfo, tab) {
      var currentUrl;
      currentUrl = tab.url;
      if (changeInfo.url) currentUrl = changeInfo.url;
      if ((myBlacklist.isBlacklisted(currentUrl, "url") || myBlacklist.isBlacklisted(tab.title, "keyword")) && openTabs.indexOf(tabId) === -1) {
        if (!firstBadTabTime) firstBadTabTime = new Date().getTime() - 10000;
        openTabs.push(tabId);
        return console.log(openTabs);
      } else if (!(myBlacklist.isBlacklisted(currentUrl, "url") || myBlacklist.isBlacklisted(tab.title, "keyword")) && openTabs.indexOf(tabId) >= 0) {
        this.tabClosed(tabId);
        return;
      }
    };

    WipeMode.prototype.tabClosed = function(tabId) {
      var formerBadTab;
      formerBadTab = openTabs.indexOf(tabId);
      if (formerBadTab >= 0) {
        openTabs.splice(formerBadTab, 1);
        if (openTabs.length === 0) {
          this.wipeHistory(firstBadTabTime);
          return firstBadTabTime = void 0;
        }
      }
    };

    WipeMode.prototype.onRedirect = function(details) {
      if (myBlacklist.isBlacklisted(details.redirectUrl, "url") && badRedirects.indexOf(details.redirectUrl)) {
        badRedirects.push(details.url);
        console.log(badRedirects);
      }
      return;
    };

    WipeMode.prototype.purgeBadUrl = function(url) {
      /*
          if we just delete the url the item will disappear from the history but a www. prefixed
          version will still show up in the omnibox so and the other way round
          therefore we need to make sure that both types of urls are deleted
      */
      var httpsUrl;
      if (url.indexOf("http") === -1) {
        /*
              if the url comes from a list and WipeMode is initialized it will only
              consist of domain.tld so we need to prefix it with the proper possible schemes
              otherwise it won't be deleted
        */
        url = "http://" + url;
        httpsUrl = "https://" + url;
      }
      chrome.history.deleteUrl({
        url: url
      });
      if (httpsUrl) {
        chrome.history.deleteUrl({
          url: httpsUrl
        });
      }
      if (url.indexOf("www") >= 0) {
        chrome.history.deleteUrl({
          url: url.replace("http://www.", "http://")
        });
        return console.log("purged " + (url.replace("http://www.", "http://")));
      } else {
        chrome.history.deleteUrl({
          url: url.replace("http://", "http://www.")
        });
        return console.log("purged " + (url.replace("http://", "http://www.")));
      }
    };

    WipeMode.prototype.wipeHistory = function(startTime, doFullClean) {
      var endTime, maxResults, site, _i, _len, _ref,
        _this = this;
      if (!startTime) startTime = new Date(2000, 0, 1, 0).getTime();
      endTime = new Date().getTime();
      if (doFullClean) {
        console.log(myBlacklist.getBlacklist());
        _ref = myBlacklist.getBlacklist().urls;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          site = _ref[_i];
          this.purgeBadUrl(site);
        }
      }
      maxResults = 1000000000;
      chrome.history.search({
        text: "",
        startTime: startTime,
        endTime: endTime,
        maxResults: maxResults
      }, function(historyItems) {
        var deleteCount, hItem, nastyRedirect, _j, _k, _len2, _len3;
        deleteCount = 0;
        for (_j = 0, _len2 = historyItems.length; _j < _len2; _j++) {
          hItem = historyItems[_j];
          if (myBlacklist.isBlacklisted(hItem.url, "url") || myBlacklist.isBlacklisted(hItem.title, "keyword")) {
            _this.purgeBadUrl(hItem.url);
            deleteCount++;
          }
          if (hItem.url.indexOf(".google.") >= 0) {
            if (myBlacklist.isBlacklisted(hItem.url, "keyword")) {
              _this.purgeBadUrl(hItem.url);
              deleteCount++;
            }
          }
        }
        for (_k = 0, _len3 = badRedirects.length; _k < _len3; _k++) {
          nastyRedirect = badRedirects[_k];
          chrome.history.deleteUrl({
            url: nastyRedirect
          });
          deleteCount++;
        }
        localStorage["popup_lastCleanupTime"] = JSON.stringify(new Date);
        localStorage["popup_cleanupUrlCounter"] = deleteCount;
        localStorage["totalRemoved"] = JSON.parse(localStorage["totalRemoved"]) + deleteCount;
        return;
      });
      return;
    };

    WipeMode.prototype.installListeners = function() {
      chrome.tabs.onUpdated.addListener(this.tabAdded);
      chrome.tabs.onRemoved.addListener(function(tabId, removeInfo) {
        return this.tabClosed(tabId);
      });
      return chrome.webRequest.onBeforeRedirect.addListener(this.onRedirect, {
        urls: ["http://*/*"],
        types: ["main_frame"]
      });
    };

    return WipeMode;

  })();

  InterceptMode = (function() {

    function InterceptMode(myBlacklist) {
      this.myBlacklist = myBlacklist;
      this.init = __bind(this.init, this);
      this.init();
    }

    InterceptMode.prototype.init = function() {
      var filter,
        _this = this;
      if (!myBlacklist.readyState) {
        return setTimeout(function() {
          return _this.init();
        }, 100);
      } else {
        if (chrome.webRequest.onBeforeRequest.hasListener()) {
          chrome.webRequest.onBeforeRequest.removeListener();
        }
        filter = this.buildFilter();
        if (filter.length > 0) {
          return chrome.webRequest.onBeforeRequest.addListener(this.intercept, {
            urls: filter,
            types: ["main_frame"]
          }, ["blocking"]);
        }
      }
    };

    InterceptMode.prototype.intercept = function(details) {
      localStorage["totalRemoved"] = JSON.parse(localStorage["totalRemoved"]) + 1;
      chrome.windows.create({
        "url": details.url,
        "incognito": true
      }, function() {
        chrome.tabs.remove(details.tabId);
        return console.log("spawned new window");
      });
      return {
        "cancel": true
      };
    };

    InterceptMode.prototype.buildFilter = function() {
      var blacklist, tmpFilter, url, _i, _len, _ref;
      tmpFilter = [];
      blacklist = this.myBlacklist.getBlacklist();
      _ref = blacklist["urls"];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        url = _ref[_i];
        tmpFilter.push("*://*." + url + "/*");
        tmpFilter.push("*://" + url + "/*");
      }
      console.log("tmp filter:", tmpFilter);
      return tmpFilter;
    };

    return InterceptMode;

  })();

  PrivateBookmarks = (function() {
    var bookmarks;

    bookmarks = void 0;

    function PrivateBookmarks() {
      this.loadBookmarks();
    }

    PrivateBookmarks.prototype.loadBookmarks = function() {
      var possibleBookmarks;
      possibleBookmarks = CryptoJS.AES.decrypt(localStorage["privateBookmarks"], localStorage["obfuKey"], "bookmarks").toString(CryptoJS.enc.Utf8);
      if (possibleBookmarks.length > 0) {
        try {
          bookmarks = JSON.parse(possibleBookmarks);
        } catch (e) {
          alert(e);
        }
      }
      return bookmarks;
    };

    PrivateBookmarks.prototype.saveBookmarks = function() {
      return localStorage["privateBookmarks"] = CryptoJS.AES.encrypt(JSON.stringify(bookmarks), localStorage["obfuKey"], "bookmarks").toString();
    };

    PrivateBookmarks.prototype.getBookmarks = function() {
      return bookmarks;
    };

    PrivateBookmarks.prototype.addBookmark = function(title, url) {
      var bookmark;
      bookmark = {
        title: title,
        url: url
      };
      bookmarks.push(bookmark);
      console.log("saving bookmark", bookmark);
      console.log("private bookmarks", bookmarks);
      return this.saveBookmarks();
    };

    PrivateBookmarks.prototype.removeBookmark = function(url) {
      var bookmark, index, _len;
      for (index = 0, _len = bookmarks.length; index < _len; index++) {
        bookmark = bookmarks[index];
        if (bookmark.url === url) {
          bookmarks.splice(index, 1);
          this.saveBookmarks();
          return true;
        }
      }
      return false;
    };

    PrivateBookmarks.prototype.injectDialog = function(tab) {
      var dialogHtml, injectScript;
      dialogHtml = ("  <div id=\"bookmark_dialog\" title=\"Add a bookmark\">\n    <label for=\"bookmark_title\">Name</label><br/>\n    <input type=\"text\" style=\"width:250px;\" id=\"ef_bookmark_title\" value=\"" + tab.title + "\"/>\n</div>").replace(/(\r\n|\n|\r)/gm, "");
      injectScript = "$(function(){\n  $(\"body\").append($('" + dialogHtml + "'));\n  $('#bookmark_dialog').dialog({\n    autoOpen: true,\n    width: 300,\n    buttons: {\n      \"Save\": function() {\n         chrome.extension.sendRequest({'action': 'addBookmark', 'title': $('#ef_bookmark_title').val(), 'url': '" + tab.url + "'});\n         $(this).dialog(\"close\");\n       },\n      \"Cancel\": function() {\n        $(this).dialog(\"close\");\n      }\n    },\n    modal: true\n  });\n})";
      return chrome.tabs.executeScript(tab.id, {
        "file": "js/jquery.min.js"
      }, function() {
        return chrome.tabs.executeScript(tab.id, {
          "file": "js/jquery-ui-1.8.21.custom.min.js"
        }, function() {
          return chrome.tabs.insertCSS(tab.id, {
            "file": "css/Aristo.css"
          }, function() {
            return chrome.tabs.executeScript(tab.id, {
              "code": injectScript
            });
          });
        });
      });
    };

    return PrivateBookmarks;

  })();

  ContextMenu = (function() {

    function ContextMenu(myBlacklist, privateBookmarks) {
      var child1, child2, parent;
      this.myBlacklist = myBlacklist;
      this.privateBookmarks = privateBookmarks;
      parent = chrome.contextMenus.create({
        "title": "(surf) shameless"
      });
      child1 = chrome.contextMenus.create({
        "title": "Don't log my visits to this site",
        "parentId": parent,
        "onclick": this.contextMenuAddSite
      });
      child2 = chrome.contextMenus.create({
        "title": "Make this a private bookmark",
        "parentId": parent,
        "onclick": this.addBookmark
      });
    }

    ContextMenu.prototype.contextMenuAddSite = function(info, tab) {
      var hostname;
      hostname = myBlacklist.addToBlacklist("url", tab.url);
      return alert("Added " + hostname + " to your blacklist");
    };

    ContextMenu.prototype.addBookmark = function(info, tab) {
      return privateBookmarks.injectDialog(tab);
    };

    return ContextMenu;

  })();

  if (localStorage["firstRun"] === void 0) {
    localStorage["obfuKey"] = CryptoJS.PBKDF2(Math.random().toString(36).substring(2), "efilter", {
      keySize: 256 / 32,
      iterations: 100
    }).toString();
    localStorage["firstRun"] = false;
    localStorage["opMode"] = 1;
    emptyList = {
      keywords: [],
      urls: []
    };
    localStorage["customBlacklist"] = CryptoJS.AES.encrypt(JSON.stringify(emptyList), localStorage["obfuKey"]).toString();
    localStorage["privateBookmarks"] = CryptoJS.AES.encrypt(JSON.stringify([]), localStorage["obfuKey"], "bookmarks").toString();
    localStorage["totalRemoved"] = 0;
  }

  if (localStorage["setupFinished"] === void 0) {
    chrome.tabs.create({
      url: "first_run.html"
    });
  }

  opMode = JSON.parse(localStorage["opMode"]);

  myBlacklist = new MyBlacklist();

  wipeMode = new WipeMode(myBlacklist);

  privateBookmarks = new PrivateBookmarks();

  contextMenu = new ContextMenu(myBlacklist, privateBookmarks);

  if (opMode === 0) {
    interceptMode = new InterceptMode(myBlacklist);
  } else if (opMode === 1) {
    wipeMode.installListeners();
  }

  reloadAll = function() {
    myBlacklist.init();
    wipeMode.wipeHistory(void 0, true);
    if (opMode === 0) return interceptMode.init();
  };

  chrome.extension.onRequest.addListener(function(request, sender, sendResponse) {
    console.log("got request", request);
    if (request.action === "getAvailableLists") {
      myBlacklist.getAvailableLists(void 0, true);
    } else if (request.action === "changeListState") {
      myBlacklist.setListState(request.listName, request.listState);
      reloadAll();
    } else if (request.action === "reInit") {
      reloadAll();
    } else if (request.action === "addToBlacklist") {
      myBlacklist.addToBlacklist(request.type, request.entry);
      sendResponse(myBlacklist.getCustomList());
    } else if (request.action === "rmFromBlacklist") {
      myBlacklist.removeFromBlacklist(request.type, request.entry);
      sendResponse(myBlacklist.getCustomList());
    } else if (request.action === "getLists") {
      sendResponse(myBlacklist.getCustomList());
    } else if (request.action === "addBookmark") {
      privateBookmarks.addBookmark(request.title, request.url);
    } else if (request.action === "rmBookmark") {
      privateBookmarks.removeBookmark(request.url);
    } else if (request.action === "getBookmarks") {
      sendResponse(privateBookmarks.getBookmarks());
    }
    return console.log(request);
  });

}).call(this);
