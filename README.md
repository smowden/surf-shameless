Description
===========

The embarassment-filter is a Chrome extension that selectively deletes items from you history.
As of today it comes prepackaged with two lists, one contains medical terms and the other
porn websites. Once you enabled the extension will delete existing items and protect you from new items
showing up in you browser history. In addition to that you can add your own custom keywords and websites
through the settings page.


Simple install (for nontechnical Users)
===========
* Download this archive: https://github.com/codesuela/embarassment-filter/zipball/master
* (or click the ZIP button on the top third of this page)
* Extract the contents to a folder of your choosing
* skip to the "installing" section


Build and install
===========

NOTE:
the latest JS files should be included so if you don't want to build it yourself skip to the "installing" section

Requirements to build:
------------
* node.js
* npm
* Coffeescript
see: http://coffeescript.org/#installation
for more info

Building:
if you have Python on you PC you can run the build.py script in the root directory
otherwise type this into your shell
`coffee -c -o extension/build/ extension/src/`

Installing:
-----------
* To install open Chrome -> Settings
* Check "Developer Mode"
* Click "Load unpacked extension"
* Select the extension folder and click "Open"


Behaviour on various OS
===========

Linux/Chromium (recommended):
-----------------------
This extension was extensively tested by me on Chromium 18.0.1025.168
(Developer Build 134367 Linux) Built on Ubuntu 11.10, running on LinuxMint 12
This is where it works perfect and will not only delete your history but also keep your Omnibox clean

Linux/Chrome:
-----------------------
On Chrome (tested 19.0.1084.56 Ubuntu) this extension will delete unwanted history items and keep your startpage clean.
However due to more aggresive Omnibox caching traces of the visits will remain in the Omnibox (not the history)
in form of the pure url (without a title next to it).
Unfortunately I found no way to remove these traces (within the extension API), they even exist if you block the request
and redirect it to a incognito window. To delete these you have to either wipe your WHOLE history or follow these instructions:
http://superuser.com/a/389660

Windows/Chrome:
-----------------------
Behaves similar to Linux/Chrome, please see above.

OSX/Chrome:
-----------------------
unfortunately untested, would love to hear some feedback

OSX/Chromium:
-----------------------
untested but probably similar to Linux/Chromium



Bugs:
please report bugs via Github, pull requests are also very welcome.
If you wish to join me in working on this extension send me a message or an email to smorra@webhype.me

Copyright by Christian Smorra 2012
PS: I've chosen the GPL license if this is stopping you from doing something cool with this extension let me know.