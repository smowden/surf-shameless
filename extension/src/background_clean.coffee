# todo on first run flush the cache or delete "History Provider Cache" in user folder AND archived history
# todo credit pixture for the icon ( http://www.pixture.com/drupal/ )
# todo build better/custom localstorage handler
#############################################







class MyBlacklist
  readyState: false

  totalEnabled = 0
  customBlacklist = undefined

  settings =
    myAvailableLists: undefined
    enabledLists: {}
    lastListUpdate: undefined


  constructor: () ->
    @init()

  getCustomLists: () ->
    lists =
      keywords: []
      urls: []

    if localStorage["myCustomKeywordList"] != "undefined" and typeof localStorage["myCustomKeywordList"] != "undefined"
      lists.keywords = JSON.parse(localStorage["myCustomKeywordList"])

    if localStorage["myCustomUrlList"] != "undefined" and typeof localStorage["myCustomUrlList"] != "undefined"
      lists.urls = JSON.parse(localStorage["myCustomUrlList"])

    lists

  loadSettings: () ->
    if localStorage["efSettings"] != undefined and localStorage["efSettings"] != "undefined"
      storedSettings = JSON.parse(localStorage["efSettings"])
      return storedSettings
    return undefined

  saveSettings: () ->
    localStorage["efSettings"] = JSON.stringify(settings)

  init: () ->
    ###
    as the name init suggestst this method (re)initializes the blacklist
    this means it populates the blacklistKeywords and blacklistUrls with the user defined keywords and urls
    and then proceeds to join them with the lists that the user enabled
    once initialization is done readyState is true
    ###

    console.log("init...")

    storedSettings = @loadSettings()
    settings = storedSettings if storedSettings != undefined

    console.log(settings)
    customBlacklist = @getCustomLists()

    @readyState = false
    if settings.myAvailableLists == undefined
      @getAvailableLists()
      setTimeout(
        =>
          @init()
        , 100
      )

    else
      console.log("enabling lists...")
      @loadEnabledLists()


  getBlacklist: () ->
    customBlacklist

  isBlacklisted: (string, type) ->
    string = string.toLowerCase()
    lookupDir = customBlacklist.urls if type == "url"
    lookupDir = customBlacklist.keywords if type == "keyword"

    for s in lookupDir
      if type == "url"
        if string.indexOf("http://www.#{s}") >= 0 or string.indexOf("http://#{s}") >= 0 or string.indexOf("https://#{s}") >= 0
          return true
      else if type == "keyword"
        if string.indexOf(s) >= 0
          return true
    false

  getAvailableLists: (availableLists, refresh) =>
    if (settings.myAvailableLists == undefined and not availableLists) or refresh
      @getLocalFile("lists/_available", @getAvailableLists)
      undefined
    else
      settings.myAvailableLists = availableLists
      @saveSettings()

  loadEnabledLists: () =>
    if settings.enabledLists
      console.log("enabledLists check")
      if settings.myAvailableLists
        console.log("myAvailableLists check")
        totalEnabled = 0
        console.log(settings.myAvailableLists)
        console.log(settings.enabledLists)

        enabledListsIndex = 0
        totalDisabled = 0

        for listName in settings.myAvailableLists
          if settings.enabledLists[listName]
            enabledListsIndex++
            totalEnabled++
            console.log("loading list #{listName}")
            @loadList(undefined, listName, enabledListsIndex)
          else
            totalDisabled++

        if totalEnabled == 0 and totalDisabled > 0
          @readyState = true
        console.log("end of list enabler")


        return true

    @readyState = true

  loadList: (listObject, name, index) =>
    if not listObject
      @getLocalFile("lists/#{name}", @loadList, name, index)
    else
      if listObject.type == "urls"
        customBlacklist.urls = customBlacklist.urls.concat(listObject.content)
      else if listObject.type == "keywords"
        customBlacklist.keywords = customBlacklist.keywords.concat(listObject.content)
      console.log(customBlacklist)
      if index == totalEnabled
        @readyState = true

  setListState: (name, state) -> #state is true/false for enabled/disabled
    if typeof state == "boolean"
      settings.enabledLists[name] = state
    @saveSettings()
    console.log("enabled lists", settings.enabledLists)
    @loadEnabledLists()

  getLocalFile: (path, callback, var1, var2) ->
    xhr = new XMLHttpRequest()
    xhr.open("GET", path, true)
    xhr.onreadystatechange = =>
      if xhr.readyState == 4
        callback(JSON.parse(xhr.responseText), var1, var2)
    xhr.send()



class WipeMode
  openTabs = [] # openTabs is a list of all the tabs whose history should be deleted upon closing all of them
  badRedirects = []
  firstBadTabTime = undefined

  constructor: (@myBlacklist) ->
    @init()

  init: () ->
    console.log("waiting for readyness")
    if not myBlacklist.readyState
      setTimeout(
        =>
          @init()
        , 100
      )
    else
      @wipeHistory(undefined, true)

  ###
  tabAdded, tabClosed and onRedirect keep track of whether blacklisted urls are currently open
  or whether redirects to blacklisted sites occured
  once all tabs with blacklisted urls are closed the history will be cleaned out
  ###
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


  onRedirect: (details) ->
    if myBlacklist.isBlacklisted(details.redirectUrl, "url") and badRedirects.indexOf(details.redirectUrl)
      badRedirects.push(details.url)
      console.log(badRedirects)
    undefined

  purgeBadUrl: (url) ->
    ###
    if we just delete the url the item will disappear from the history but a www. prefixed
    version will still show up in the omnibox so and the other way round
    therefore we need to make sure that both types of urls are deleted
    ###

    if url.indexOf("http") == -1
      ###
      if the url comes from a list and WipeMode is initialized it will only
      consist of domain.tld so we need to prefix it with the proper possible schemes
      otherwise it won't be deleted
      ###
      url = "http://#{url}"
      httpsUrl = "https://#{url}"

    chrome.history.deleteUrl({url: url})
    chrome.history.deleteUrl({url: httpsUrl}) if httpsUrl

    if url.indexOf("www") >= 0
      chrome.history.deleteUrl({url: url.replace("http://www.", "http://")})
      console.log("purged #{url.replace("http://www.", "http://")}")
    else
      chrome.history.deleteUrl({url: url.replace("http://", "http://www.")})
      console.log("purged #{url.replace("http://", "http://www.")}")

  wipeHistory: (startTime, doFullClean) ->

    startTime = new Date(2000, 0, 1, 0).getTime() if not startTime
    endTime = new Date().getTime()

    if doFullClean
      console.log(myBlacklist.getBlacklist())
      for site in myBlacklist.getBlacklist().urls
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

contextMenuAddSite = (info, tab) ->
  parser = document.createElement('a');
  parser.href = tab.url
  myCustomUrls = JSON.parse(localStorage["myCustomUrlList"])
  hostname = parser.hostname.replace("www.", "")
  if myCustomUrls.indexOf(hostname) == -1
    myCustomUrls.push(hostname)
    localStorage["myCustomUrlList"] = JSON.stringify(myCustomUrls)

  alert "Added #{hostname} to your blacklist"



myBlacklist = new MyBlacklist()
console.log(myBlacklist.getBlacklist("urls"))

wipeMode = new WipeMode(myBlacklist)


parent = chrome.contextMenus.create({"title": "Embaressment Filter"})

child1 = chrome.contextMenus.create(
  {"title": "Don't log my visits to this site", "parentId": parent, "onclick": contextMenuAddSite})

child2 = chrome.contextMenus.create(
  {"title": "Make this a private bookmark", "parentId": parent, "onclick": contextMenuAddSite})

console.log("parent:" + parent + " child1:" + child1 + " child2:" + child2)

if localStorage["myCustomUrlList"] == "undefined" or typeof localStorage["myCustomUrlList"] == "undefined"
  localStorage["myCustomUrlList"] = JSON.stringify([])

if localStorage["myCustomKeywordList"] == "undefined" or typeof localStorage["myCustomKeywordList"] == "undefined"
  localStorage["myCustomKeywordList"] = JSON.stringify([])

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
      myBlacklist.init()
      wipeMode.wipeHistory(undefined, true)
      console.log(myBlacklist.getBlacklist("urls"))
      console.log(myBlacklist.getBlacklist("keywords"))
    else if request.action == "reInit"
      myBlacklist.init()
      wipeMode.wipeHistory(undefined, true)

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