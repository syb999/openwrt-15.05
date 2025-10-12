m = Map("ffmpegtool", translate("FFMPEG-Tool"))
m.description = translate("Tips 1: add LOGO command\(for PC\): ffmpeg -i input.mp4 -vf \"movie=logo.png[wm];[in][wm]overlay=30:15[out]\" output.mp4")

m:section(SimpleSection).template  = "ffmpegtool_status"

s = m:section(TypedSection, "ffmpegtool", "", translate("Assistant for FFMPEG"))
s.anonymous = true
s.addremove = false
s.description = translate("Tips 2: add subtitles command\(for PC\): ffmpeg -i input.mp4 -vf subtitles=1.srt output.mp4")

s:tab("ffmpegbasic", translate("Basic Setting"))

src_select=s:taboption("ffmpegbasic", ListValue, "src_select", translate("Source Select"))
src_select.placeholder = "one file"
src_select:value("one file",translate("one file"))
src_select:value("all files in the directory",translate("all files in the directory"))
src_select:value("streaming media",translate("streaming media"))
src_select:value("microphone",translate("microphone"))
src_select.default = "one file"
src_select.rempty  = false

micro_about = s:taboption("ffmpegbasic", DummyValue, "micro_about", translate("About microphone"))
micro_about:depends( "src_select", "microphone" )
micro_about.description = translate("The same sound card needs to be selected for simultaneous acquisition and playback")

switchcard1 = s:taboption("ffmpegbasic", Button, "switchcard1", translate("switch to card1"))
switchcard1:depends( "src_select", "microphone" )
switchcard1.rmempty = true
switchcard1.inputstyle = "apply"
function switchcard1.write(self, section)
	luci.util.exec("echo \"defaults.pcm.card 1\" > /etc/asound.conf &")
end
switchcard1.description = translate("switch the sound card connected to the microphone")

switchcard0 = s:taboption("ffmpegbasic", Button, "switchcard0", translate("switch to card0"))
switchcard0:depends( "src_select", "microphone" )
switchcard0.rmempty = true
switchcard0.inputstyle = "apply"
function switchcard0.write(self, section)
	luci.util.exec("echo \"defaults.pcm.card 0\" > /etc/asound.conf &")
end
switchcard0.description = translate("switch the sound card connected to the microphone")

src_file_path=s:taboption("ffmpegbasic", Value, "src_file_path", translate("Source File"))
src_file_path:depends( "src_select", "one file" )
src_file_path.rmempty = true
src_file_path.datatype = "string"
src_file_path.default = "/mnt/sda1/input.mp3"
src_file_path.description = translate("please input audio/video/picture file fullpath")

src_directory_path=s:taboption("ffmpegbasic", Value, "src_directory_path", translate("Source Directory"))
src_directory_path:depends( "src_select", "all files in the directory" )
src_directory_path.rmempty = true
src_directory_path.datatype = "string"
src_directory_path.default = "/mnt/sda1"
src_directory_path.description = translate("please input directory path")

src_stream_path=s:taboption("ffmpegbasic", Value, "src_stream_path", translate("Streaming media url"))
src_stream_path:depends( "src_select", "streaming media" )
src_stream_path.rmempty = true
src_stream_path.datatype = "string"
src_stream_path.default = "rtmp://ip:1935/stream"
src_stream_path.description = translate("like rtmp,m3u8 and so on")

dest_select=s:taboption("ffmpegbasic", ListValue, "dest_select", translate("Destination Select"))
dest_select.placeholder = "directory"
dest_select:value("directory",translate("directory"))
dest_select:value("Sound Card",translate("Sound Card"))
dest_select:value("streaming media server",translate("streaming media server"))
dest_select.default = "directory"
dest_select.rempty  = false

streamserver_select=s:taboption("ffmpegbasic", ListValue, "streamserver_select", translate("Select stream server"))
streamserver_select:depends( "dest_select", "streaming media server" )
streamserver_select:value("none")
streamserver_select:value("rtmp server",translate("rtmp server"))
streamserver_select:value("icecast server",translate("icecast server"))
streamserver_select.default = "none"
streamserver_select.rempty  = false
streamserver_select.description = translate("recurrently push to stream media server")

rtmp_server_url=s:taboption("ffmpegbasic", Value, "rtmp_server_url", translate("rtmp server url"))
rtmp_server_url:depends( "streamserver_select", "rtmp server" )
rtmp_server_url.rmempty = true
rtmp_server_url.datatype = "string"
rtmp_server_url.placeholder = "rtmp://ip:1935/stream"
rtmp_server_url.default = "rtmp://ip:1935/stream"

icecast_server_url=s:taboption("ffmpegbasic", Value, "icecast_server_url", translate("icecast server url"))
icecast_server_url:depends( "streamserver_select", "icecast server" )
icecast_server_url.rmempty = true
icecast_server_url.datatype = "string"
icecast_server_url.placeholder = "icecast://source:hackme@ip:port/stream"
icecast_server_url.default = "icecast://source:hackme@ip:port/stream"

dest_directory_path=s:taboption("ffmpegbasic", Value, "dest_directory_path", translate("Destination Directory Path"))
dest_directory_path:depends( "dest_select", "directory" )
dest_directory_path.rmempty = true
dest_directory_path.datatype = "string"
dest_directory_path.default = "/mnt/sda1"
dest_directory_path.description = translate("do not be the same as the source directory")

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

audio_add_silence=s:taboption("audio_setting", Flag, "audio_add_silence", translate("add silence at the beginning"))
audio_add_silence.default = ""
audio_add_silence.rmempty = true

audio_silence_duration = s:taboption("audio_setting", Value, "audio_silence_duration", translate("silent duration"))
audio_silence_duration:depends( "audio_add_silence", "1" )
audio_silence_duration.datatype = "uinteger"
audio_silence_duration.placeholder = "5000"
audio_silence_duration.default = "5000"
audio_silence_duration.rmempty = true
audio_silence_duration.description = translate("5000 is 5 seconds")

audio_sept=s:taboption("audio_setting", Flag, "audio_separate", translate("separate audio"))
audio_sept.default = ""

audio_sept_silence=s:taboption("audio_setting", Flag, "audio_sept_silence", translate("separate audio by silencedetect"))
audio_sept_silence:depends( "audio_separate", "" )
audio_sept_silence = ""

audio_sept_silence_input = s:taboption("audio_setting", Value, "audio_sept_silence_input", translate("the original file to be separated"))
audio_sept_silence_input:depends( "audio_sept_silence", "1" )
audio_sept_silence_input.datatype = "string"
audio_sept_silence_input.placeholder = "/mnt/sda1/input.mp3"
audio_sept_silence_input.default = "/mnt/sda1/input.mp3"
audio_sept_silence_input.rmempty = true

audio_sept_silence_threshold = s:taboption("audio_setting", Value, "audio_sept_silence_threshold", translate("threshold level"))
audio_sept_silence_threshold:depends( "audio_sept_silence", "1" )
audio_sept_silence_threshold.datatype = "string"
audio_sept_silence_threshold.placeholder = "-45dB"
audio_sept_silence_threshold.default = "-45dB"
audio_sept_silence_threshold.rmempty = true

audio_sept_silence_duration = s:taboption("audio_setting", Value, "audio_sept_silence_duration", translate("silence duration"))
audio_sept_silence_duration:depends( "audio_sept_silence", "1" )
audio_sept_silence_duration.datatype = "string"
audio_sept_silence_duration.placeholder = "2.5"
audio_sept_silence_duration.default = "2.5"
audio_sept_silence_duration.rmempty = true

audio_sept_input = s:taboption("audio_setting", Value, "audio_sept_input", translate("the original file to be separated"))
audio_sept_input:depends( "audio_separate", "1" )
audio_sept_input.datatype = "string"
audio_sept_input.placeholder = "/mnt/sda1/input.mp3"
audio_sept_input.default = "/mnt/sda1/input.mp3"
audio_sept_input.rmempty = true

audio_sept_segment = s:taboption("audio_setting", Value, "audio_sept_segment", translate("segment duration"))
audio_sept_segment:depends( "audio_separate", "1" )
audio_sept_segment.datatype = "string"
audio_sept_segment.placeholder = "5:01,3:02,6:03"
audio_sept_segment.default = ""
audio_sept_segment.rmempty = true
audio_sept_segment.description = translate("Please enter the duration of each segmented audio in sequence")

audio_sept_timespinner = s:taboption("audio_setting", Value, "audio_sept_timespinner", translate("timespinner"))
audio_sept_timespinner:depends( "audio_separate", "1" )
audio_sept_timespinner.datatype = "uinteger"
audio_sept_timespinner.placeholder = "0"
audio_sept_timespinner.default = "0"
audio_sept_timespinner.rmempty = true

audio_merge=s:taboption("audio_setting", Flag, "audio_merge", translate("combine audio"))
audio_merge:depends( "audio_copy", "" )
audio_merge.default = ""

enable_amix=s:taboption("audio_setting", ListValue, "enable_amix", translate("enable merge"))
enable_amix:depends( "audio_merge", "1" )
enable_amix:value("one by one",translate("one by one"))
enable_amix:value("mix1",translate("Mixes 2 audio inputs into a single output"))
enable_amix:value("mix2",translate("After merging the two stereo audio channels into single channels, mix them according to the left and right channels"))
enable_amix:value("mix3",translate("Merge 2 single channel audio into one stereo by combining left and right channels"))
enable_amix:value("mix4",translate("When splicing two audio tracks, add a silent track in the middle (default 5 seconds)"))
enable_amix.default = "one by one"
enable_amix.rempty  = true

audio_null = s:taboption("audio_setting", Value, "audio_null", translate("Silent track duration in seconds"))
audio_null:depends( "enable_amix", "mix4" )
audio_null.datatype = "uinteger"
audio_null.placeholder = "5"
audio_null.default = "5"
audio_null.rmempty = true

audio_input1 = s:taboption("audio_setting", Value, "audio_input1", translate("The first file to be merged"))
audio_input1:depends( "audio_merge", "1" )
audio_input1.datatype = "string"
audio_input1.placeholder = "/mnt/sda1/input1.mp3"
audio_input1.default = "/mnt/sda1/input1.mp3"
audio_input1.rmempty = true

audio_input2 = s:taboption("audio_setting", Value, "audio_input2", translate("The second file to be merged"))
audio_input2:depends( "audio_merge", "1" )
audio_input2.datatype = "string"
audio_input2.placeholder = "/mnt/sda1/input2.mp3"
audio_input2.default = "/mnt/sda1/input2.mp3"
audio_input2.rmempty = true

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
risingfalling_tone:value("sharp(44100Hz)",translate("sharp(44100Hz)"))
risingfalling_tone:value("sharp(22050Hz)",translate("sharp(22050Hz)"))
risingfalling_tone:value("rasing whole tone(44100Hz)",translate("rasing whole tone(44100Hz)"))
risingfalling_tone:value("rasing whole tone(22050Hz)",translate("rasing whole tone(22050Hz)"))
risingfalling_tone:value("flat(44100Hz)",translate("flat(44100Hz)"))
risingfalling_tone:value("flat(22050Hz)",translate("flat(22050Hz)"))
risingfalling_tone:value("falling whole tone(44100Hz)",translate("falling whole tone(44100Hz)"))
risingfalling_tone:value("falling whole tone(22050Hz)",translate("falling whole tone(22050Hz)"))
risingfalling_tone:value("special-1(44100Hz)",translate("special-1(44100Hz)"))
risingfalling_tone:value("special-1(22050Hz)",translate("special-1(22050Hz)"))
risingfalling_tone:value("special-2(44100Hz)",translate("special-2(44100Hz)"))
risingfalling_tone:value("special-2(22050Hz)",translate("special-2(22050Hz)"))
risingfalling_tone.default = "none"
risingfalling_tone.rempty  = false
risingfalling_tone.description = translate("increase CPU loading")

a_speed_governing=s:taboption("audio_setting", ListValue, "a_speed_governing", translate("Speed governing"))
a_speed_governing.placeholder = "none"
a_speed_governing:value("none")
a_speed_governing:value("0.2")
a_speed_governing:value("0.5")
a_speed_governing:value("0.8")
a_speed_governing:value("1.0")
a_speed_governing:value("1.1")
a_speed_governing:value("1.2")
a_speed_governing:value("1.3")
a_speed_governing:value("1.4")
a_speed_governing:value("1.5")
a_speed_governing:value("1.6")
a_speed_governing:value("1.7")
a_speed_governing:value("1.8")
a_speed_governing:value("1.9")
a_speed_governing:value("2.0")
a_speed_governing.default = "none"
a_speed_governing.rempty  = false
a_speed_governing.description = translate("increase CPU loading")

volume=s:taboption("audio_setting", ListValue, "volume", translate("Volume"))
volume.placeholder = "none"
volume:value("none")
volume:value("standard")
volume:value("+15dB")
volume:value("+10dB")
volume:value("+5dB")
volume:value("-5dB")
volume:value("-10dB")
volume:value("0.2")
volume:value("0.5")
volume:value("1.5")
volume.default = "none"
volume.rempty  = false
volume.description = translate("increase CPU loading")

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
audio_ready.description = translate("Save/apply first please")

s:tab("video_setting", translate("Video Setting"))
video_format=s:taboption("video_setting", ListValue, "video_format", translate("Video format"))
video_format.placeholder = "mp4"
video_format:value("mp4")
video_format:value("mkv")
video_format:value("avi")
video_format:value("wmv")
video_format:value("ts")
video_format:value("flv")
video_format:value("3gp")
video_format.default = "mp4"
video_format.rempty  = false

video_preset=s:taboption("video_setting", ListValue, "video_preset", translate("Preset"))
video_preset.placeholder = "ultrafast"
video_preset:value("ultrafast")
video_preset:value("fast")
video_preset:value("medium")
video_preset.default = "ultrafast"
video_preset.rempty  = false
video_preset.description = translate("Choseing ultrafast that can reduce CPU usage. PS: medium is default setting")

video_adjustspeed = s:taboption("video_setting", Flag, "video_adjustspeed", translate("adjust the playback speed"))
video_adjustspeed:depends({ video_x2645 = "none", image_effects = "", screen_merge = "", video_picture = "", picture_tovideo = "" })

list_adjustspeed=s:taboption("video_setting", ListValue, "list_adjustspeed", translate("speed list"))
list_adjustspeed:depends( "video_adjustspeed", "1" )
list_adjustspeed:value("0.5",translate("speed up by two times"))
list_adjustspeed:value("2",translate("reduce the speed by two times"))
list_adjustspeed:value("3",translate("reduce the speed by three times"))
list_adjustspeed.default = "2"
list_adjustspeed.rempty  = true

video_x2645=s:taboption("video_setting", ListValue, "video_x2645", translate("using libx264/libx265"))
video_x2645:value("none")
video_x2645:value("libx264")
video_x2645:value("libx265")
video_x2645.description = translate("increase CPU loading")

image_effects=s:taboption("video_setting", Flag, "image_effects", translate("image effects"))
image_effects:depends({ screen_merge = "", video_adjustspeed = "", video_expan = "" })
image_effects.description = translate("increase CPU loading when open")

video_horizontally = s:taboption("video_setting", Flag, "video_horizontally", translate("flip image horizontally"))
video_horizontally:depends( "image_effects", "1" )

video_upanddown = s:taboption("video_setting", Flag, "video_upanddown", translate("flip image up and down"))
video_upanddown:depends( "image_effects", "1" )

video_rotation = s:taboption("video_setting", Flag, "video_rotation", translate("image rotation 90 degrees"))
video_rotation:depends( "image_effects", "1" )

horizontal_symmetrical = s:taboption("video_setting", Flag, "horizontal_symmetrical", translate("image horizontal symmetrical"))
horizontal_symmetrical:depends( "image_effects", "1" )

vertically_symmetrical = s:taboption("video_setting", Flag, "vertically_symmetrical", translate("image vertically symmetrical"))
vertically_symmetrical:depends( "image_effects", "1" )

fuzzy_processing = s:taboption("video_setting", Flag, "fuzzy_processing", translate("fuzzy processing"))
fuzzy_processing:depends( "image_effects", "1" )

crisp_enhancement = s:taboption("video_setting", Flag, "crisp_enhancement", translate("crisp enhancement"))
crisp_enhancement:depends( "image_effects", "1" )

video_halfsize = s:taboption("video_setting", Flag, "video_halfsize", translate("a half of screensize"))
video_halfsize:depends( "image_effects", "1" )

video_clipping = s:taboption("video_setting", Flag, "video_clipping", translate("screen clipping"))
video_clipping:depends( "image_effects", "1" )

video_crop = s:taboption("video_setting", Value, "video_crop", translate("capture the screen of the specified size and location"))
video_crop:depends( "video_clipping", "1" )
video_crop.datatype = "string"
video_crop.placeholder = "crop=iw:ih/2:0:100"
video_crop.default = "crop=iw:ih/2:0:100"
video_crop.rmempty = true
video_crop.description = translate("default set is capture 100% width and 50% heigh from the topleft (0,100) pixel")

video_blackandwhite = s:taboption("video_setting", Flag, "video_blackandwhite", translate("black-and-white"))
video_blackandwhite:depends( "image_effects", "1" )

video_separate = s:taboption("video_setting", Flag, "video_separate", translate("separate scenes"))
video_separate:depends( "image_effects", "1" )

video_separate_direction = s:taboption("video_setting", ListValue, "video_separate_direction", translate("separate direction"))
video_separate_direction:depends( "video_separate", "1" )
video_separate_direction:value("vertical",translate("vertical"))
video_separate_direction:value("horizontal",translate("horizontal"))
video_separate_direction.default = "vertical"
video_separate_direction.rempty  = true

video_separate_size = s:taboption("video_setting", Value, "video_separate_size", translate("width of dividing line"))
video_separate_size:depends( "video_separate", "1" )
video_separate_size.datatype = "uinteger"
video_separate_size.placeholder = "20"
video_separate_size.default = "20"
video_separate_size.rmempty = true

video_separate_color = s:taboption("video_setting", ListValue, "video_separate_color", translate("separate line color"))
video_separate_color:depends( "video_separate", "1" )
video_separate_color:value("black",translate("black"))
video_separate_color:value("white",translate("white"))
video_separate_color:value("red",translate("red"))
video_separate_color:value("green",translate("green"))
video_separate_color:value("blue",translate("blue"))
video_separate_color:value("yellow",translate("yellow"))
video_separate_color:value("pink",translate("pink"))
video_separate_color:value("grey",translate("grey"))
video_separate_color:value("orange",translate("orange"))
video_separate_color:value("purple",translate("purple"))
video_separate_color:value("cyan",translate("cyan"))
video_separate_color.default = "black"
video_separate_color.rempty  = true

video_separate_color_transparency = s:taboption("video_setting", ListValue, "video_separate_color_transparency", translate("transparency list"))
video_separate_color_transparency:depends( "video_separate", "1" )
video_separate_color_transparency:value("@1",translate("off"))
video_separate_color_transparency:value("@0.8",translate("little"))
video_separate_color_transparency:value("@0.5",translate("half"))
video_separate_color_transparency:value("@0.2",translate("almost"))
video_separate_color_transparency.default = "@1"
video_separate_color_transparency.rempty  = true

video_expan = s:taboption("video_setting", Flag, "video_expan", translate("expand canvas"))
video_expan:depends({ screen_merge = "", video_adjustspeed = "", image_effects = "" })
video_expan.description = translate("significantly solves the scale imbalance caused by changing the resolution after filling with the extended canvas")

video_expand_direction = s:taboption("video_setting", ListValue, "video_expand_direction", translate("expand direction"))
video_expand_direction:depends( "video_expan", "1" )
video_expand_direction:value("left and right",translate("left and right"))
video_expand_direction:value("top and bottom",translate("top and bottom"))
video_expand_direction.default = "left and right"
video_expand_direction.rempty  = true

video_expand_size = s:taboption("video_setting", Value, "video_expand_size", translate("increased pixels on the canvas"))
video_expand_size:depends( "video_expan", "1" )
video_expand_size.datatype = "uinteger"
video_expand_size.placeholder = "420"
video_expand_size.default = "420"
video_expand_size.rmempty = true

video_expand_color = s:taboption("video_setting", ListValue, "video_expand_color", translate("canvas color"))
video_expand_color:depends( "video_expan", "1" )
video_expand_color:value("black",translate("black"))
video_expand_color:value("white",translate("white"))
video_expand_color:value("red",translate("red"))
video_expand_color:value("green",translate("green"))
video_expand_color:value("blue",translate("blue"))
video_expand_color:value("yellow",translate("yellow"))
video_expand_color:value("pink",translate("pink"))
video_expand_color:value("grey",translate("grey"))
video_expand_color:value("orange",translate("orange"))
video_expand_color:value("purple",translate("purple"))
video_expand_color:value("cyan",translate("cyan"))
video_expand_color.default = "black"
video_expand_color.rempty  = true

screen_merge=s:taboption("video_setting", Flag, "screen_merge", translate("screen merge"))
screen_merge.default = ""
screen_merge:depends({ image_effects = "", video_adjustspeed = "" })
screen_merge.description = translate("only modification duration is supported")

enable_merge=s:taboption("video_setting", ListValue, "enable_merge", translate("enable merge"))
enable_merge:depends( "screen_merge", "1" )
enable_merge:value("left and right",translate("left and right"))
enable_merge:value("top and bottom",translate("top and bottom"))
enable_merge:value("one by one",translate("one by one"))
enable_merge:value("merge video and audio",translate("merge video and audio"))
enable_merge:value("merge video to picture",translate("merge video to picture"))
enable_merge:value("merge picture onto video",translate("merge picture onto video"))
enable_merge:value("overlay in the middle",translate("overlay in the middle"))
enable_merge:value("custom overley",translate("custom overley"))
enable_merge.default = "left and right"
enable_merge.rempty  = true

picture_merge=s:taboption("video_setting", ListValue, "picture_merge", translate("merge video to picture"))
picture_merge:depends( "enable_merge", "merge video to picture" )
picture_merge:value("none")
picture_merge:value("one video and one picture",translate("one video and one picture"))
picture_merge:value("two videos and one picture",translate("two videos and one picture"))
picture_merge.default = "none"
picture_merge.rempty  = true

screen_input1 = s:taboption("video_setting", Value, "screen_input1", translate("The first file to be merged"))
screen_input1:depends( "screen_merge", "1" )
screen_input1.datatype = "string"
screen_input1.placeholder = "/mnt/sda1/input1.mp4"
screen_input1.default = "/mnt/sda1/input1.mp4"
screen_input1.rmempty = true

screen_input2 = s:taboption("video_setting", Value, "screen_input2", translate("The second file to be merged"))
screen_input2:depends( "screen_merge", "1" )
screen_input2.datatype = "string"
screen_input2.placeholder = "/mnt/sda1/input2.mp4"
screen_input2.default = "/mnt/sda1/input2.mp4"
screen_input2.rmempty = true

screen_picture = s:taboption("video_setting", Value, "screen_picture", translate("The picture file to be merged"))
screen_picture:depends( "enable_merge", "merge video to picture" )
screen_picture.datatype = "string"
screen_picture.placeholder = "/mnt/sda1/input.jpg"
screen_picture.default = "/mnt/sda1/input.jpg"
screen_picture.rmempty = true

picture_custom_1 = s:taboption("video_setting", Value, "picture_custom_1", translate("modify the screen resolution of input1 video"))
picture_custom_1:depends( "enable_merge", "merge video to picture" )
picture_custom_1.datatype = "string"
picture_custom_1.placeholder = "800:-1"
picture_custom_1.default = "800:-1"
picture_custom_1.rmempty = true
picture_custom_1.description = translate("800:-1 means: width 800, height adaptive correction")

picture_custom_2 = s:taboption("video_setting", Value, "picture_custom_2", translate("modify the screen resolution of input2 video"))
picture_custom_2:depends( "picture_merge", "two videos and one picture" )
picture_custom_2.datatype = "string"
picture_custom_2.placeholder = "320:-1"
picture_custom_2.default = "320:-1"
picture_custom_2.rmempty = true
picture_custom_2.description = translate("320:-1 means: width 320, height adaptive correction")

picture_custom_3 = s:taboption("video_setting", Value, "picture_custom_3", translate("vertex coordinates of superimposed input1 video"))
picture_custom_3:depends( "enable_merge", "merge video to picture" )
picture_custom_3.datatype = "string"
picture_custom_3.placeholder = "100:0"
picture_custom_3.default = "100:0"
picture_custom_3.rmempty = true
picture_custom_3.description = translate("100:0 means:the pixel at coordinates 100,0")

picture_custom_4 = s:taboption("video_setting", Value, "picture_custom_4", translate("vertex coordinates of superimposed input2 video"))
picture_custom_4:depends( "picture_merge", "two videos and one picture" )
picture_custom_4.datatype = "string"
picture_custom_4.placeholder = "120:20"
picture_custom_4.default = "120:20"
picture_custom_4.rmempty = true
picture_custom_4.description = translate("120:20 means:the pixel at coordinates 120,20")

picture_merge_new=s:taboption("video_setting", ListValue, "picture_merge_new", translate("merge picture onto video"))
picture_merge_new:depends( "enable_merge", "merge picture onto video" )
picture_merge_new:value("one video and one picture",translate("one video and one picture"))
picture_merge_new.default = "one video and one picture"
picture_merge_new.rempty  = true
picture_merge_new.description = translate("overlay the picture onto the designated coordinates of the video")

merge_new_input1 = s:taboption("video_setting", Value, "merge_new_input1", translate("video file"))
merge_new_input1:depends( "picture_merge_new", "one video and one picture" )
merge_new_input1.datatype = "string"
merge_new_input1.placeholder = "/mnt/sda1/input1.mp4"
merge_new_input1.default = "/mnt/sda1/input1.mp4"
merge_new_input1.rmempty = true

merge_new_input2 = s:taboption("video_setting", Value, "merge_new_input2", translate("picture file"))
merge_new_input2:depends( "picture_merge_new", "one video and one picture" )
merge_new_input2.datatype = "string"
merge_new_input2.placeholder = "/mnt/sda1/input2.png"
merge_new_input2.default = "/mnt/sda1/input2.png"
merge_new_input2.rmempty = true

merge_new_coordinate = s:taboption("video_setting", Value, "merge_new_coordinate", translate("overlay coordinate"))
merge_new_coordinate:depends( "picture_merge_new", "one video and one picture" )
merge_new_coordinate.datatype = "string"
merge_new_coordinate.placeholder = "120:20"
merge_new_coordinate.default = "120:20"
merge_new_coordinate.rmempty = true
merge_new_coordinate.description = translate("120:20 means:the pixel at coordinates 120,20")

video_custom_1 = s:taboption("video_setting", Value, "video_custom_1", translate("modify the screen resolution of input2 video"))
video_custom_1:depends( "enable_merge", "custom overley" )
video_custom_1.datatype = "string"
video_custom_1.placeholder = "320:-1"
video_custom_1.default = "320:-1"
video_custom_1.rmempty = true
video_custom_1.description = translate("320:-1 means: width 320, height adaptive correction")

video_custom_2 = s:taboption("video_setting", Value, "video_custom_2", translate("vertex coordinates of superimposed video"))
video_custom_2:depends( "enable_merge", "custom overley" )
video_custom_2.datatype = "string"
video_custom_2.placeholder = "20:20"
video_custom_2.default = "20:20"
video_custom_2.rmempty = true
video_custom_2.description = translate("20:20 means:the pixel at coordinates 20,20")

v_modify_duration=s:taboption("video_setting", ListValue, "v_modify_duration", translate("Modify duration"))
v_modify_duration.placeholder = "do not modify"
v_modify_duration:value("do not modify",translate("do not modify"))
v_modify_duration:value("specific time period",translate("specific time period"))
v_modify_duration:value("cut head and tail",translate("cut head and tail"))
v_modify_duration:value("only configure duration",translate("only configure duration"))
v_modify_duration.default = "do not modify"
v_modify_duration.rempty  = false

video_starttime=s:taboption("video_setting", Value, "video_starttime", translate("Start time"))
video_starttime:depends( "v_modify_duration", "specific time period" )
video_starttime.datatype = "string"
video_starttime.placeholder = "00:00:00.00"
video_starttime.default = "00:00:00.00"
video_starttime.rmempty = true

video_endtime=s:taboption("video_setting", Value, "video_endtime", translate("End time"))
video_endtime:depends( "v_modify_duration", "specific time period" )
video_endtime.datatype = "string"
video_endtime.placeholder = "00:01:30.00"
video_endtime.default = "00:01:30.00"
video_endtime.rmempty = true

video_headtime=s:taboption("video_setting", Value, "video_headtime", translate("cut head"))
video_headtime:depends( "v_modify_duration", "cut head and tail" )
video_headtime.datatype = "string"
video_headtime.placeholder = "15"
video_headtime.default = "15"
video_headtime.rmempty = true

video_tailtime=s:taboption("video_setting", Value, "video_tailtime", translate("cut tail"))
video_tailtime:depends( "v_modify_duration", "cut head and tail" )
video_tailtime.datatype = "string"
video_tailtime.placeholder = "10"
video_tailtime.default = "10"
video_tailtime.rmempty = true

vide_duration=s:taboption("video_setting", Value, "vide_duration", translate("only configure duration"))
vide_duration:depends( "v_modify_duration", "only configure duration" )
vide_duration.datatype = "string"
vide_duration.placeholder = "5"
vide_duration.default = "5"
vide_duration.rmempty = true

video_mute = s:taboption("video_setting", Flag, "video_mute", translate("Mute"))
video_mute.default = ""

video_picture = s:taboption("video_setting", Flag, "video_picture", translate("Save to picture"))
video_picture:depends({ video_x2645 ="none", picture_tovideo = "", video_adjustspeed = "" })

video_frames = s:taboption("video_setting", Flag, "video_frames", translate("Set the number of frames"))
video_frames.default = ""

video_frames_num = s:taboption("video_setting", Value, "video_frames_num", translate("The number of frames"))
video_frames_num:depends( "video_frames", "1" )
video_frames_num.datatype = "range(1,25)"
video_frames_num.placeholder = "1"
video_frames_num.default = "1"
video_frames_num.rmempty = true

picture_tovideo = s:taboption("video_setting", Flag, "picture_tovideo", translate("picture to video"))
picture_tovideo:depends({ video_x2645 ="none", video_picture = "", video_adjustspeed = "" })
picture_tovideo.default = ""

ptv_one=s:taboption("video_setting", Flag, "ptv_one", translate("only one picture"))
ptv_one:depends({ src_select ="one file", picture_tovideo = "1" })
ptv_one.default = ""

ptv_multi=s:taboption("video_setting", Flag, "ptv_multi", translate("multiple pictures"))
ptv_multi:depends({ src_select ="all files in the directory", picture_tovideo = "1" })
ptv_multi.default = ""

picture_resolution=s:taboption("video_setting", Value, "picture_resolution", translate("picture resolution"))
picture_resolution:depends( "picture_tovideo", "1" )
picture_resolution.datatype = "string"
picture_resolution.placeholder = "1280x720"
picture_resolution.default = "1280x720"
picture_resolution.rmempty = true

fix_android=s:taboption("video_setting", Flag, "fix_android", translate("fix display for android"))
fix_android:depends( "picture_tovideo", "1" )

video_copy = s:taboption("video_setting", Flag, "video_copy", translate("Fast copy"))
video_copy:depends({ image_effects = "", video_x2645 = "none", video_picture = "", picture_tovideo = "" })

video_ready = s:taboption("video_setting", Flag, "video_ready", translate("Setup ready"))
video_ready.description = translate("Save/apply first please")

s:tab("action", translate("Action"))

audioaction = s:taboption("action", Button, "audioaction", translate("One-click Convert/Play/Push/Output Audio"))
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
	luci.util.exec("kill $(busybox ps | grep ffmpeg | grep -v grep | awk '{print$1}') >/dev/null 2>&1 ")
	luci.util.exec("kill $(busybox ps | grep arecord | grep -v grep | awk '{print$1}') >/dev/null 2>&1 ")
	luci.util.exec("rm /tmp/ffmpeg.log 2>&1")
end

videoaction = s:taboption("action", Button, "videoaction", translate("One-click Convert/Play/Push/Output Video"))
videoaction:depends( "video_ready", "1" )
videoaction.rmempty = true
videoaction.inputstyle = "apply"
function videoaction.write(self, section)
	luci.util.exec("sh /usr/ffmpegtool/videoaction >/dev/null 2>&1 &")
end

videostop = s:taboption("action", Button, "videostop", translate("One-click STOP"))
videostop:depends( "video_ready", "1" )
videostop.rmempty = true
videostop.inputstyle = "apply"
function videostop.write(self, section)
	luci.util.exec("kill -9 $(busybox ps | grep videoaction | grep -v grep | awk '{print$1}') >/dev/null 2>&1 ")
	luci.util.exec("kill $(busybox ps | grep ffmpeg | grep -v grep | awk '{print$1}') >/dev/null 2>&1 ")
	luci.util.exec("rm /tmp/ffmpeg.log 2>&1")
end

return m

