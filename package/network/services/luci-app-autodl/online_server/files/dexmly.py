from fastapi import FastAPI
import uvicorn
import os
import urllib
import subprocess

app = FastAPI()

@app.get("/")
async def index():
    return {"decode xmly web server"}

@app.get("/epcode/{epcode}")
async def read_ep(epcode: str):
	epcode = urllib.parse.unquote(epcode)
	epval = os.popen('sh /usr/online_server/scripts/epxmly.sh '+epcode)
	return epval.read()

@app.get("/sdcode/{sdcode}")
async def read_sd(sdcode: str):
	sdval = os.popen('sh /usr/online_server/scripts/sdxmly.sh '+sdcode)
	return sdval.read()

@app.get("/phcode/{phcode}")
async def read_ph(phcode: str):
	phcode = urllib.parse.unquote(phcode)
	phval = os.popen('sh /usr/online_server/scripts/phxmly.sh '+phcode)
	return phval.read()

@app.get("/m4atomp3/{m4aurl}")
async def read_m4a(m4aurl: str):
	m4aurl = urllib.parse.unquote(m4aurl)
	urlval = os.popen('sh /usr/online_server/scripts/onlinem4amp3.sh '+m4aurl)
	return m4aurl

@app.get("/playfree/{freeurl}")
async def read_furl(freeurl: str):
	freeurl = urllib.parse.unquote(freeurl)
	furlval = os.popen('sh /usr/online_server/scripts/onlineplayfree.sh '+freeurl)
	return freeurl

@app.get("/playvip/{vipurl}")
async def read_vurl(vipurl: str):
	vipurl = urllib.parse.unquote(vipurl)
	vurlval = os.popen('sh /usr/online_server/scripts/onlineplayvip.sh '+vipurl)
	return vipurl

@app.get("/playrm/{rmfile}")
async def read_fmfl(rmfile: str):
	rmfile = urllib.parse.unquote(rmfile)
	fmfval = os.popen('sh /usr/online_server/scripts/playrm.sh '+rmfile)
	return rmfile

@app.get("/qrccode/{qrccode}")
async def read_qrcep(qrccode: str):
	qrccode = urllib.parse.unquote(qrccode)
	subprocess.call('sh /usr/online_server/csm/main.sh '+qrccode,shell=True)
	return qrccode

if __name__ == "__main__":
	uvicorn.run("dexmly:app", host="0.0.0.0", port=7777)

