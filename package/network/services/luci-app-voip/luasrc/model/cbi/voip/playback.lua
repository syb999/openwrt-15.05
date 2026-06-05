local m = Map("voip", translate("Ringback Music"), translate("Configure ringback music played to callers while waiting"))

local tip = m:section(SimpleSection)
tip.description = '<div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 10px 0;">' .. translate("This feature plays music to the calling party while waiting for the called party to answer. Place your .gsm file in the specified directory.") .. '</div>'

local s = m:section(TypedSection, "playback", translate("Ringback Music Settings"))
s.anonymous = true

enabled = s:option(Flag, "enabled", translate("Enable Ringback Music"))
enabled.default = 0
enabled.description = translate("Play music to callers while waiting for answer")

playback_dir = s:option(Value, "dir", translate("Music Directory"))
playback_dir.default = "/tmp/playback"
playback_dir.description = translate("Directory containing .gsm audio file")

playback_file = s:option(Value, "file", translate("Music File Name"))
playback_file.default = "ring"
playback_file.description = translate("GSM file name without extension (e.g., 'ring' for ring.gsm)")

playback_loop = s:option(Value, "loop", translate("Play Loop Count"))
playback_loop.datatype = "uinteger"
playback_loop.default = 1
playback_loop.description = translate("Number of times to play the music before dialing (1-6 recommended)")

return m
