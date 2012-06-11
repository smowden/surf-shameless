intercept_sites = ["youjizz.com", "spankwire.com", "webmd.com"]

# NOTE, leaves no trace in history but the page still shows up in the omnibox (without details)
# and is not removable through the exposed apis
# todo report to google
isBlacklistedUrl = (url) ->
  for site in intercept_sites
    if url.indexOf("http://www.#{site}") >= 0 or url.indexOf("http://#{site}") >= 0
      true
    false





cleanupHistory = (startTime, endTime) ->
  if not startTime
    t = new Date(2010, 0, 1, 0)
    startTime = t.getTime()

  if not endTime
    t = new Date()
    endTime = t.getTime()

  maxResults = 1000000000
  chrome.history.search(
    {text: "", startTime: startTime, endTime: endTime, maxResults: maxResults},
    # specifying a text for the search seems to just return completely random results
    (historyItems) ->
      #console.log(historyItems)
      #todo show confirmation promt of some kind before deletion

      for hItem in historyItems
          if hItem.url.indexOf("wikipedia.org") >= 0
            chrome.history.deleteUrl({"url": hItem.url})

      console.profileEnd("iterating through history")
      undefined
  )
  undefined

Mode = () ->
  setMode = (mode) ->
    localStorage["operation_mode"] = mode
    return mode

  getMode = () ->
    return localStorage["operation_mode"]

benchmark = () ->
  random_urls = []
  for i in [0..200]
    random_string = Math.random().toString(36).substring(7);
    random_urls.push "#{ random_string }.net"

  regex_str = "^(http://|https://)?([aA-zZ0-9\\-\\_]*\\.)?(#{ random_urls.join("|") })(/.*)?$"
  all_sites_regex = new RegExp(regex_str)

  dummy_url = "subdomain.some-pretty-long-url.com/example?query=test"

  console.profile("indexof performance")

  for url in random_urls
    if dummy_url.indexOf(url) > 0
      console.log("hit")
    else if dummy_url.indexOf("http://www.#{url}") >= 0
      console.log("hit")
    else if dummy_url.indexOf("http://#{url}") >= 0
      console.log("hit")

  console.profileEnd()


  console.profile("regex perfomance")

  if dummy_url.search(all_sites_regex) != -1
    console.log("hit")


  console.profileEnd()

  # conclusion: indexOf is approximately 4 times faster for this use case (6 vs 26 ms) with 6000 urls
  # 2 vs 7 ms with 1000 urls
  # 2 vs 4 with 500 urls
  # 2 vs 3 with 200 urls
  # and both time <= 2ms with random_urls length <= 100
  # (tested with Chromium 17 and a Phenom II 945, 8 GB RAM)

class PrivateStash
  # todo add omnibox to permissions and enable users to add custom urls to their stash

class WipeMode

  open_tabs = []

  tabAdded: (tabId, changeInfo, tab) ->
    if isBlacklistedUrl(tab.url) and open_tabs.indexOf(tabId) == -1
      open_tabs.push(tabId)
      console.log(tab)

    if changeInfo.url
      if isBlacklistedUrl(changeInfo.url) and open_tabs.indexOf(tabId) == -1
        open_tabs.push(tabId)
      else if not isBlacklistedUrl(changeInfo.url) and facebook_tabs.indexOf(tabId) >= 0
        this.tabClosed(tabId)

    console.log(facebook_tabs)

  tabClosed: (tabId) ->
    former_bad_tab = open_tabs.indexOf(tabId)

    if former_bad_tab >= 0
      console.log("tab #{former_bad_tab} closed")
      open_tabs.splice(former_bad_tab, 1)
      if open_tabs.length == 0
        this.wipeHistory()
      console.log("facebook tabs open "+facebook_tabs.length)

  wipeHistory: () ->
    #todo write regex cleanup
    #todo show confirmation
    console.log("time to clean up fb logs...")



chrome.webRequest.onBeforeRequest.addListener(
  interceptRequest
  ,{
    urls: ["http://*/*"],
    types: ["main_frame"]
  },
  ["blocking"]
)
"""
chrome.tabs.onUpdated.addListener(
  (tabId, changeInfo, tab) ->
    if face_protect
      face_protect.tabAdded(tabId, changeInfo, tab)
)

chrome.tabs.onRemoved.addListener(
  (tabId, removeInfo) ->
    if face_protect
      face_protect.tabClosed(tabId)
)
"""
console.profile("iterating through history")
cleanupHistory2()

localStorage["enable_faceprotect"] = true

if localStorage["enable_faceprotect"]
  face_protect = new FaceProtect

