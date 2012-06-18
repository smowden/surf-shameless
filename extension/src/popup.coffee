$(
  ->
    updatePopup = () ->
      $("#lastCleanupTime").text(humaneDate(JSON.parse(localStorage["popup_lastCleanupTime"])))
      $("#cleanupUrlCounter").text(localStorage["popup_cleanupUrlCounter"])

    setInterval(
      =>
        updatePopup()
      , 500
    )


)

