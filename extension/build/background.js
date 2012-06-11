// Generated by CoffeeScript 1.3.3
(function() {
  var Mode, PrivateStash, WipeMode, benchmark, cleanupHistory, face_protect, intercept_sites, isBlacklistedUrl;

  intercept_sites = ["youjizz.com", "spankwire.com", "webmd.com"];

  isBlacklistedUrl = function(url) {
    var site, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = intercept_sites.length; _i < _len; _i++) {
      site = intercept_sites[_i];
      if (url.indexOf("http://www." + site) >= 0 || url.indexOf("http://" + site) >= 0) {
        true;
      }
      _results.push(false);
    }
    return _results;
  };

  cleanupHistory = function(startTime, endTime) {
    var maxResults, t;
    if (!startTime) {
      t = new Date(2010, 0, 1, 0);
      startTime = t.getTime();
    }
    if (!endTime) {
      t = new Date();
      endTime = t.getTime();
    }
    maxResults = 1000000000;
    chrome.history.search({
      text: "",
      startTime: startTime,
      endTime: endTime,
      maxResults: maxResults
    }, function(historyItems) {
      var hItem, _i, _len;
      for (_i = 0, _len = historyItems.length; _i < _len; _i++) {
        hItem = historyItems[_i];
        if (hItem.url.indexOf("wikipedia.org") >= 0) {
          chrome.history.deleteUrl({
            "url": hItem.url
          });
        }
      }
      console.profileEnd("iterating through history");
      return void 0;
    });
    return void 0;
  };

  Mode = function() {
    var getMode, setMode;
    setMode = function(mode) {
      localStorage["operation_mode"] = mode;
      return mode;
    };
    return getMode = function() {
      return localStorage["operation_mode"];
    };
  };

  benchmark = function() {
    var all_sites_regex, dummy_url, i, random_string, random_urls, regex_str, url, _i, _j, _len;
    random_urls = [];
    for (i = _i = 0; _i <= 200; i = ++_i) {
      random_string = Math.random().toString(36).substring(7);
      random_urls.push("" + random_string + ".net");
    }
    regex_str = "^(http://|https://)?([aA-zZ0-9\\-\\_]*\\.)?(" + (random_urls.join("|")) + ")(/.*)?$";
    all_sites_regex = new RegExp(regex_str);
    dummy_url = "subdomain.some-pretty-long-url.com/example?query=test";
    console.profile("indexof performance");
    for (_j = 0, _len = random_urls.length; _j < _len; _j++) {
      url = random_urls[_j];
      if (dummy_url.indexOf(url) > 0) {
        console.log("hit");
      } else if (dummy_url.indexOf("http://www." + url) >= 0) {
        console.log("hit");
      } else if (dummy_url.indexOf("http://" + url) >= 0) {
        console.log("hit");
      }
    }
    console.profileEnd();
    console.profile("regex perfomance");
    if (dummy_url.search(all_sites_regex) !== -1) {
      console.log("hit");
    }
    return console.profileEnd();
  };

  PrivateStash = (function() {

    function PrivateStash() {}

    return PrivateStash;

  })();

  WipeMode = (function() {
    var open_tabs;

    function WipeMode() {}

    open_tabs = [];

    WipeMode.prototype.tabAdded = function(tabId, changeInfo, tab) {
      if (isBlacklistedUrl(tab.url) && open_tabs.indexOf(tabId) === -1) {
        open_tabs.push(tabId);
        console.log(tab);
      }
      if (changeInfo.url) {
        if (isBlacklistedUrl(changeInfo.url) && open_tabs.indexOf(tabId) === -1) {
          open_tabs.push(tabId);
        } else if (!isBlacklistedUrl(changeInfo.url) && facebook_tabs.indexOf(tabId) >= 0) {
          this.tabClosed(tabId);
        }
      }
      return console.log(facebook_tabs);
    };

    WipeMode.prototype.tabClosed = function(tabId) {
      var former_bad_tab;
      former_bad_tab = open_tabs.indexOf(tabId);
      if (former_bad_tab >= 0) {
        console.log("tab " + former_bad_tab + " closed");
        open_tabs.splice(former_bad_tab, 1);
        if (open_tabs.length === 0) {
          this.wipeHistory();
        }
        return console.log("facebook tabs open " + facebook_tabs.length);
      }
    };

    WipeMode.prototype.wipeHistory = function() {
      return console.log("time to clean up fb logs...");
    };

    return WipeMode;

  })();

  chrome.webRequest.onBeforeRequest.addListener(interceptRequest, {
    urls: ["http://*/*"],
    types: ["main_frame"]
  }, ["blocking"]);

  "chrome.tabs.onUpdated.addListener(\n  (tabId, changeInfo, tab) ->\n    if face_protect\n      face_protect.tabAdded(tabId, changeInfo, tab)\n)\n\nchrome.tabs.onRemoved.addListener(\n  (tabId, removeInfo) ->\n    if face_protect\n      face_protect.tabClosed(tabId)\n)";


  console.profile("iterating through history");

  cleanupHistory2();

  localStorage["enable_faceprotect"] = true;

  if (localStorage["enable_faceprotect"]) {
    face_protect = new FaceProtect;
  }

}).call(this);
