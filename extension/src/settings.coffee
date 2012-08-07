
$(
  ->

    loadAvailableLists = () ->
      if localStorage["efSettings"] == "undefined" or typeof localStorage["efSettings"] == "undefined"
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
      chrome.extension.sendRequest({"action": "changeListState", "listName": name, "listState": state})

    blacklistReInit = () ->
      chrome.extension.sendRequest({"action": "reInit"})

    listInitializer = () ->
      settings = JSON.parse(localStorage["efSettings"])
      xhr = new XMLHttpRequest()
      console.log("list initializer start")
      for name in settings.myAvailableLists
        xhrs = {}
        xhr.open("GET", "lists/#{name}", false)
        xhr.onreadystatechange = ->
          if xhr.readyState == 4
            listObj = JSON.parse(xhr.responseText)
            checked = ""

            state = false
            if settings.enabledLists
              state = settings.enabledLists[name]
              checked = "checked='checked'" if state
            console.log(listObj)



            descTr =  $("<tr></tr>")
            checkbox = $("<td><input type='checkbox' class='list' name='n_#{name}' list_name='#{name}' #{checked}/> <label for='n_#{name}'>#{listObj.name}</label></td> ")
            desc = $("<td><div id='desc_#{name}'>#{listObj.description}</div></td>")
            descRow = descTr.append(checkbox).append(desc)

            detailTr = $("<tr></tr>")
            detailCols = []
            curCol = 0
            for url in listObj.content
              if detailCols[curCol] == undefined
                detailCols[curCol] = []
              detailCols[curCol].push(url)
              curCol++
              curCol = 0 if curCol == 4

            colsHtml = $("<div id='urls_#{name}' class='urls'></div>")
            toggleBtn = $("""<div class='toggle_urls_btn'>
                              <a href='#'>
                                <img src='images/show.png' class='toggle_urls_icon' />
                                <span class='toggle_urls_caption'>Show list contents</span>
                              </a>
                            </div>""")
            colsHtml.append(toggleBtn)
            for col in detailCols
              urlColumn = "<div class='urls_column'>#{col.join('<br />')}</div>"
              colsHtml.append(urlColumn)

            urls = $("<td colspan='2'></td>").append(colsHtml)
            detailRow = detailTr.append(urls)

            $('#selected_lists > tbody:last').append(descRow)
            $('#selected_lists > tbody:last').append(detailRow)
        xhr.send()


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
          td = $("""<td>
                      <span class='url'>#{item}</span>
                      <a class='remove_#{type}_item' href='javascript:void(0)'>
                        <img src='images/delete.png' />
                      </a>
                    </td>""")
          destination.append(td)
      undefined


    customListAdd = (string, type) ->
      if type == "url"
        customListName = "myCustomUrlList"
      else if type == "keyword"
        customListName = "myCustomKeywordList"

      if localStorage[customListName] == "undefined" or typeof localStorage[customListName] == "undefined" or localStorage[customListName] == undefined
        myCustomList = []
      else
        myCustomList = JSON.parse(localStorage[customListName])
      myCustomList.push(string.replace("http://", "").replace("www.", ""))
      localStorage[customListName] = JSON.stringify(myCustomList)

      blacklistReInit()


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
        localStorage[customListName] = JSON.stringify(myCustomList)

      blacklistReInit()



    $('#nav_tabs').tabs()

    $('.remove_url_item').live('click', ->
      customListRemove($(this).text(), "url")
      $(@).parent().remove()
    )


    $(".list").live("change", ->
      state = $(@).is(':checked')
      changeListState($(@).attr('list_name'), state)
    )

    $('.remove_keyword_item').live('click', ->
      customListRemove($(@).text(), "keyword")
      $(@).parent().remove()
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

    $('.toggle_urls_btn').live( 'click',
      ->
        urlColumns = $(@).parent().children(".urls_column")
        console.log(urlColumns)
        if not urlColumns.is(":visible")
          urlColumns.slideDown()
          $(".toggle_urls_icon", @).attr("src", "images/hide.png")
          $(".toggle_urls_caption", @).text("Hide list contents")
        else
          urlColumns.slideUp()
          $(".toggle_urls_icon", @).attr("src", "images/show.png")
          $(".toggle_urls_caption", @).text("Show list contents")
        false
    )

    $('#lockdown_password').keyup(
      ->
        console.log($(@).val())
        if $(@).val() == "password"
          loadAvailableLists()
          getCustomList("url")
          getCustomList("keyword")
          $("#body_wrapper").show()
          $("#lockdown").hide()
          $(@).remove()
    )
)
