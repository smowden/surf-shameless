interceptSites = ["youjizz.com", "spankwire.com", "webmd.com"]

isBlacklistedUrl = (url) ->
  console.log(url)
  for site in interceptSites
    if url.indexOf("http://www.#{site}") >= 0 or url.indexOf("http://#{site}") >= 0
      return true
  false

interceptRequest = (info) ->
  console.log("intercepted request")
  current_url = info.url

  if isBlacklistedUrl(current_url)
    chrome.windows.create({
      "url": info.url,
      "incognito": true
      },
    () ->
      chrome.tabs.remove(info.tabId)
      console.log("spawned new window")
    )
    return {"cancel": true}
  return undefined


class WipeMode
  openTabs = [] # open tabs are all the tabs whose history should be deleted upon closing all of them
  firstBadTabTime = undefined

  tabAdded: (tabId, changeInfo, tab) ->

    console.log(changeInfo)
    if changeInfo.status == "complete"
      console.log(tab)
    currentUrl = tab.url
    if changeInfo.url
      currentUrl = changeInfo.url

    if isBlacklistedUrl(currentUrl) and openTabs.indexOf(tabId) == -1
      firstBadTabTime = (new Date().getTime() - 10000) if not firstBadTabTime
      # ^ the 10 second difference is to make sure we wont miss anything
      openTabs.push(tabId)
      console.log(tab)
    else if not isBlacklistedUrl(currentUrl) and openTabs.indexOf(tabId) >= 0
      this.tabClosed(tabId)

    console.log(openTabs)

  tabClosed: (tabId) ->
    formerBadTab = openTabs.indexOf(tabId)

    if formerBadTab >= 0
      console.log("tab #{formerBadTab} closed")
      openTabs.splice(formerBadTab, 1)
      if openTabs.length == 0
        this.wipeHistory(firstBadTabTime)
        firstBadTabTime = undefined
      console.log("tabs open "+openTabs.length)

  wipeHistory: (startTime) ->

    startTime = new Date(2010, 0, 1, 0).getTime() if not startTime

    endTime = new Date().getTime()

    maxResults = 1000000000
    chrome.history.search(
      {text: "", startTime: startTime, endTime: endTime, maxResults: maxResults},
      # specifying a text for the search seems to just return completely random results
    (historyItems) ->
      #console.log(historyItems)
      #todo show confirmation promt of some kind before deletion

      for hItem in historyItems
        console.log(isBlacklistedUrl(hItem.url))
        if isBlacklistedUrl(hItem.url)
          chrome.history.deleteUrl({"url": hItem.url})

      console.profileEnd("iterating through history")
      undefined
    )
    undefined

#############################################

wipeMode = new WipeMode()
wipeMode.wipeHistory()
"""


chrome.tabs.onUpdated.addListener(
  (tabId, changeInfo, tab) ->
    wipeMode.tabAdded(tabId, changeInfo, tab)
)

chrome.tabs.onRemoved.addListener(
  (tabId, removeInfo) ->
    wipeMode.tabClosed(tabId)
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