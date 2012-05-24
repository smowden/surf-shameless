(function() {
  var FaceProtect, Mode, benchmark, cleanupHistory, face_protect, interceptRequest, intercept_sites;

  intercept_sites = ["youjizz.com", "spankwire.com", "webmd.com"];

  interceptRequest = function(info) {
    var current_url, site, _i, _len;
    current_url = info.url;
    for (_i = 0, _len = intercept_sites.length; _i < _len; _i++) {
      site = intercept_sites[_i];
      if (current_url.indexOf("http://www." + site) >= 0 || current_url.indexOf("http://" + site) >= 0) {
        chrome.windows.create({
          "url": info.url,
          "incognito": true
        }, function() {
          chrome.tabs.remove(info.tabId);
          return console.log("spawned new window");
        });
        return {
          "cancel": true
        };
      }
    }
  };

  cleanupHistory = function() {
    var all_filtered_sites, all_sites_regex, regex_str;
    all_filtered_sites = intercept_sites;
    regex_str = "^(http://|https://)?([aA-zZ0-9\\-\\_]*\\.)?(" + (all_filtered_sites.join("|")) + ")(/.*)?$";
    all_sites_regex = new RegExp(regex_str);
    return chrome.history.search({
      "text": ""
    }, function(history_items) {
      var h_item, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = history_items.length; _i < _len; _i++) {
        h_item = history_items[_i];
        if (h_item.url.toLowerCase().search(all_sites_regex) !== -1) {
          _results.push(chrome.history.deleteUrl({
            "url": h_item.url
          }));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    });
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
    var all_sites_regex, dummy_url, i, random_string, random_urls, regex_str, url, _i, _len;
    random_urls = [];
    for (i = 0; i <= 200; i++) {
      random_string = Math.random().toString(36).substring(7);
      random_urls.push("" + random_string + ".net");
    }
    regex_str = "^(http://|https://)?([aA-zZ0-9\\-\\_]*\\.)?(" + (random_urls.join("|")) + ")(/.*)?$";
    all_sites_regex = new RegExp(regex_str);
    dummy_url = "subdomain.some-pretty-long-url.com/example?query=test";
    console.profile("indexof performance");
    for (_i = 0, _len = random_urls.length; _i < _len; _i++) {
      url = random_urls[_i];
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
    if (dummy_url.search(all_sites_regex) !== -1) console.log("hit");
    return console.profileEnd();
  };

  FaceProtect = (function() {
    var facebook_tabs;

    function FaceProtect() {}

    facebook_tabs = [];

    FaceProtect.prototype.tabAdded = function(tabId, changeInfo, tab) {
      if (tab.url.indexOf("facebook") >= 0 && facebook_tabs.indexOf(tabId) === -1) {
        facebook_tabs.push(tabId);
        console.log(tab);
      }
      if (changeInfo.url) {
        if (changeInfo.url.indexOf("facebook") >= 0 && facebook_tabs.indexOf(tabId) === -1) {
          facebook_tabs.push(tabId);
        } else if (changeInfo.url.indexOf("facebook") === -1 && facebook_tabs.indexOf(tabId) >= 0) {
          this.tabClosed(tabId);
        }
      }
      return console.log(facebook_tabs);
    };

    FaceProtect.prototype.tabClosed = function(tabId) {
      var former_fb_tab;
      former_fb_tab = facebook_tabs.indexOf(tabId);
      if (former_fb_tab >= 0) {
        console.log("tab " + former_fb_tab + " closed");
        facebook_tabs.splice(former_fb_tab, 1);
        if (facebook_tabs.length === 0) this.cleanupFacebook();
        return console.log("facebook tabs open " + facebook_tabs.length);
      }
    };

    FaceProtect.prototype.cleanupFacebook = function() {
      return console.log("time to clean up fb logs...");
    };

    return FaceProtect;

  })();

  chrome.webRequest.onBeforeRequest.addListener(interceptRequest, {
    urls: ["http://*/*"],
    types: ["main_frame"]
  }, ["blocking"]);

  chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
    if (face_protect) return face_protect.tabAdded(tabId, changeInfo, tab);
  });

  chrome.tabs.onRemoved.addListener(function(tabId, removeInfo) {
    if (face_protect) return face_protect.tabClosed(tabId);
  });

  cleanupHistory();

  localStorage["enable_faceprotect"] = true;

  if (localStorage["enable_faceprotect"]) {
    face_protect = new FaceProtect;
    console.log(face_protect);
  }

  if (!localStorage["is_setup"]) alert("please setup this extension");

}).call(this);
