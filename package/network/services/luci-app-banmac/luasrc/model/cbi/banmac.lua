m = Map("banmac", translate("BanMac"))

local banlist = m:section(TypedSection, "banlist", translate("Client list"))
    banlist.anonymous = true

local bmdetails = "/etc/banmacdetails"
local BMNXFS = require "nixio.fs"
     o = banlist:option(TextValue, "details")
     o.rows = 6
     o.wrap = "off"
     o.cfgvalue = function(self, section)
     	return BMNXFS.readfile(bmdetails) or ""
     end
     o.write = function(self, section, value)
     	BMNXFS.writefile(bmdetails, value:gsub("\r\n", "\n"))
     end

     o = banlist:option(Value, "banlist_mac", translate("MAC address")) 
        o.rmempty = false
        o.datatype = "macaddr"
        luci.sys.net.mac_hints(function(mac, name)
            o:value(mac, "%s (%s)" %{ mac, name })
        end)

     o = banlist:option(Button, "ban_mac", translate("One-Click BAN")) 
        o.rmempty = false
        o.inputstyle = "apply"
        function o.write(self, section)
            luci.util.exec("/usr/banmac/ban.sh")
        end

     o = banlist:option(Button, "unban_mac", translate("One-Click UnBAN")) 
        o.rmempty = false
        o.inputstyle = "apply"
        function o.write(self, section)
            luci.util.exec("/usr/banmac/unban.sh")
        end

return m

