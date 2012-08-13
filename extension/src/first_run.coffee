$(
  ->
    $(".next_btn").click(
      ->
        curStep = $(@).parent().parent()
        curStepNo = parseInt(curStep.attr("step"), 10)

        if curStepNo == 1
          password = $("#ef_password").val()

          if password.length > 0
            localStorage["password"] = CryptoJS.PBKDF2(password, localStorage["obfuKey"], { keySize: 256/32, iterations: 10 }).toString()
          else
            localStorage["password"] = ""
          localStorage["passwordHint"] = $("#ef_hint").val()

          curStep.hide()
          $("#step2").show()
        else if curStepNo == 2
        else if curStepNo == 3
          localStorage["allowRemote"] = $("#ef_allow_remote").is(":checked")
          curStep.hide()
          $("#step3").show()
    )

    $("#finish").click(
      ->
        chrome.tabs.create({url: "settings.html"})
        window.close()
    )

)