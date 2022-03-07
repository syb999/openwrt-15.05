from fastapi import FastAPI
import uvicorn
import os
import urllib

app = FastAPI()

@app.get("/")
async def index():
    return {"decode xmly web server"}

@app.get("/epcode/{epcode}")
async def read_ep(epcode: str):
	epcode = urllib.parse.unquote(epcode)
	epval = os.popen('sh ./scripts/epxmly.sh '+epcode)
	return epval.read()

@app.get("/sdcode/{sdcode}")
async def read_sd(sdcode: str):
	sdval = os.popen('sh ./scripts/sdxmly.sh '+sdcode)
	return sdval.read()

@app.get("/phcode/{phcode}")
async def read_ph(phcode: str):
	phcode = urllib.parse.unquote(phcode)
	phval = os.popen('sh ./scripts/phxmly.sh '+phcode)
	return phval.read()


if __name__ == "__main__":
	uvicorn.run("dexmly:app", host="0.0.0.0", port=7777)

