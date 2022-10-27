# You can use ffmpeg to push multiple streams simultaneously.

# About MP3 files:
ffmpeg -re -i input1.mp3 -acodec copy -f flv rtmp://ip:1935/mp3-1

ffmpeg -re -i input2.mp3 -acodec copy -f flv rtmp://ip:1935/mp3-2

ffmpeg -re -i input3.mp3 -acodec aac -f flv rtmp://ip:1935/mp3-3

# Test with mt7621:
Running ffmpeg with -codec copy, consumes 1.9%~2.8% CPU (single thread).

Running ffmpeg with -acodec aac, consumes 100% CPU (single thread).


# About microphone:
ffmpeg -re -f alsa -ac 1 -ar 8000 -i hw:0,0 -f flv rtmp://ip:1935/mp3-1

ffmpeg -re -f alsa -ac 1 -ar 8000 -i hw:1,0 -f flv rtmp://ip:1935/mp3-2

ffmpeg -re -f alsa -ac 2 -ar 16000 -i hw:1,0 -f flv rtmp://ip:1935/mp3-3

# Test with mt7621:
Running ffmpeg, consumes 10%~11% CPU (single thread).
