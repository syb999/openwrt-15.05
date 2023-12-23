--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2012 Connectify <bprodoehl@connectify.me>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
]]--

module("luci.controller.netem", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/netem") then
        return
    end

    local page

    page = entry({"admin", "network", "netem"}, cbi("netem/netem"), _("Network Emulation"))
    page.i18n = "netem"
    page.dependent = true

    page = entry({"mini", "network", "netem"}, cbi("netem/netemmini", {autoapply=true}), _("Network Emulation"))
    page.i18n = "netem"
    page.dependent = true
end

