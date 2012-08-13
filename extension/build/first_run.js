(function() {

  $(function() {
    $(".next_btn").click(function() {
      var curStep, curStepNo, password;
      curStep = $(this).parent().parent();
      curStepNo = parseInt(curStep.attr("step"), 10);
      if (curStepNo === 1) {
        password = $("#ef_password").val();
        if (password.length > 0) {
          localStorage["password"] = CryptoJS.PBKDF2(password, localStorage["obfuKey"], {
            keySize: 256 / 32,
            iterations: 10
          }).toString();
        } else {
          localStorage["password"] = "";
        }
        localStorage["passwordHint"] = $("#ef_hint").val();
        curStep.hide();
        return $("#step2").show();
      } else if (curStepNo === 2) {
        localStorage["allowRemote"] = $("#ef_allow_remote").is(":checked");
        curStep.hide();
        return $("#step3").show();
      }
    });
    return $("#finish").click(function() {
      chrome.tabs.create({
        url: "settings.html"
      });
      return window.close();
    });
  });

}).call(this);
