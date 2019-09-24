--[[
LuCI - Lua Configuration Interface

Description:
Offers an util to resolve extra disk information
]]--


module ("luci.siwifi.sf_disk", package.seeall)

local sysconfig  = require "luci.siwifi.sf_sysconfig"


function getDiskAvaiable()
    return "0"
end

