import requests
import json
import re
import os

def get_token():
    url = 'https://kuwo.cn/'
    html = requests.session()
    html.get(url)
    csrf=html.cookies.get_dict()['kw_token']
    return csrf


def play_mp3(bangid):
    thetoken = get_token()
    url = "https://kuwo.cn/api/www/bang/bang/musicList?bangId=" + bangid + "&pn=1&rn=30"

    headers = {
        "Accept": 'application/json, text/plain, */*',
        "Cookie": "kw_token=" + thetoken,
        "csrf": thetoken,
        "Referer": "https://kuwo.cn/rankList",
        "User-Agent": "Mozilla/5.0"
    }

    r = requests.get(url=url,headers=headers)
    musiclist = re.findall('MUSIC_\d+', r.text)
    musiclist.reverse()
    namelist = re.findall('\"name\":\".*?\"', r.text)
    namelist.reverse()

    _namestr = ""
    for i in namelist:
        _name = i.replace('\"name\":\"', "").replace('\"', "")
        _namestr = _name + "@@" + _namestr

    _idstr = ""
    for i in musiclist:
        _id = i.replace('MUSIC_', "")
        _idstr = _id + " " + _idstr

    d1 = dict(zip(_namestr.split('@@'), _idstr.split()))

    for k in d1:
        print("歌曲:" + k)
        url = "https://bd.kuwo.cn/api/v1/www/music/playUrl?type=url_3&mid=" + d1[k]
    
        r = requests.get(url=url)
        _mp3url = ''.join(re.findall('https:.*\.mp3', r.text))

        #下载mp3
        #_mp3 = requests.get(_mp3url)
        #with open(k + ".mp3", "wb") as code:
            #code.write(_mp3.content)

        #播放mp3
        os.system("curl " + _mp3url + " | mpg123 - ")


if __name__ == '__main__':
    banglist = ['93', '17', '16', '158', '176', '145']
    while 1:
        for d in banglist:
            if d == "93":
                print("酷我飙升榜")
            elif d == "17":
                print("酷我新歌榜")
            elif d == "16":
                print("酷我热歌榜")
            elif d == "158":
                print("抖音歌曲榜")
            elif d == "176":
                print("万物DJ榜")
            else:
                print("会员畅听榜")

            play_mp3(d)


