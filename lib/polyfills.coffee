require('es6-promise').polyfill()
xhrc = require 'xmlhttprequest-cookie'
global.XMLHttpRequest = xhrc.XMLHttpRequest
xhrc.CookieJar.load '' # Cookies only last the session.
