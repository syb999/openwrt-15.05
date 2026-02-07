m = Map("squeezelite", translate("Squeezelite Audio Player"), 
        translate("Squeezelite is a small headless squeezeplay emulator for Linux using ALSA audio output."))

m:section(SimpleSection).template  = "squeezelite_status"

s = m:section(TypedSection, "options", "")
s.anonymous = true
s.addremove = false

s:tab("general", translate("Setting"))

enabled = s:taboption("general", Flag, "enabled", translate("Enable"))
enabled.default = "0"

name = s:taboption("general", Value, "name", translate("Player Name"))
name.default = "SqueezeWrt"
name.datatype = "string"

server_ip = s:taboption("general", Value, "server_ip", translate("LMS Server IP"))
server_ip.default = "192.168.1.1"
server_ip.datatype = "ip4addr"

server_port = s:taboption("general", Value, "server_port", translate("LMS Server Port"))
server_port.default = "3483"
server_port.datatype = "port"

device = s:taboption("general", Value, "device", translate("ALSA Device"))
device.default = "hw:0,0"
device:value("hw:0,0", "Hardware Device 0,0")
device:value("plughw:0,0", "Plug Device 0,0")
device:value("default", "Default Device")

extra_set = s:taboption("general", Flag, "extraset", translate("Extra settings"))

model_name = s:taboption("general", Value, "model_name", translate("Model Name"))
model_name:depends("extraset", "1")
model_name.default = "SqueezeLite"
model_name.datatype = "string"

max_sr = s:taboption("general", Value, "max_sr", translate("Maximum Sample Rate (Hz)"))
max_sr:depends("extraset", "1")
max_sr.default = "48000"
max_sr:value("44100", "44.1 kHz")
max_sr:value("48000", "48 kHz")
max_sr:value("88200", "88.2 kHz")
max_sr:value("96000", "96 kHz")
max_sr:value("192000", "192 kHz")
max_sr.datatype = "uinteger"

codec = s:taboption("general", ListValue, "codec", translate("Codec Support"))
codec:depends("extraset", "1")
codec.default = "mpg"
codec:value("mpg", "MP3")
codec:value("flac", "FLAC")
codec:value("pcm", "PCM")
codec:value("all", "All Codecs")

close_delay = s:taboption("general", Value, "close_delay", translate("Close Delay (ms)"))
close_delay:depends("extraset", "1")
close_delay.default = "0"
close_delay.datatype = "uinteger"

priority = s:taboption("general", Value, "priority", translate("Priority"))
priority:depends("extraset", "1")
priority.default = "10"
priority.datatype = "uinteger"

period = s:taboption("general", Value, "period", translate("Buffer Period"))
period:depends("extraset", "1")
period.default = "200:20"
period.datatype = "string"

dsd_over_pcm = s:taboption("general", ListValue, "dsd_over_pcm", translate("DSD over PCM"))
dsd_over_pcm:depends("extraset", "1")
dsd_over_pcm.default = "0"
dsd_over_pcm:value("0", "Disabled")
dsd_over_pcm:value("1", "Enabled")

ircontrol = s:taboption("general", ListValue, "ircontrol", translate("IR Control"))
ircontrol:depends("extraset", "1")
ircontrol.default = "0"
ircontrol:value("0", "Disabled")
ircontrol:value("1", "Enabled")

interface = s:taboption("general", Value, "interface", translate("Network Interface"))
interface:depends("extraset", "1")
interface.default = ""
interface.optional = true

function m.on_after_commit(self)
    os.execute("/etc/init.d/squeezelite restart >/dev/null 2>&1")
end


return m
