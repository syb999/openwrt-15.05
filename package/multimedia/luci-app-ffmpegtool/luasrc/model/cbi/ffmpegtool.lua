m = Map("ffmpegtool", translate("FFMPEG-Tool"))

m:section(SimpleSection).template  = "ffmpegtool_status"

s = m:section(TypedSection, "ffmpegtool", "", translate("Assistant for FFMPEG"))
s.anonymous = true
s.addremove = false

s:tab("ffmpegbasic", translate("Basic Setting"))

src_select=s:taboption("ffmpegbasic", ListValue, "src_select", translate("Source Select"))
src_select.placeholder = "one file"
src_select:value("one file",translate("one file"))
src_select:value("all files in the directory",translate("all files in the directory"))
src_select.default = "one file"
src_select.rempty  = false

src_file_path=s:taboption("ffmpegbasic", Value, "src_file_path", translate("Source File Path"))
src_file_path:depends( "src_select", "one file" )
src_file_path.rmempty = true
src_file_path.datatype = "string"
src_file_path.default = "/mnt/sda1/input.mp3"

src_directory_path=s:taboption("ffmpegbasic", Value, "src_directory_path", translate("Source Directory Path"))
src_directory_path:depends( "src_select", "all files in the directory" )
src_directory_path.rmempty = true
src_directory_path.datatype = "string"
src_directory_path.default = "/mnt/sda1"

dest_select=s:taboption("ffmpegbasic", ListValue, "dest_select", translate("Destination Select"))
dest_select.placeholder = "directory"
dest_select:value("directory",translate("directory"))
dest_select:value("Sound Card",translate("Sound Card"))
dest_select.default = "directory"
dest_select.rempty  = false

dest_directory_path=s:taboption("ffmpegbasic", Value, "dest_directory_path", translate("Destination Directory Path"))
dest_directory_path:depends( "dest_select", "directory" )
dest_directory_path.rmempty = true
dest_directory_path.datatype = "string"
dest_directory_path.default = "/mnt/sda1"

srcinfo = s:taboption("ffmpegbasic", Button, "srcinfo", translate("One-click Get infomation"))
srcinfo:depends( "audio_ready", "1" )
srcinfo.rmempty = true
srcinfo.inputstyle = "apply"
function srcinfo.write(self, section)
	luci.util.exec("sh /usr/ffmpegtool/getinfo >/dev/null 2>&1 &")
end


s:tab("audio_setting", translate("Audio Setting"))

audio_format=s:taboption("audio_setting", ListValue, "audio_format", translate("Audio format"))
audio_format.placeholder = "mp3"
audio_format:value("mp3")
audio_format:value("m4a")
audio_format:value("wmv")
audio_format:value("aac")
audio_format:value("ts")
audio_format:value("wav")
audio_format.default = "mp3"
audio_format.rempty  = false

sampling_rate=s:taboption("audio_setting", ListValue, "sampling_rate", translate("Sampling rate"))
sampling_rate.placeholder = "none"
sampling_rate:value("none")
sampling_rate:value("44100")
sampling_rate:value("22050")
sampling_rate:value("11025")
sampling_rate.default = "none"
sampling_rate.rempty  = false

audio_channel=s:taboption("audio_setting", ListValue, "audio_channel", translate("Audio channel"))
audio_channel.placeholder = "none"
audio_channel:value("none")
audio_channel:value("1",translate("mono"))
audio_channel:value("2",translate("stereo"))
audio_channel.default = "none"
audio_channel.rempty  = false

a_modify_duration=s:taboption("audio_setting", ListValue, "a_modify_duration", translate("Modify duration"))
a_modify_duration.placeholder = "do not modify"
a_modify_duration:value("do not modify",translate("do not modify"))
a_modify_duration:value("specific time period",translate("specific time period"))
a_modify_duration:value("cut head and tail",translate("cut head and tail"))
a_modify_duration.default = "do not modify"
a_modify_duration.rempty  = false

audio_starttime=s:taboption("audio_setting", Value, "audio_starttime", translate("Start time"))
audio_starttime:depends( "a_modify_duration", "specific time period" )
audio_starttime.datatype = "string"
audio_starttime.placeholder = "00:00:00.00"
audio_starttime.default = "00:00:00.00"
audio_starttime.rmempty = true

audio_endtime=s:taboption("audio_setting", Value, "audio_endtime", translate("End time"))
audio_endtime:depends( "a_modify_duration", "specific time period" )
audio_endtime.datatype = "string"
audio_endtime.placeholder = "00:01:30.00"
audio_endtime.default = "00:01:30.00"
audio_endtime.rmempty = true

audio_headtime=s:taboption("audio_setting", Value, "audio_headtime", translate("cut head"))
audio_headtime:depends( "a_modify_duration", "cut head and tail" )
audio_headtime.datatype = "string"
audio_headtime.placeholder = "15"
audio_headtime.default = "15"
audio_headtime.rmempty = true

audio_tailtime=s:taboption("audio_setting", Value, "audio_tailtime", translate("cut tail"))
audio_tailtime:depends( "a_modify_duration", "cut head and tail" )
audio_tailtime.datatype = "string"
audio_tailtime.placeholder = "10"
audio_tailtime.default = "10"
audio_tailtime.rmempty = true

risingfalling_tone=s:taboption("audio_setting", ListValue, "risingfalling_tone", translate("Rising-Falling tone"))
risingfalling_tone.placeholder = "none"
risingfalling_tone:value("none")
risingfalling_tone:value("sharp",translate("sharp"))
risingfalling_tone:value("rasing whole tone",translate("rasing whole tone"))
risingfalling_tone:value("flat",translate("flat"))
risingfalling_tone:value("falling whole tone",translate("falling whole tone"))
risingfalling_tone.default = "none"
risingfalling_tone.rempty  = false
risingfalling_tone = translate("increase CPU loading")

a_speed_governing=s:taboption("audio_setting", ListValue, "a_speed_governing", translate("Speed governing"))
a_speed_governing.placeholder = "none"
a_speed_governing:value("none")
a_speed_governing:value("0.5")
a_speed_governing:value("1.0")
a_speed_governing:value("1.5")
a_speed_governing:value("2.0")
a_speed_governing.default = "none"
a_speed_governing.rempty  = false
a_speed_governing = translate("increase CPU loading")

volume=s:taboption("audio_setting", ListValue, "volume", translate("Volume"))
volume.placeholder = "none"
volume:value("none")
volume:value("standard")
volume:value("+5dB")
volume:value("-5dB")
volume.default = "none"
volume.rempty  = false
volume = translate("increase CPU loading")

audio_title = s:taboption("audio_setting", Flag, "audio_title", translate("about title"))

audio_addtitle = s:taboption("audio_setting", Flag, "audio_addtitle", translate("set title"))
audio_addtitle:depends( "audio_title", "1" )
audio_addtitle.default = "0"

audio_titleisname = s:taboption("audio_setting", Flag, "audio_titleisname", translate("replace filename with title"))
audio_titleisname:depends( "audio_title", "1" )
audio_titleisname.default = "0"

audio_copy = s:taboption("audio_setting", Flag, "audio_copy", translate("Fast copy"))
audio_copy:depends({ risingfalling_tone = "none", a_speed_governing = "none", volume = "none", audio_title = "", sampling_rate = "none", audio_channel = "none" })

audio_ready = s:taboption("audio_setting", Flag, "audio_ready", translate("Setup ready"))

s:tab("action", translate("Action"))

audioaction = s:taboption("action", Button, "audioaction", translate("One-click Convert Audio"))
audioaction:depends( "audio_ready", "1" )
audioaction.rmempty = true
audioaction.inputstyle = "apply"
function audioaction.write(self, section)
	luci.util.exec("sh /usr/ffmpegtool/audioaction >/dev/null 2>&1 &")
end

audiostop = s:taboption("action", Button, "audiostop", translate("One-click STOP"))
audiostop:depends( "audio_ready", "1" )
audiostop.rmempty = true
audiostop.inputstyle = "apply"
function audiostop.write(self, section)
	luci.util.exec("kill -9 $(busybox ps | grep audioaction | grep -v grep | awk '{print$1}') >/dev/null 2>&1 ")
	luci.util.exec("rm /tmp/ffmpeg.log 2>&1")
end

return m
