--[[
LuCI - Lua Configuration Interface

Description:
Offers an util to define siwifi constants
]]--

module ("luci.siwifi.sf_sysconfig", package.seeall)


--[[
 todo:
  resolve siwifi config from uci config file
  module("luci.config",
    function(m)
        if pcall(require, "luci.model.uci") then
        local config = util.threadlocal()
        setmetatable(m, {
            __index = function(tbl, key)
                if not config[key] then
                    config[key] = luci.model.uci.cursor():get_all("luci", key)
                end
                return config[key]
            end
        })
     end
  end)
]]--


--define sys serial no
SYS_SERIAL_NO = "000000000001"

SF_OTA_FLASH= 2
SF_OTA_DEV = 1
SF_OTA_REL = 0
--define bind value
SF_BIND_YET = '1'
SF_BIND_NO = '0'

--siflower server api
FILEUPLOAD = "/file/upload"
ROUTERLOG = "/data/routerLog"
LOOKOTAVERSION = "/lookOtaVersion"
LOOKOTAVERSION2 = "/lookImgVersion"
LOOKOTAVERSIONAP = "/lookImgVersions"
LOOK_PCTL_URL_VERSION = "/cloud/downloadMonitoredIP"
