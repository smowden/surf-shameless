
$(
  ->

    loadAvailableLists = () ->
      console.log(localStorage["myAvailableLists"])
      if (localStorage["myAvailableLists"]) == "undefined" or typeof localStorage["myAvailableLists"] == "undefined"
        console.log("set timeout")
        chrome.extension.sendRequest({"action": "getAvailableLists"}, (response) -> console.log("response", response) )
        setTimeout(
          () =>
              loadAvailableLists()
            , 1000
        )
      else
        listInitializer()

    changeListState = (name, state) ->
      chrome.extension.sendRequest({"action": "changeListState", "listName": name, "listState": state},
      (response) -> console.log(response) )


    BlacklistReInit = () ->
      chrome.extension.sendRequest({"action": "reInit"},
      (response) -> console.log(response) )

    listInitializer = () ->
      xhr = new XMLHttpRequest()
      console.log("list initializer start")
      enabledLists = JSON.parse(localStorage["enabledLists"]) if localStorage["enabledLists"] != undefined
      for name in JSON.parse(localStorage["myAvailableLists"])
        xhrs = {}
        xhr.open("GET", "lists/#{name}", false)
        xhr.onreadystatechange = ->
          if xhr.readyState == 4
            listObj = JSON.parse(xhr.responseText)
            checked = ""

            state = false
            if enabledLists
              state = enabledLists[name]
              checked = "checked='checked'" if state
            console.log(listObj)
            tr = $("<tr></tr>")
            checkbox = $("<td><input type='checkbox' class='list' name='n_#{name}' list_name='#{name}' #{checked}/> <label for='n_#{name}'>#{listObj.name}</label></td> ")
            desc = $("<td><div id='desc_#{name}'>#{listObj.description}</div></td>")
            urls = $("<td><div id='urls_#{name}' class='urls'> #{listObj.content.join("<br />")} </div></td>")
            row = tr.append(checkbox).append(desc).append(urls)
            console.log(row)
            $('#selected_lists > tbody:last').append(row);
        xhr.send()
    loadAvailableLists()


    $(".list").live("change", ->
      state = $(@).is(':checked')
      changeListState($(@).attr('list_name'), state)
    )


    # custom list stuff
    getCustomList = (type) ->
      console.log("get custom list called")
      console.log(type)
      if type == "url"
        customListName = "myCustomUrlList"
        destination = $("#my_urls > tbody:last")
      else if type == "keyword"
        customListName = "myCustomKeywordList"
        destination = $("#my_keywords > tbody:last")

      if localStorage[customListName] != "undefined" and typeof(localStorage[customListName]) != "undefined" and localStorage[customListName] != undefined
        for item in JSON.parse(localStorage[customListName])
          td = $("<td><a class='remove_#{type}_item' href='javascript:void(0)'>#{item}</a>  [click to remove] </td>")
          destination.append(td)
      undefined


    getCustomList("url")
    getCustomList("keyword")

    customListAdd = (string, type) ->

      if type == "url"
        customListName = "myCustomUrlList"
      else if type == "keyword"
        customListName = "myCustomKeywordList"

      if localStorage[customListName] == "undefined" or typeof(localStorage[customListName]) == "undefined" or localStorage[customListName] == undefined
        myCustomList = []
      else
        myCustomList = JSON.parse(localStorage[customListName])
      myCustomList.push(string.replace("http://", "").replace("www.", ""))
      localStorage[customListName] = JSON.stringify(myCustomList)

      BlacklistReInit()


    customListRemove = (string, type) ->
      if type == "url"
        customListName = "myCustomUrlList"
      else if type == "keyword"
        customListName = "myCustomKeywordList"

      myCustomList = JSON.parse(localStorage[customListName])
      if myCustomList
        removeItem = string.replace("http://", "").replace("www.", "") if type == "url"
        removeItem = string if type == "keyword"
        listIndex = myCustomList.indexOf(removeItem)
        myCustomList.splice(listIndex, 1)
        if myCustomList.length > 0
          localStorage[customListName] = JSON.stringify(myCustomList)
        else
          localStorage[customListName] = undefined

      BlacklistReInit()




    $('.remove_url_item').live('click', ->
      customListRemove($(this).text(), "url")
      $(this).parent().remove()
    )

    $('.remove_keyword_item').live('click', ->
      customListRemove($(this).text(), "keyword")
      $(this).parent().remove()
    )

    $('#add_new_url').click( ->
      if $('#new_url_add').val().length == 0
        alert("Url field is emptry")
        return false
      customListAdd($('#new_url_add').val(), "url")
      $("#my_urls tbody").html("")
      getCustomList("url")
    )
    $('#add_new_keyword').click( ->
      if $('#new_keyword_add').val().length == 0
        alert("Keyword field is emptry")
        return false
      customListAdd($('#new_keyword_add').val(), "keyword")
      $("#my_keywords tbody").html("")
      getCustomList("keyword")
    )

)
