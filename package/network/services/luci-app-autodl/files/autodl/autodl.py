import os, shutil
import urllib.request, urllib.error, requests


def getUrlData(url):
    try:
        urlData = urllib.request.urlopen(url, timeout=20)  # .read().decode('utf-8', 'ignore')
        return urlData
    except Exception as err:
        print(f'err getUrlData({url})\n', err)
        return -1


def getDown_urllib(url, file_path):
    try:
        urllib.request.urlretrieve(url, filename=file_path)
        return True
    except urllib.error.URLError as e:
        if hasattr(e, 'code'):
            print(e.code)
        elif hasattr(e, 'reason'):
            print(e.reason)


def getVideo_urllib(url_m3u8, path, videoName):
    print('begin run ~~\n')
    urlData = getUrlData(url_m3u8)
    num = 0
    tempName_video = os.path.join(path, f'{videoName}.xts')
    for line in urlData:
        url_ts = line.decode('utf-8')
        tempName_ts = os.path.join(path, f'{num}.ts')
        if not '.ts' in url_ts:
            continue
        else:
            if not url_ts.startswith('http'):
                url_ts = url_m3u8.replace(url_m3u8.split('/')[-1], url_ts)
        getDown_urllib(url_ts, tempName_ts)
        if num == 0:
            shutil.move(tempName_ts, tempName_video)
            num += 1
            continue
        cmd = f'cat {tempName_ts} >> {tempName_video}'
        res = os.system(cmd)
        if res == 0:
            os.system(f'rm {tempName_ts}')
            if num == 356:
                break
            num += 1
            continue
        print(f'Wrong, copy {num}.ts-->{videoName}.ts failure')
        return False
    filename = os.path.join(path, f'{videoName}.ts')
    shutil.move(tempName_video, filename)
    print(f'{videoName}.ts finish down!')
 
if __name__ == '__main__':
    url_m3u8 = input("请输入下载地址:")
    path = r'/autodl/videos'
    videoName = url_m3u8.split('/')[-2]
    getVideo_urllib(url_m3u8, path, videoName)
