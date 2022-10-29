# You can use ffmpeg to push multiple streams simultaneously.

# About MP3 files:
ffmpeg -re -i input1.mp3 -acodec copy -f flv rtmp://ip:1935/mp3-1

ffmpeg -re -i input2.mp3 -ac 1 -b:a 32k -f flv rtmp://ip:1935/mp3-2

ffmpeg -re -i input3.mp3 -ac 2 -b:a 128k -f flv rtmp://ip:1935/mp3-3

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

