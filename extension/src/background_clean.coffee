# todo credit pixture for the icon ( http://www.pixture.com/drupal/ )
#############################################

REMOTE_SERVER_URL = "http://shameless.codesuela.com/"

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

    #console.log("init...")

    storedSettings = @loadSettings()
    settings = storedSettings if storedSettings != undefined

    #console.log("settings", settings)
    customBlacklist = @getCustomLists()
    joinedBlacklist = jQuery.extend(true, {}, customBlacklist)


    #console.log("custom blacklist", customBlacklist)

    @readyState = false
    if settings.myAvailableLists == undefined
      @getAvailableLists()
      setTimeout(
        =>
          @init()
        , 100
      )

    else
      #console.log("enabling lists...")
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
    #console.log("storing custom blacklist", customBlacklist)
    localStorage["customBlacklist"] = CryptoJS.AES.encrypt(JSON.stringify(customBlacklist), localStorage["obfuKey"]).toString()

  addToBlacklist: (type, entry) ->
    #console.log("add to blacklist called with", type, entry)
    entry = entry.toLowerCase()
    if type == "url"
      entry = "http://#{entry}" if entry.indexOf("http://") == -1 and entry.indexOf("https://") == -1
      parser = document.createElement('a');
      parser.href = entry
      hostname = parser.hostname.replace("www.", "")
      if customBlacklist.urls.indexOf(hostname) == -1
        customBlacklist.urls.push(hostname)
        @storeObfuscatedBlacklist()

        if JSON.parse(localStorage["allowRemote"])
          $.post(
            "#{REMOTE_SERVER_URL}submit/", {url: hostname}
          )
      return hostname
    else if type == "keyword"
      if customBlacklist.keywords.indexOf(entry) == -1
        customBlacklist.keywords.push(entry)
        @storeObfuscatedBlacklist()

  removeFromBlacklist: (type, entry) ->
    #console.log("removeFromBlacklist", type, entry)
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

    if lookupDir.length > 0
      if type == "url"
        r = new RegExp("http(s)?://(www.)?(#{lookupDir.join("|")})")
        if string.search(r) >= 0
          return true

      if type == "keyword"
        for s in lookupDir
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
      #console.log("enabledLists check")
      if settings.myAvailableLists
        #console.log("myAvailableLists check")
        totalEnabled = 0
        #console.log("available lists", settings.myAvailableLists)
        #console.log("enabled lists", settings.enabledLists)

        enabledListsIndex = 0
        totalDisabled = 0

        for listName in settings.myAvailableLists
          if settings.enabledLists[listName]
            enabledListsIndex++
            totalEnabled++
            #console.log("loading list #{listName}")
            @loadList(undefined, listName, enabledListsIndex)
          else
            totalDisabled++

        if totalEnabled == 0 and totalDisabled > 0
          @readyState = true
        #console.log("end of list enabler")


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
      #console.log("joined blacklist", joinedBlacklist)
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
    #console.log("waiting for readyness")
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
  tabAdded: (tabId, changeInfo, tab) ->
    currentUrl = tab.url
    if changeInfo.url
      currentUrl = changeInfo.url

    if (myBlacklist.isBlacklisted(currentUrl, "url") or myBlacklist.isBlacklisted(tab.title, "keyword")) and openTabs.indexOf(tabId) == -1
      firstBadTabTime = (new Date().getTime() - 10000) if not firstBadTabTime
      # ^ the 10 second difference is to make sure we wont miss anything
      openTabs.push(tabId)
      #console.log(openTabs)
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
      #console.log(badRedirects)
    undefined

  purgeBadUrl: (url) ->
    ###
    if we just delete the url the item will disappear from the history but a www. prefixed
    version will still show up in the omnibox so and the other way round
    therefore we need to make sure that both types of urls are deleted
    ###

    #console.log("purging url:", url)

    if url.indexOf("http") == -1
      ###
      if the url comes from a list and WipeMode is initialized it will only
      consist of domain.tld so we need to prefix it with the proper possible schemes
      otherwise it won't be deleted
      ###
      httpsUrl = "https://#{url}"
      url = "http://#{url}"
    else
      httpsUrl = url.replace("http://", "https://")

    chrome.history.deleteUrl({url: url})
    chrome.history.deleteUrl({url: httpsUrl})

    if url.indexOf("www") >= 0
      chrome.history.deleteUrl({url: url.replace("http://www.", "http://")})
      chrome.history.deleteUrl({url: httpsUrl.replace("https://www.", "https://")})
      #console.log("purged #{url.replace("http://www.", "http://")}")
      #console.log("purged #{httpsUrl.replace("https://www.", "https://")}")
    else
      chrome.history.deleteUrl({url: url.replace("http://", "http://www.")})
      chrome.history.deleteUrl({url: httpsUrl.replace("https://", "https://www.")})
      #console.log("purged #{url.replace("http://", "http://www.")}")
      #console.log("purged #{httpsUrl.replace("https://", "https://www.")}")

  deleteEntries: (deleteStack) ->
    url = deleteStack.pop()
    httpsUrl = url.replace("http://", "https://")
    _self = this

    chrome.history.deleteUrl({url: url}, ->
      chrome.history.deleteUrl({url: httpsUrl}, ->
        if url.indexOf("www") >= 0
          chrome.history.deleteUrl({url: url.replace("http://www.", "http://")}, ->
            #console.log("purged #{url.replace("http://www.", "http://")}")
            chrome.history.deleteUrl({url: httpsUrl.replace("https://www.", "https://")}, ->
              #console.log("purged #{httpsUrl.replace("https://www.", "https://")}")
              _self.deleteEntries(deleteStack)
            )
          )
        else
          chrome.history.deleteUrl({url: url.replace("http://", "http://www.")}, ->
            #console.log("purged #{url.replace("http://", "http://www.")}")
            chrome.history.deleteUrl({url: httpsUrl.replace("https://", "https://www.")}, ->
              #console.log("purged #{httpsUrl.replace("https://", "https://www.")}")
              _self.deleteEntries(deleteStack)
            )
          )
      )
    )

  wipeHistory: (startTime, doFullClean) ->
    startTime = new Date(2000, 0, 1).getTime() if not startTime
    endTime = new Date().getTime()
    visitStack = []


    if doFullClean
      #console.log(myBlacklist.getBlacklist())
      for site in myBlacklist.getBlacklist().urls
        @purgeBadUrl(site)

    maxResults = 100000000
    chrome.history.search(
      {text: "", startTime: startTime, endTime: endTime, maxResults: maxResults},
      # specifying a text for the search seems to just return completely random results
    (historyItems) =>

      deleteCount = 0
      visitCount = 0
      for hItem in historyItems
        if myBlacklist.isBlacklisted(hItem.url, "url") or myBlacklist.isBlacklisted(hItem.title, "keyword")
          chrome.history.getVisits({url: hItem.url},
            (results) ->
              visitCount += results.length
              for visitItem in results
                chrome.history.deleteRange({startTime:visitItem.visitTime-1, endTime:visitItem.visitTime+1}, ->
                  deleteCount++
                  localStorage["totalRemoved"] = JSON.parse(localStorage["totalRemoved"]) + 1
                  chrome.extension.sendRequest({'sAction': 'showProgress', 'processed': deleteCount, 'total': visitCount})
                )
          )

        if hItem.url.indexOf(".google.") >= 0
          if myBlacklist.isBlacklisted(hItem.url, "keyword") # get rid of nasty google redirects
            @purgeBadUrl(hItem.url)
            deleteCount++


      #console.log("!!!!!!!!!! DELETE COUNT !!!!!!!!!!", deleteCount)
      #@deleteEntries(deleteStack)

      for nastyRedirect in badRedirects
        chrome.history.deleteUrl(url: nastyRedirect)
        deleteCount++

      localStorage["popup_lastCleanupTime"] =  JSON.stringify(new Date)
      localStorage["totalRemoved"] = JSON.parse(localStorage["totalRemoved"]) + deleteCount

      undefined
    )
    undefined

  installListeners: ->
    chrome.tabs.onUpdated.addListener(
      (tabId, changeInfo, tab) =>
        #console.log(tabId, changeInfo, tab)
        @tabAdded(tabId, changeInfo, tab)
    )

    chrome.tabs.onRemoved.addListener(
      (tabId, removeInfo) =>
        @tabClosed(tabId)
    )

    chrome.webRequest.onBeforeRedirect.addListener(
      (details) =>
        @onRedirect(details)
      ,
      {
      urls: ["*://*/*"],
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
        #console.log("spawned new window")
    )
    {"cancel": true}

  buildFilter: ->
    tmpFilter = []
    blacklist = @myBlacklist.getBlacklist()

    for url in blacklist["urls"]
      tmpFilter.push("*://*.#{url}/*")
      tmpFilter.push("*://#{url}/*")

    #console.log("tmp filter:", tmpFilter)
    tmpFilter

class PrivateBookmarks

  bookmarks = undefined

  constructor: ->
    @loadBookmarks()

  loadBookmarks: ->
    possibleBookmarks = CryptoJS.AES.decrypt(localStorage["privateBookmarks"], localStorage["obfuKey"], "bookmarks")
    .toString(CryptoJS.enc.Utf8)

    if possibleBookmarks.length > 0
      try
        bookmarks = JSON.parse(possibleBookmarks)
      catch e
        alert e
    bookmarks

  saveBookmarks: ->
    localStorage["privateBookmarks"] = CryptoJS.AES.encrypt(JSON.stringify(bookmarks), localStorage["obfuKey"], "bookmarks").toString()

  getBookmarks: ->
    bookmarks

  addBookmark: (title, url) ->
    bookmark = {title: title, url: url}
    bookmarks.push(bookmark)
    #console.log("saving bookmark", bookmark)
    #console.log("private bookmarks", bookmarks)
    @saveBookmarks()

  removeBookmark: (url) ->
    for bookmark, index in bookmarks
      if bookmark.url == url
        bookmarks.splice(index, 1)
        @saveBookmarks()
        return true
    false


  injectDialog: (tab) ->
    dialogHtml = """
      <div id="bookmark_dialog" title="Add a bookmark">
        <label for="bookmark_title">Name</label><br/>
        <input type="text" style="width:250px;" id="ef_bookmark_title" value="#{tab.title}"/>
    </div>
    """.replace(/(\r\n|\n|\r)/gm,"");

    injectScript =
      """
      $(function(){
        $("body").append($('#{dialogHtml}'));
        $('#bookmark_dialog').dialog({
          autoOpen: true,
          width: 300,
          buttons: {
            "Save": function() {
               chrome.extension.sendRequest({'action': 'addBookmark', 'title': $('#ef_bookmark_title').val(), 'url': '#{tab.url}'});
               $(this).dialog("close");
             },
            "Cancel": function() {
              $(this).dialog("close");
            }
          },
          modal: true
        });
      })
      """

    ##console.log("injecting script", injectScript)

    chrome.tabs.executeScript(tab.id, {"file": "js/jquery.min.js"}, ->
      chrome.tabs.executeScript(tab.id, {"file": "js/jquery-ui-1.8.21.custom.min.js"}, ->
        chrome.tabs.insertCSS(tab.id, {"file": "css/Aristo.css"}, ->
          chrome.tabs.executeScript(tab.id, {"code": injectScript})
        )
      )
    )






class ContextMenu
  constructor: (@myBlacklist, @privateBookmarks) ->
    parent = chrome.contextMenus.create({"title": "(surf) shameless"})

    child1 = chrome.contextMenus.create(
      {"title": "Don't log my visits to this site", "parentId": parent, "onclick": @contextMenuAddSite})

    child2 = chrome.contextMenus.create(
      {"title": "Make this a private bookmark", "parentId": parent, "onclick": @addBookmark})

  contextMenuAddSite: (info, tab) ->
    hostname = myBlacklist.addToBlacklist("url", tab.url)
    alert "Added #{hostname} to your blacklist"

  addBookmark: (info, tab) ->
    privateBookmarks.injectDialog(tab)

if localStorage["firstRun"] == undefined
  localStorage["obfuKey"] = CryptoJS.PBKDF2(Math.random().toString(36).substring(2), "efilter", { keySize: 256/32, iterations: 100 }).toString()
  localStorage["firstRun"] = false
  localStorage["opMode"] = 1
  emptyList =
    keywords: []
    urls: []
  localStorage["customBlacklist"] = CryptoJS.AES.encrypt(JSON.stringify(emptyList), localStorage["obfuKey"]).toString()
  localStorage["privateBookmarks"] = CryptoJS.AES.encrypt(JSON.stringify([]), localStorage["obfuKey"], "bookmarks").toString()
  localStorage["totalRemoved"] = 0
  localStorage["password"] = ""
  localStorage["passwordHint"] = ""

if localStorage["setupFinished"] == undefined
  chrome.tabs.create({url: "first_run.html"})

opMode = JSON.parse(localStorage["opMode"]) # 0 - preventive, 1 - retroactive
myBlacklist = new MyBlacklist()
wipeMode = new WipeMode(myBlacklist)
privateBookmarks = new PrivateBookmarks()
contextMenu = new ContextMenu(myBlacklist, privateBookmarks)


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
    #console.log("got request", request)
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
    else if request.action == "addBookmark"
      privateBookmarks.addBookmark(request.title, request.url)
    else if request.action == "rmBookmark"
      privateBookmarks.removeBookmark(request.url)
    else if request.action == "getBookmarks"
      sendResponse(privateBookmarks.getBookmarks())

    #console.log(request)
)