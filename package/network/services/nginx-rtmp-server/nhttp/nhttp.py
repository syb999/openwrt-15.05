# pip install Flask Jinja2

import os
from flask import Flask, render_template

app = Flask(__name__)
template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), 'templates'))
app.template_folder = template_dir

@app.route('/')
def index():
    streams = [
        {
            'name': 'Stream 1',
            'url': 'http://ip:1936/hls/1.m3u8'
        },
        {
            'name': 'Stream 2',
            'url': 'http://ip:1936/hls/2.m3u8'
        },
        {
            'name': 'Stream 3',
            'url': 'http://ip:1936/hls/3.m3u8'
        }
    ]
    return render_template('index.html', streams=streams)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=82)

