from PIL import Image,ImageFont,ImageDraw
import qrcode
import os

px = open("/tmp/csm.run.pythonread")
x = px.read()
x = x.split(',')
compname = x[0]
qrcurl = x[1]
localinfo = x[2]

qr = qrcode.QRCode(
	version=2,
	error_correction=qrcode.constants.ERROR_CORRECT_H,
	box_size=10,
	border=1
)
qr.add_data(qrcurl)
qr.make(fit=True)

oimg = qr.make_image()
oimg = oimg.convert("RGBA")

icon = Image.open("/usr/online_server/csm/logo.png")
 
img_w, img_h = oimg.size
factor = 4
size_w = int(img_w / factor)
size_h = int(img_h / factor)
 
icon_w, icon_h = icon.size
if icon_w > size_w:
	icon_w = size_w
if icon_h > size_h:
	icon_h = size_h
icon = icon.resize((icon_w, icon_h), Image.ANTIALIAS)
 
w = int((img_w - icon_w) / 2)
h = int((img_h - icon_h) / 2)
oimg.paste(icon, (w, h), icon)
oimg = oimg.resize((1420,1420))

oimg.save("/tmp/csm.run.2img.png")


img = Image.open("/tmp/csm.run.2img.png")
backimg = Image.open("/usr/online_server/csm/basemap.png")
backimg_w, backimg_h = backimg.size
img_w, img_h = img.size
backimg.paste(img, (560, 820), img)
backimg.save("/tmp/csm.run.2imgbg.png")


f = ImageFont.truetype(u'/usr/online_server/csm/simhei.ttf',96)
im = Image.new("RGBA",(1700,500),(255,0,255,0))
draw = ImageDraw.Draw(im)
f4 = open("/tmp/csm.run.showmeit")
x=0

for w in f4.readlines():
	draw.text((10,x),w,font=f,fill=(255,255,255))
	x += 110

im.save('/tmp/csm.run.zi.png')

wzimg = Image.open("/tmp/csm.run.zi.png")
nbackimg = Image.open("/tmp/csm.run.2imgbg.png")
nbackimg_w, nbackimg_h = nbackimg.size
img_w, img_h = wzimg.size
nbackimg.paste(wzimg, (653, 2910), wzimg)
nbackimg.save("/tmp/csm.run.output.png")

