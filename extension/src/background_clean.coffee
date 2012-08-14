# todo credit pixture for the icon ( http://www.pixture.com/drupal/ )
#############################################

class MyBlacklist
  readyState: false

  totalEnabled = 0
  customBlacklist = undefined
  joinedBlacklist = undefined


  settings =
    myAvailableLists: undefined
    enabledLists: {}
    lastListUpdate: undefined


  constructor: ->
    @init()


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

    console.log("settings", settings)
    customBlacklist = @getCustomLists()
    joinedBlacklist = jQuery.extend(true, {}, customBlacklist)


    console.log("custom blacklist", customBlacklist)

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


  getCustomLists: ->
    lists =
      keywords: []
      urls: []

    possibleBlacklist = CryptoJS.AES.decrypt(localStorage["customBlacklist"], localStorage["obfuKey"])
                      .toString(CryptoJS.enc.Utf8)

    if possibleBlacklist.length > 0
      try
        lists = JSON.parse(possibleBlacklist)
      catch e
        alert e

    lists

  loadSettings: ->
    if localStorage["efSettings"] != undefined and localStorage["efSettings"] != "undefined"
      storedSettings = JSON.parse(localStorage["efSettings"])
      return storedSettings
    return undefined

  saveSettings: ->
    localStorage["efSettings"] = JSON.stringify(settings)


  storeObfuscatedBlacklist: ->
    console.log("storing custom blacklist", customBlacklist)
    localStorage["customBlacklist"] = CryptoJS.AES.encrypt(JSON.stringify(customBlacklist), localStorage["obfuKey"]).toString()

  addToBlacklist: (type, entry) ->
    console.log("add to blacklist called with", type, entry)
    entry = entry.toLowerCase()
    if type == "url"
      entry = "http://#{entry}" if entry.indexOf("http://") == -1 and entry.indexOf("https://") == -1
      parser = document.createElement('a');
      parser.href = entry
      hostname = parser.hostname.replace("www.", "")
      if customBlacklist.urls.indexOf(hostname) == -1
        customBlacklist.urls.push(hostname)
        @storeObfuscatedBlacklist()
      return hostname
    else if type == "keyword"
      if customBlacklist.keywords.indexOf(entry) == -1
        customBlacklist.keywords.push(entry)
        @storeObfuscatedBlacklist()

  removeFromBlacklist: (type, entry) ->
    console.log("removeFromBlacklist", type, entry)
    entry = entry.toLowerCase()
    listIndex = customBlacklist[type+"s"].indexOf(entry)
    if listIndex >= 0
      customBlacklist[type+"s"].splice(listIndex, 1)
    @storeObfuscatedBlacklist()


  getBlacklist:  ->
    joinedBlacklist

  getCustomList: ->
    customBlacklist

  isBlacklisted: (string, type) ->
    string = string.toLowerCase()
    lookupDir = joinedBlacklist.urls if type == "url"
    lookupDir = joinedBlacklist.keywords if type == "keyword"

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

  loadEnabledLists: =>
    # minor bug, once a list is enabled it is loaded twice into the joined lists
    if settings.enabledLists
      console.log("enabledLists check")
      if settings.myAvailableLists
        console.log("myAvailableLists check")
        totalEnabled = 0
        console.log("available lists", settings.myAvailableLists)
        console.log("enabled lists", settings.enabledLists)

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
        joinedBlacklist.urls = joinedBlacklist.urls.concat(listObject.content)
      else if listObject.type == "keywords"
        joinedBlacklist.keywords = joinedBlacklist.keywords.concat(listObject.content)
      console.log("joined blacklist", joinedBlacklist)
      if index == totalEnabled
        @readyState = true

  setListState: (name, state) -> #state is true/false for enabled/disabled
    if typeof state == "boolean"
      settings.enabledLists[name] = state
    @saveSettings()

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
    unless myBlacklist.readyState
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
      localStorage["totalRemoved"] = JSON.parse(localStorage["totalRemoved"]) + deleteCount

      undefined
    )
    undefined

  installListeners: ->
    chrome.tabs.onUpdated.addListener(
      @tabAdded
    )

    chrome.tabs.onRemoved.addListener(
      (tabId, removeInfo) ->
        @tabClosed(tabId)
    )

    chrome.webRequest.onBeforeRedirect.addListener(
      @onRedirect,
      {
      urls: ["http://*/*"],
      types: ["main_frame"]
      }
    )

class InterceptMode
  constructor: (@myBlacklist) ->
    @init()

  init: =>
    unless myBlacklist.readyState
      setTimeout(
        =>
          @init()
        , 100
      )
    else
      if chrome.webRequest.onBeforeRequest.hasListener()
        chrome.webRequest.onBeforeRequest.removeListener()

      filter = @buildFilter()

      if filter.length > 0
        chrome.webRequest.onBeforeRequest.addListener(
          @intercept
          ,{
            urls: filter,
            types: ["main_frame"]
          },
          ["blocking"]
        )


  intercept: (details) ->
    localStorage["totalRemoved"] = JSON.parse(localStorage["totalRemoved"]) + 1

    chrome.windows.create(
      {
        "url": details.url,
        "incognito": true
      }
      , ->
        chrome.tabs.remove(details.tabId)
        console.log("spawned new window")
    )
    {"cancel": true}

  buildFilter: ->
    tmpFilter = []
    blacklist = @myBlacklist.getBlacklist()

    for url in blacklist["urls"]
      tmpFilter.push("*://*.#{url}/*")
      tmpFilter.push("*://#{url}/*")

    console.log("tmp filter:", tmpFilter)
    tmpFilter

class ContextMenu
  constructor: (@myBlacklist) ->
    parent = chrome.contextMenus.create({"title": "Embarrassment Filter"})

    child1 = chrome.contextMenus.create(
      {"title": "Don't log my visits to this site", "parentId": parent, "onclick": @contextMenuAddSite})

    child2 = chrome.contextMenus.create(
      {"title": "Make this a private bookmark", "parentId": parent, "onclick": @contextMenuAddSite})

  contextMenuAddSite: (info, tab) ->
    hostname = myBlacklist.addToBlacklist("url", tab.url)
    alert "Added #{hostname} to your blacklist"

if localStorage["firstRun"] == undefined
  localStorage["obfuKey"] = CryptoJS.PBKDF2(Math.random().toString(36).substring(2), "efilter", { keySize: 256/32, iterations: 100 }).toString()
  localStorage["firstRun"] = false
  localStorage["opMode"] = 1
  emptyList =
    keywords: []
    urls: []
  localStorage["customBlacklist"] = CryptoJS.AES.encrypt(JSON.stringify(emptyList), localStorage["obfuKey"]).toString()
  localStorage["totalRemoved"] = 0
  chrome.tabs.create({url: "first_run.html"})

opMode = JSON.parse(localStorage["opMode"]) # 0 - preventive, 1 - retroactive
myBlacklist = new MyBlacklist()
contextMenu = new ContextMenu(myBlacklist)
wipeMode = new WipeMode(myBlacklist)

if opMode == 0
  interceptMode = new InterceptMode(myBlacklist)
else if opMode == 1
  wipeMode.installListeners()

reloadAll = ->
  myBlacklist.init()
  wipeMode.wipeHistory(undefined, true)
  interceptMode.init() if opMode == 0


chrome.extension.onRequest.addListener(
  (request, sender, sendResponse) ->
    console.log("got request", request)
    if request.action == "getAvailableLists"
      myBlacklist.getAvailableLists(undefined,true)
    else if request.action == "changeListState"
      myBlacklist.setListState(request.listName, request.listState)
      reloadAll()
    else if request.action == "reInit"
      reloadAll()
    else if request.action == "addToBlacklist"
      myBlacklist.addToBlacklist(request.type, request.entry)
      sendResponse(myBlacklist.getCustomList())
    else if request.action == "rmFromBlacklist"
      myBlacklist.removeFromBlacklist(request.type, request.entry)
      sendResponse(myBlacklist.getCustomList())
    else if request.action == "getLists"
      sendResponse(myBlacklist.getCustomList())

    console.log(request)
)