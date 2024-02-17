# You can use ffmpeg to push multiple streams simultaneously.

# About MP3 files:
ffmpeg -re -i input1.mp3 -acodec copy -f flv rtmp://ip:1935/mp3-1

ffmpeg -re -i input2.mp3 -ac 1 -ar 11025 -f flv rtmp://ip:1935/mp3-2

ffmpeg -re -i input.mp3 -ac 1 -ar 22050 -f flv rtmp://ip:1935/mp3-3

ffmpeg -re -i input.mp3 -ac 2 -ar 44100 -f flv rtmp://ip:1935/mp3

# Test with mt7621:
Running ffmpeg with -codec copy, consumes 1.9%~2.8% CPU (single thread).

Running ffmpeg with -acodec aac, consumes 100% CPU (single thread).


# About microphone:
ffmpeg -re -f alsa -ac 1 -ar 22050 -i hw:0,0 -f flv rtmp://ip:1935/mp3-1

ffmpeg -re -f alsa -ac 1 -ar 22050 -i hw:1,0 -f flv rtmp://ip:1935/mp3-2

ffmpeg -re -f alsa -ac 2 -ar 44100 -i hw:1,0 -f flv rtmp://ip:1935/mp3-3

# Test with mt7621:
Running ffmpeg, consumes 0%~12% CPU (single thread).

------------------------------------------------------------------------
# After edit ffmpeg/Makefile:
－	--disable-outdevs

＋	--enable-outdev=alsa

# We can play rtmp:
ffmpeg -i rtmp://ip:1935/mp3-1 -f alsa default

ffmpeg -i rtmp://ip:1935/mp3-2 -f alsa hw:0,0

ffmpeg -i rtmp://ip:1935/mp3-3 -f alsa hw:1,0

# Test with mt7620/mt7621:
Running ffmpeg,consumes     0% CPU (if source use: ffmpeg -re -i input2.mp3 -ac 1 -b:a 32k -f flv rtmp://...).

Running ffmpeg,consumes 5%~10% CPU (if source use: ffmpeg -re -f alsa -ac 1 -ar 22050 -i hw:0,0 -f flv rtmp://...).

Running ffmpeg,consumes   100% CPU (if source use: ffmpeg -re -i input1.mp3 -acodec copy -f rtmp://...).


--------------------------------------------------------------------------
# About HLS stream
hls推流方法:
ffmpeg -re -i input.mp4 -c copy -f flv rtmp://ip:1935/hls/mp4
访问地址:
http://ip:1936/hls/mp4.m3u8

---------------------------------------------------------------------------

添加手机平板端浏览器同时观看多路视频流方法。使用pyhon3的flask库来提供网页服务。
pip install flask Jinja2
复制http目录内容到路由器。并修改nhttp.py里的ip为当前路由器的ip地址。
执行python3 nhttp.py后
安卓手机或平板使用浏览器打开http://ip:82页面来观看多路视频流。

--------------------------------------------------------------------------

ffmpeg -re -i input源 -c copy -f flv rtmp://ip:1935/live

live开启录像功能的配置(此配置为每分钟保存1个mp4文件):

rtmp {
	server {
		application live {
			live on;
			allow publish all;
			allow play all;
                       
			record all;
			record_path /tmp;
			record_append on;
			record_max_size 128M;
			record_suffix %Y%m%d-%H%M%S.mp4;
			record_interval 1m;
		}

请根据实际修改record_path,record_max_size,record_suffix,record_interval的值。


