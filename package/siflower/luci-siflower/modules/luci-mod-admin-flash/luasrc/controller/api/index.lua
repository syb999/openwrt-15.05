module("luci.controller.api.index", package.seeall)
function index()
    local page   = node("api")
    page.target  = firstchild()
    page.title   = _("")
    page.order   = 12
    page.index = true
end
