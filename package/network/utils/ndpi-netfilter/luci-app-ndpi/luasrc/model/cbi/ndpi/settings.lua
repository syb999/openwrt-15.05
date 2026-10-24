m = Map("ndpi", translate("nDPI application identification"),
	translate("In-kernel application identification provided by kmod-ipt-ndpi. Rules are translated into iptables mangle rules by /etc/init.d/ndpi."))

s = m:section(NamedSection, "config", "ndpi")
s.addremove = false

en = s:option(Flag, "enabled", translate("Enable"))
en.rmempty = false
en.description = translate("Disabling removes the iptables chains created by this app")

fi = s:option(Flag, "flow_info", translate("flow-info connection details"))
fi.rmempty = false
fi.description = translate("Optional per-connection details on the identification page. Not needed for preset or application rules")

function m.on_commit(map)
	luci.sys.call("/etc/init.d/ndpi reload >/dev/null 2>&1")
end

return m
