
$(
  ->

    loadAvailableLists = () ->
      if localStorage["efSettings"] == "undefined" or typeof localStorage["efSettings"] == "undefined"
        console.log("set timeout")
        chrome.extension.sendRequest({"action": "getAvailableLists"})
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

    getPrivateBookmarks = ->
      chrome.extension.sendRequest({"action": "getBookmarks"},
        (bookmarks) ->
          $("#private_bookmarks").children().remove()
          $("#no_bookmarks_warning").show() if bookmarks.length == 0
          for bookmark in bookmarks
            bookmarkRepr = """<li class="bookmark">
            <a href="#{bookmark.url}" target="_blank">#{bookmark.title}</a>

            <div class="delete_bookmark_icon ui-state-default ui-corner-all">
                         <span class="ui-icon ui-icon-closethick"></span>

            </div>
            </li> """
            $("#private_bookmarks").append(bookmarkRepr)

          $(".delete_bookmark_icon").hover(
            ->
              $(@).addClass('ui-state-hover')
            , ->
              $(@).removeClass('ui-state-hover')
          )
      )

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
          getPrivateBookmarks()
          $("#e_total_count").text(localStorage["totalRemoved"])
          $("#body_wrapper").show()
          $("#lockdown").hide()

          if localStorage["opMode"] == "1"
            $("#op_mode_retroactive").attr("checked", "checked")
          else
            $("#op_mode_preventive").attr("checked", "checked")

          if JSON.parse(localStorage["allowRemote"]) == true
            $("#ef_allow_remote").attr("checked", "checked")
      )

    chrome.extension.onRequest.addListener(
      (request, sender, sendResponse) ->
        console.log(request)
        if request.sAction == "showProgress"

          unless $("#progress_dialog").hasClass("ui-dialog-content")
            $("#progress_dialog").dialog({
              autoOpen: true,
              width: "55em",
              modal: true
            })

          if request.processed >= request.total
            $("#progress_dialog").dialog("close")
          else
            $("#progress_dialog").dialog("open")

          percent = request.processed/(request.total/100)
          $("#progress_total").text(request.total)
          $("#progress_processed").text(request.processed)

          if $("#progress_bar").hasClass("ui-progressbar")
            $("#progress_bar div").width(percent+"%")
          else
            $("#progress_bar").progressbar({value:percent}).width("50em")


    )

    console.log("password length", localStorage["password"].length)
    if localStorage["password"].length == 0
      console.log("unlocking")
      $("#no_password_warning").show()
      unlock()

    $('#nav_tabs').tabs()

    $('.remove_url_item').live('click', ->
      customListRemove("url", $(@).attr("item"))
      $(@).remove()
    )

    $('.delete_bookmark_icon').live("click", ->

      chrome.extension.sendRequest({"action": "rmBookmark", "url": $("a", $(@).parent()).attr("href")})
      $(@).parent().remove()
    )

    $(".list").live("change", ->
      state = $(@).is(':checked')
      changeListState($(@).attr('list_name'), state)
    )

    $('.remove_keyword_item').live('click', ->
      customListRemove("keyword", $(@).attr("item"))
      $(@).remove()
    )

    $('#form_url_add').submit( ->
      if $('#new_url_add').val().length == 0
        alert("Url field is empty")
        return false
      customListAdd("url", $('#new_url_add').val())
      $('#new_url_add').val("")
      getCustomList()
      false
    )
    $('#form_keyword_add').submit( ->
      if $('#new_keyword_add').val().length == 0
        alert("Keyword field is empty")
        return false
      customListAdd("keyword", $('#new_keyword_add').val())
      $('#new_keyword_add').val("")
      getCustomList()
      false
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

    $('#show_hint').click( ->
      if localStorage["passwordHint"].length > 0
        alert localStorage["passwordHint"]
      else
        alert "there is no hint"
    )

    # settings

    $("#ef_allow_remote").change(->
      localStorage["allowRemote"] = JSON.parse($("#ef_allow_remote").is(":checked"))
    )

    $("input[type='radio']").change(->
      opMode = $("input[type='radio']:checked").val()
      if opMode != undefined
        localStorage["opMode"] = parseInt(opMode, 10)
    )

    $("#update_password").click(
      ->
        localStorage["password"] = CryptoJS.PBKDF2($("#new_password").val(), localStorage["obfuKey"], { keySize: 256/32, iterations: 10 }).toString()
        alert("Password changed")
    )


    #lovebox
    rng = Math.random()
    $("#lovebox").show() if rng < 0.22

    $('input[type="submit"]').button()
)
