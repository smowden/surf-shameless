
$(
  ->
    getPrivateBookmarks = ->
      chrome.extension.sendRequest({"action": "getBookmarks"},
        (bookmarks) ->
          $("#private_bookmarks").children().remove()
          for bookmark in bookmarks
            bookmarkRepr = """<li class="bookmark">
                        <a href="#{bookmark.url}" target="_blank">#{bookmark.title}</a>
                        </li> """
            $("#private_bookmarks").append(bookmarkRepr)
          $("#lockdown").remove()
      )

    getPrivateBookmarks() if localStorage["password"].length == 0

    $("#password").keyup( ->
      hashedPass = CryptoJS.PBKDF2($(@).val(), localStorage["obfuKey"], { keySize: 256/32, iterations: 10 }).toString()
      if hashedPass == localStorage["password"]
        getPrivateBookmarks()
    )
)