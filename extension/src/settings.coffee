
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
                                Show list contents
                            </div>""")
            .button(icons: { primary: 'ui-icon-zoomin' })

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
    getCustomList = (gclCallback) ->
      chrome.extension.sendRequest({"action": "getLists"},
        (lists) ->
          for type, listContents of lists
            console.log(type, listContents)
            destination = $("#my_#{type}_inner")
            destination.children().remove()
            for item in listContents
              removeBtn = $("""
                          <a class='remove_#{type.replace("s", "")}_item remove_item' href='#' item='#{item}'>
                            #{item}
                          </a>
                """)
              destination.append(removeBtn)
            $(".remove_item").button(icons: {secondary: "ui-icon-circle-close"})
            if gclCallback
              gclCallback()
      )


    customListAdd = (type, entry) ->
      chrome.extension.sendRequest({"action": "addToBlacklist", "type": type, "entry": entry},
        (response) ->
          getCustomList()
          blacklistReInit()
      )



    customListRemove = (type, entry) ->
      chrome.extension.sendRequest({"action": "rmFromBlacklist", "type": type, "entry": entry},
        (response) ->
          getCustomList()
          blacklistReInit()
      )

    unlock = ->
      loadAvailableLists()
      getCustomList(
        ->
          $("#body_wrapper").show()
          $("#lockdown").hide()
      )



    console.log("password length", localStorage["password"].length)
    if localStorage["password"].length == 0
      console.log("unlocking")
      unlock()

    $('#nav_tabs').tabs()

    $('.remove_url_item').live('click', ->
      customListRemove("url", $(@).attr("item"))
      $(@).remove()
    )


    $(".list").live("change", ->
      state = $(@).is(':checked')
      changeListState($(@).attr('list_name'), state)
    )

    $('.remove_keyword_item').live('click', ->
      customListRemove("keyword", $(@).attr("item"))
      $(@).remove()
    )

    $('#add_new_url').click( ->
      if $('#new_url_add').val().length == 0
        alert("Url field is emptry")
        return false
      customListAdd("url", $('#new_url_add').val())
      getCustomList()
    )
    $('#add_new_keyword').click( ->
      if $('#new_keyword_add').val().length == 0
        alert("Keyword field is emptry")
        return false
      customListAdd("keyword", $('#new_keyword_add').val())
      getCustomList()
    )

    $('.toggle_urls_btn').live( 'click',
      ->
        urlColumns = $(@).parent().children(".urls_column")
        console.log(urlColumns)
        if not urlColumns.is(":visible")
          urlColumns.slideDown()
          $(".ui-icon", @).removeClass("ui-icon-zoomin").addClass("ui-icon-zoomout")
          $(".ui-button-text", @).text("Hide list contents")
        else
          urlColumns.slideUp()
          $(".ui-icon", @).removeClass("ui-icon-zoomout").addClass("ui-icon-zoomin")
          $(".ui-button-text", @).text("Show list contents")
        false
    )

    $('#lockdown_password').keyup(
      ->
        hashedPass = CryptoJS.PBKDF2($(@).val(), localStorage["obfuKey"], { keySize: 256/32, iterations: 10 }).toString()
        if hashedPass == localStorage["password"]
          unlock()
          $(@).remove()
    )

    $('input[type="submit"]').button()
)
