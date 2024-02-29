import sys
import os
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
import base64
import requests
import time

def decrypt_url(ciphertext):
    key = bytes.fromhex("aaad3e4fd540b0f79dca95606e72bf93")
    cipher = AES.new(key, AES.MODE_ECB)
    ciphertext = base64.urlsafe_b64decode(ciphertext + '=' * (4 - len(ciphertext) % 4))
    plaintext = cipher.decrypt(ciphertext)
    plaintext = unpad(plaintext, AES.block_size)
    plaintext = plaintext.decode("utf-8").encode("ascii", errors="ignore").decode()
    return plaintext

def analyze_sound(sound_id, headers):
    url = f"https://www.ximalaya.com/mobile-playpage/track/v3/baseInfo/{int(time.time() * 1000)}"
    params = {
        "device": "web",
        "trackId": sound_id,
        "trackQualityLevel": 2
    }
    try:
        response = requests.get(url, headers=headers, params=params, timeout=15)
        encrypted_url_list = response.json()["trackInfo"]["playUrlList"]
    except Exception as e:
        print(f'ID为{sound_id}的声音解析失败！')
        return False

    sound_info = ""
    for encrypted_url in encrypted_url_list:
        if encrypted_url["type"] == "MP3_64":
            sound_info = decrypt_url(encrypted_url["url"])
            break
    return sound_info

if __name__ == "__main__":
    headers = {
        "user-agent": "Mozilla/5.0"
    }

    with open('/tmp/tmpXM.xmlysoundid', 'r') as f:
        sound_id = f.read().strip()

    sound_info = analyze_sound(sound_id, headers)

    if sound_info:
        output_file = os.path.join(os.path.dirname(__file__), '/tmp/tmpXM.xmlyhttp')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(sound_info)

