# todo on first run flush the cache or delete "History Provider Cache" in user folder AND archived history
# todo credit pixture for the icon ( http://www.pixture.com/drupal/ )

#############################################

class MyBlacklist
  blacklistUrls = ["spankwire.com"]
  customUrls = []
  blacklistKeywords = []
  lastListUpdate = 0
  readyState = false
  totalEnabled = 0

  constructor: () ->
    @init()

  isReady: () ->
    return readyState

  init: () ->
    console.log("init...")
    if localStorage["myAvailableLists"] == "undefined" or localStorage["myAvailableLists"] == undefined
      @getAvailableLists()
      setTimeout(
        =>
          @init()
        , 100
      )
    else
      console.log("enabling lists...")
      @loadEnabledLists()


  getBlacklist: (type) ->
    if type == "urls"
      return blacklistUrls
    else
      return blacklistKeywords

  isBlacklisted: (string, type) ->
    string = string.toLowerCase()
    lookupDir = blacklistUrls if type == "url"
    lookupDir = blacklistKeywords if type == "keyword"
    for s in lookupDir
      if type == "url"
        if string.indexOf("http://www.#{s}") >= 0 or string.indexOf("http://#{s}") >= 0
          return true
      else if type == "keyword"
        if string.indexOf(s) >= 0
          return true
    false

  getAvailableLists: (availableLists, refresh) ->
    if (localStorage["myAvailableLists"] == "undefined" and not availableLists) or refresh
      @getLocalFile("lists/_available", @getAvailableLists)
      undefined
    else
      localStorage["myAvailableLists"] = JSON.stringify(availableLists)

  loadEnabledLists: () ->
    if localStorage["enabledLists"] != "undefined" and localStorage["enabledLists"] != undefined
      console.log("enabledLists check")
      if localStorage["myAvailableLists"] != "undefined" and localStorage["myAvailableLists"] != undefined
        console.log("myAvailableLists check")
        totalEnabled = 0
        enabledLists = JSON.parse(localStorage["enabledLists"])
        availableLists = JSON.parse(localStorage["myAvailableLists"])
        console.log(availableLists)
        console.log(enabledLists)
        blacklistUrls = []
        blacklistKeywords = []
        for listName, i in availableLists
          if enabledLists[listName]
            totalEnabled++
            console.log("loading list #{listName}")
            @loadList(undefined, listName, i)


  loadList: (listObject, name, index) ->
    if not listObject
      @getLocalFile("lists/#{name}", @loadList, name, index)
    else
      if listObject.type == "urls"
        blacklistUrls = blacklistUrls.concat(listObject.content)
      else if listObject.type == "keywords"
        blacklistKeywords = blacklistKeywords.concat(listObject.content)
      if index == totalEnabled-1
        readyState = true

  reload: () ->
    if localStorage["lastUserUpdate"] >= lastListUpdate
      @loadEnabledLists()

  setListState: (name, state) -> #state is true/false for enabled/disabled
    if not localStorage["enabledLists"] or localStorage["enabledLists"] == "undefined"
      enabledLists = {}
    else
      enabledLists = JSON.parse(localStorage["enabledLists"])
    if state == true or state == false
      enabledLists[name] = state
    localStorage["enabledLists"] = JSON.stringify(enabledLists)
    console.log(localStorage["enabledLists"])
    @loadEnabledLists()

  getLocalFile: (path, callback, var1, var2) ->
    xhr = new XMLHttpRequest()
    xhr.open("GET", path, true)
    xhr.onreadystatechange = =>
      if xhr.readyState == 4
        callback(JSON.parse(xhr.responseText), var1, var2)
    xhr.send()

class WipeMode
  openTabs = [] # open tabs are all the tabs whose history should be deleted upon closing all of them
  badRedirects = []
  firstBadTabTime = undefined

  constructor: (@myBlacklist) ->
    @init()

  init: () ->
    if not myBlacklist.isReady()
      setTimeout(
        =>
          @init()
        , 100
      )
    else
      @wipeHistory(undefined, true)

  tabAdded: (tabId, changeInfo, tab) =>
    currentUrl = tab.url
    if changeInfo.url
      currentUrl = changeInfo.url

    if (myBlacklist.isBlacklisted(currentUrl, "url") or myBlacklist.isBlacklisted(tab.title, "keyword")) and openTabs.indexOf(tabId) == -1
      firstBadTabTime = (new Date().getTime() - 10000) if not firstBadTabTime
      # ^ the 10 second difference is to make sure we wont miss anything
      openTabs.push(tabId)
      console.log(openTabs)
    else if not (myBlacklist.isBlacklisted(currentUrl, "url") or myBlacklist.isBlacklisted(tab.title, "keyword")) and openTabs.indexOf(tabId) >= 0
      @tabClosed(tabId)
      undefined


  tabClosed: (tabId) ->
    formerBadTab = openTabs.indexOf(tabId)

    if formerBadTab >= 0
      openTabs.splice(formerBadTab, 1)
      if openTabs.length == 0
        @wipeHistory(firstBadTabTime)
        firstBadTabTime = undefined

  purgeBadUrl: (url) ->
    # todo does not completely delete all traces todo investigate (if used with an existing profile)
    # unfortunately we cant retroactively delete all bad redirects but
    # this should take care of the ordinary www redirects

    if url.indexOf("http") == -1
      url = "http://#{url}"

    chrome.history.deleteUrl({url: url})
    if url.indexOf("www") >= 0
      chrome.history.deleteUrl({url: url.replace("http://www.", "http://")})
      console.log("purged #{url.replace("http://www.", "http://")}")
    else
      chrome.history.deleteUrl({url: url.replace("http://", "http://www.")})
      console.log("purged #{url.replace("http://", "http://www.")}")

  onRedirect: (details) ->
    if myBlacklist.isBlacklisted(details.redirectUrl, "url") and badRedirects.indexOf(details.redirectUrl)
      badRedirects.push(details.url)
      console.log(badRedirects)
    undefined

  wipeHistory: (startTime, doFullClean) ->

    startTime = new Date(2000, 0, 1, 0).getTime() if not startTime
    endTime = new Date().getTime()

    if doFullClean
      for site in myBlacklist.getBlacklist("urls")
        @purgeBadUrl(site)

    maxResults = 1000000000
    chrome.history.search(
      {text: "", startTime: startTime, endTime: endTime, maxResults: maxResults},
      # specifying a text for the search seems to just return completely random results
    (historyItems) =>
      deleteCount = 0
      for hItem in historyItems
        if myBlacklist.isBlacklisted(hItem.url, "url") or myBlacklist.isBlacklisted(hItem.title, "keyword")
          @purgeBadUrl(hItem.url)
          deleteCount++
        if hItem.url.indexOf(".google.") >= 0
          if myBlacklist.isBlacklisted(hItem.url, "keyword") # get rid of nasty google redirects
            @purgeBadUrl(hItem.url)
            deleteCount++

      for nastyRedirect in badRedirects
        chrome.history.deleteUrl(url: nastyRedirect)
        deleteCount++

      localStorage["popup_lastCleanupTime"] =  JSON.stringify(new Date)
      localStorage["popup_cleanupUrlCounter"] =  deleteCount

      undefined
    )
    undefined

myBlacklist = new MyBlacklist()
console.log(myBlacklist.getBlacklist("urls"))

wipeMode = new WipeMode(myBlacklist)



chrome.tabs.onUpdated.addListener(
    wipeMode.tabAdded
)

chrome.tabs.onRemoved.addListener(
  (tabId, removeInfo) ->
    wipeMode.tabClosed(tabId)
)

chrome.extension.onRequest.addListener(
  (request, sender, sendResponse) ->
    if request.action == "getAvailableLists"
      myBlacklist.getAvailableLists(undefined,true)
    else if request.action == "changeListState"
      myBlacklist.setListState(request.listName, request.listState)
      console.log(myBlacklist.getBlacklist("urls"))
      console.log(myBlacklist.getBlacklist("keywords"))

    console.log(request)
)

chrome.webRequest.onBeforeRedirect.addListener(
  wipeMode.onRedirect,
  {
    urls: ["http://*/*"],
    types: ["main_frame"]
  }
)
"""
chrome.webRequest.onBeforeRequest.addListener(
  interceptRequest
  ,{
  urls: ["http://*/*"],
  types: ["main_frame"]
  },
  ["blocking"]
)
"""