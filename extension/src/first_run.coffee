$(
  ->

    $(".next_btn").button().click(
      ->
        curStep = $(@).parent()
        curStepNo = parseInt(curStep.attr("step"), 10)
        console.log("cur step no", curStepNo)


        if curStepNo == 1
          password = $("#ef_password").val()

          if password.length > 0
            localStorage["password"] = CryptoJS.PBKDF2(password, localStorage["obfuKey"], { keySize: 256/32, iterations: 10 }).toString()
          else
            localStorage["password"] = ""
          localStorage["passwordHint"] = $("#ef_hint").val()

        else if curStepNo == 2
          opMode = $("#step2 input[type='radio']:checked").val()
          console.log("op mode", opMode)
          if opMode != undefined
            localStorage["opMode"] = parseInt(opMode, 10)
          else
            return alert("please select a mode of operation")
        else if curStepNo == 3
          localStorage["allowRemote"] = $("#ef_allow_remote").is(":checked")

        curStep.hide()
        $("#step#{(curStepNo+1)}").show()
    )

    $("#finish").click(
      ->
        chrome.tabs.create({url: "settings.html"})
        window.close()
    )

)