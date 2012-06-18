
$(
  ->

    loadAvailableLists = () ->
      console.log(localStorage["myAvailableLists"])
      if (localStorage["myAvailableLists"]) == "undefined" or localStorage == undefined
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


    listInitializer = () ->
      xhr = new XMLHttpRequest()
      console.log("list initializer start")
      enabledLists = JSON.parse(localStorage["enabledLists"]) if localStorage["enabledLists"] != undefined
      for name in JSON.parse(localStorage["myAvailableLists"])

        checked = ""
        if enabledLists
          checked = "checked='checked'" if enabledLists.indexOf(name) >= 0

        xhrs = {}
        console.log(xhr.open("GET", "lists/#{name}", false))
        xhr.onreadystatechange = ->
          if xhr.readyState == 4
            listObj = JSON.parse(xhr.responseText)

            state = false
            if enabledLists
              if enabledLists.indexOf(name) >= 0
                state = enabledLists[name]
            console.log(listObj)
            p = $("<p></p>")
            checkbox = $("<input type='checkbox' name='n_#{name}' onchange='changeListState(\"#{name}\", #{!state})' #{checked}/> ")
            label = $("<label for='n_#{name}'>#{listObj.name}</label>")
            urls = $("<div id='urls_#{name}'>#{listObj.content.join("<br />")}</div>")
            desc = $("<div id='desc_#{name}'>#{listObj.description}</div>")
            $("#select_lists").append(p).append(checkbox).append(label).append(urls).append(desc)
        xhr.send()
    loadAvailableLists()


)