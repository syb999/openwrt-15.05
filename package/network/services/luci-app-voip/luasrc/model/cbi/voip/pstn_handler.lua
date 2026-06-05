local m = Map("voip", translate("PSTN Incoming Handler"), translate("Configure how to handle incoming PSTN calls"))

local tip = m:section(SimpleSection)
tip.description = '<div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 10px 0;">' .. translate("Choose how to process incoming PSTN calls. Place your .gsm files in the directory specified below. For ringback music use 'ring.gsm', for IVR use 'ivr-welcome.gsm' and 'ivr-invalid.gsm'.") .. '</div>'

local s = m:section(TypedSection, "pstn_handler", translate("PSTN Handler Settings"))
s.anonymous = true

mode = s:option(ListValue, "mode", translate("Incoming Call Mode"))
mode:value("normal", translate("Normal (Standard Ringback)"))
mode:value("direct", translate("Direct Dial with Ringback Music"))
mode:value("ivr", translate("IVR Menu"))
mode.default = "normal"

playback_enabled = s:option(Flag, "playback_enabled", translate("Enable Ringback Music"))
playback_enabled.default = 0
playback_enabled:depends("mode", "direct")

playback_dir = s:option(Value, "playback_dir", translate("Music Directory"))
playback_dir.default = "/usr/share/asterisk/sounds"
playback_dir:depends("mode", "direct")

playback_file = s:option(Value, "playback_file", translate("Music File Name"))
playback_file.default = "ring"
playback_file:depends("mode", "direct")
playback_file.description = translate("GSM file name without extension (e.g., 'ring' for ring.gsm)")

playback_loop = s:option(Value, "playback_loop", translate("Play Loop Count"))
playback_loop.datatype = "uinteger"
playback_loop.default = 1
playback_loop:depends("mode", "direct")
playback_loop.description = translate("Number of times to play the music before dialing (1-6 recommended)")

welcome = s:option(Value, "welcome", translate("Welcome Prompt"))
welcome.default = "ivr-welcome"
welcome:depends("mode", "ivr")
welcome.description = translate("GSM file name without extension (placed in the music directory)")

timeout = s:option(Value, "timeout", translate("Timeout (seconds)"))
timeout.datatype = "uinteger"
timeout.default = 10
timeout:depends("mode", "ivr")

invalid = s:option(Value, "invalid", translate("Invalid Prompt"))
invalid.default = "ivr-invalid"
invalid:depends("mode", "ivr")
invalid.description = translate("GSM file name without extension (placed in the music directory)")

local opt = m:section(TypedSection, "ivr_option", translate("IVR Key Mapping"))
opt.addremove = true
opt.anonymous = true
opt.template = "cbi/tblsection"

digit = opt:option(Value, "digit", translate("Key (0-9)"))
digit.datatype = "range(0,9)"
digit.rmempty = false

action = opt:option(ListValue, "action", translate("Action"))
action:value("extension", translate("Dial Extension"))
action:value("hangup", translate("Hangup"))
action.default = "extension"

target = opt:option(Value, "target", translate("Target"))
target.description = translate("Extension number")

return m
