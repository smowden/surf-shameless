# todo on first run flush the cache or delete "History Provider Cache" in user folder AND archived history
# todo credit pixture for the icon ( http://www.pixture.com/drupal/ )
interceptSites = ["youjizz.com", "spankwire.com", "webmd.com"]

isBlacklistedUrl = (url) ->
  for site in interceptSites
    if url.indexOf("http://www.#{site}") >= 0 or url.indexOf("http://#{site}") >= 0
      return true
  false

class WipeMode
  openTabs = [] # open tabs are all the tabs whose history should be deleted upon closing all of them
  badRedirects = []
  firstBadTabTime = undefined

  tabAdded: (tabId, changeInfo, tab) ->
    currentUrl = tab.url
    if changeInfo.url
      currentUrl = changeInfo.url

    if isBlacklistedUrl(currentUrl) and openTabs.indexOf(tabId) == -1
      firstBadTabTime = (new Date().getTime() - 10000) if not firstBadTabTime
      # ^ the 10 second difference is to make sure we wont miss anything
      openTabs.push(tabId)
      console.log(openTabs)
    else if not isBlacklistedUrl(currentUrl) and openTabs.indexOf(tabId) >= 0
      @tabClosed(tabId)


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
    if isBlacklistedUrl(details.redirectUrl) and badRedirects.indexOf(details.redirectUrl)
      badRedirects.push(details.url)
      console.log(badRedirects)
    undefined

  wipeHistory: (startTime, doFullClean) ->

    startTime = new Date(2000, 0, 1, 0).getTime() if not startTime

    endTime = new Date().getTime()

    if doFullClean
      for site in interceptSites
        @purgeBadUrl(site)

    maxResults = 1000000000
    chrome.history.search(
      {text: "", startTime: startTime, endTime: endTime, maxResults: maxResults},
      # specifying a text for the search seems to just return completely random results
    (historyItems) =>
      for hItem in historyItems
        if isBlacklistedUrl(hItem.url)
          this.purgeBadUrl(hItem.url)

      for nastyRedirect in badRedirects
        chrome.history.deleteUrl(url: nastyRedirect)

      undefined
    )
    undefined

#############################################


wipeMode = new WipeMode()
wipeMode.wipeHistory(undefined, true)


chrome.tabs.onUpdated.addListener(
    wipeMode.tabAdded
)

chrome.tabs.onRemoved.addListener(
  (tabId, removeInfo) ->
    wipeMode.tabClosed(tabId)
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