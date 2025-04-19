from Crypto.Cipher import AES
from base64 import b64decode
import urllib.parse
import re
import argparse

token_key = "57A891D97E332A9D"

def decrypt_video_url(encrypted_str, iv_str):
   
    try:
        padding = (-len(encrypted_str) % 4)
        encrypted_str += '=' * padding

        encrypted_data = b64decode(encrypted_str)

        aligned_length = len(encrypted_data) // 16 * 16
        encrypted_data = encrypted_data[:aligned_length]

        cipher = AES.new(
            token_key.encode('utf-8'), 
            AES.MODE_CBC, 
            iv=iv_str.encode('utf-8')
        )

        decrypted = cipher.decrypt(encrypted_data)

        try:
            unpadded = unpad_pkcs7(decrypted)
        except ValueError as e:
            unpadded = decrypted

        decoded_str = unpadded.decode('utf-8', errors='ignore')

        match = re.search(
            r'(https?://[^\s<>#"\\]+)',
            decoded_str
        )
        
        if match:
            return urllib.parse.unquote(match.group(0))
        return None

    except Exception as e:
        raise

def unpad_pkcs7(data, strict=True):
    if len(data) == 0:
        raise ValueError("error")
        
    padding_len = data[-1]

    return data[:-padding_len]

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="decrpyt qdm88.com",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('-e', '--encrypted', required=True)
    parser.add_argument('-i', '--iv', required=True)
    
    args = parser.parse_args()

    try:
        result = decrypt_video_url(
            args.encrypted,
            args.iv
        )

        if result:
            print(result)
        else:
            print("error")
                
    except Exception as e:
        print("error")

