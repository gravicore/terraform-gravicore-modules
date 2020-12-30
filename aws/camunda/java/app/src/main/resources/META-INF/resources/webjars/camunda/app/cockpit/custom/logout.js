const doFetch = window.fetch;
window.fetch = function() {
    // Intercept calling logout
    if (arguments[0] === '/camunda/api/admin/auth/user/default/logout') {
      // do whatever you want to do on logout
      window.location.href = "/logout/oauth2/code/custom"
    } else {
      return doFetch.apply(this, arguments)
    }
}