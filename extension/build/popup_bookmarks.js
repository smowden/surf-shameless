(function() {

  $(function() {
    var getPrivateBookmarks;
    getPrivateBookmarks = function() {
      return chrome.extension.sendRequest({
        "action": "getBookmarks"
      }, function(bookmarks) {
        var bookmark, bookmarkRepr, _i, _len;
        $("#private_bookmarks").children().remove();
        for (_i = 0, _len = bookmarks.length; _i < _len; _i++) {
          bookmark = bookmarks[_i];
          bookmarkRepr = "<li class=\"bookmark\">\n<a href=\"" + bookmark.url + "\" target=\"_blank\">" + bookmark.title + "</a>\n</li> ";
          $("#private_bookmarks").append(bookmarkRepr);
        }
        return $("#lockdown").remove();
      });
    };
    if (localStorage["password"].length === 0) getPrivateBookmarks();
    return $("#password").keyup(function() {
      var hashedPass;
      hashedPass = CryptoJS.PBKDF2($(this).val(), localStorage["obfuKey"], {
        keySize: 256 / 32,
        iterations: 10
      }).toString();
      if (hashedPass === localStorage["password"]) return getPrivateBookmarks();
    });
  });

}).call(this);
