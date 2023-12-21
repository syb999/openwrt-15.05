#!/usr/bin/lua
--[[
Copyright 2012 Connectify

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
--]]

require("uci")
local signal = require("posix.signal")
intfcfg = {}

function exec (cmd)
    print (cmd)
    return os.execute(cmd)
end

function setRules (operation)
    local x = uci.cursor()
    local qdisc_parent = 0
    local errors = 0

    if ( operation == "del") then
        --remove all rules associated to previously added interfaces
        for k,v in ipairs(intfcfg) do
            tc_str = "tc qdisc del dev "..v.." root"
            exec(tc_str)
        end
        table.remove(intfcfg)
        return
    end

    x:foreach("netem", "interface",
    function (section)

        iface = x:get("netem", section[".name"], "ifname")
        if iface == nil then
            return
        end

        enabled = x:get("netem", section[".name"], "enabled")
        if enabled == "1" then
            qdisc_parent = qdisc_parent + 1
            --keep track of all interfaces where we are adding rules
            table.insert(intfcfg, iface)

            if (operation == "add") then
                --tc_str = "tc qdisc del dev "..iface.." root"
                --exec(tc_str)
                tc_str = "tc qdisc replace dev "..iface.." handle "..qdisc_parent..
                         ": root htb default 11"
                exec(tc_str)
            end

            tc_str = "tc class "..operation.." dev "..iface.." parent "..
                     qdisc_parent..": classid "..qdisc_parent..":1 htb rate 1000Mbit quantum 60000"
            err = exec(tc_str);
            if err ~= 0 then
                errors = errors + 1
                return err
            end

            ratelimit = "1000Mbit"
            rate_control_enabled = x:get("netem", section[".name"], "ratecontrol")
            if rate_control_enabled == "1" then
                ratelimit = x:get("netem", section[".name"], "ratecontrol_rate")
                if ratelimit == nil then
                   ratelimit = 1000000
                end
                ratelimit = ratelimit.."kbit"
            end

            tc_str = "tc class "..operation.." dev "..iface.." parent "..qdisc_parent..
                     ":1 classid "..qdisc_parent..":11 htb rate "..ratelimit.." quantum 60000"
            err = exec(tc_str);
            if err ~= 0 then
                errors = errors + 1
                return err
            end

            last_id = 11
            parent = last_id
            current_id = last_id + 1
            netem_used = 0

            tc_str = "tc qdisc "..operation.." dev "..iface.." parent "..qdisc_parent..
                         ":"..parent.." handle "..current_id..": netem"
            last_id = current_id

            delay_enabled = x:get("netem", section[".name"], "delay")
            if delay_enabled == "1" then
                netem_used = 1
                delay_ms = x:get("netem", section[".name"], "delay_ms")
                if delay_ms == nil then
                    delay_ms = 0
                end
                delay_var = x:get("netem", section[".name"], "delay_var")
                if delay_var == nil then
                    delay_var = 0
                end
                delay_corr = x:get("netem", section[".name"], "delay_corr")
                if delay_corr == nil then
                    delay_corr = 0
                end
                tc_str = tc_str.." delay "..delay_ms.."ms "..delay_var.."ms "..delay_corr.."%"
            end
            
            reorder_enabled = x:get("netem", section[".name"], "reordering")
            if reorder_enabled == "1" then
                netem_used = 1
                reorder_pct = x:get("netem", section[".name"], "reordering_immed_pct")
                if reorder_pct == nil then
                    reorder_pct = 0
                end
                reorder_corr = x:get("netem", section[".name"], "reordering_corr")
                if reorder_corr == nil then
                    reorder_corr = 0
                end
                tc_str = tc_str.." reorder "..reorder_pct.."% "..reorder_corr.."%"
            end

            loss_enabled = x:get("netem", section[".name"], "loss")
            if loss_enabled == "1" then
                netem_used = 1
                loss_pct = x:get("netem", section[".name"], "loss_pct")
                if loss_pct == nil then
                    loss_pct = 0
                end
                loss_corr = x:get("netem", section[".name"], "loss_corr")
                if loss_corr == nil then
                    loss_corr = 0
                end
                tc_str = tc_str.." loss "..loss_pct.."% "..loss_corr.."%"
            end

            dupe_enabled = x:get("netem", section[".name"], "duplication")
            if dupe_enabled == "1" then
                netem_used = 1
                dupe_pct = x:get("netem", section[".name"], "duplication_pct")
                if dupe_pct == nil then
                    dupe_pct = 0
                end
                tc_str = tc_str.." duplicate "..dupe_pct.."%"
            end

            corrupt_enabled = x:get("netem", section[".name"], "corruption")
            if corrupt_enabled == "1" then
                netem_used = 1
                corrupt_pct = x:get("netem", section[".name"], "corruption_pct")
                if corrupt_pct == nil then
                    corrupt_pct = 0
                end
                tc_str = tc_str.." corrupt "..corrupt_pct.."%"
            end

            if netem_used == 0 then
                tc_str = tc_str.." delay 0ms"
            end

            err = exec(tc_str)
            if err ~= 0 then
                errors = errors + 1
                return err
            end
            return 0
        else
            -- blow away the root in case this was enabled, and isn't anymore
            --tc_str = "tc qdisc del dev "..iface.." root"
            --exec(tc_str)
        end
    end)
    return errors
end



signal.signal(signal.SIGTERM, function(signum)
    io.write("\n")
    print ("Unloading WAN Emulation rules...")
    setRules("del")

    os.exit(128 + signum)
end)

print("Loading WAN Emulation rules...")
setRules("add")

--endless loop to keep the service running

while( true )
do
    -- use os sleep to wait and block with low cpu
    os.execute("sleep 1")

end

return