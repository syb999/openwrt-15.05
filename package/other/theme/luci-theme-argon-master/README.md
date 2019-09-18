# luci-theme-argon
A new Luci theme for LEDE/OpenWRT  
Argon is a clean HTML5 theme for LuCI. It is based on luci-theme-material and Argon Template  
Suitable for Openwrt  

The old version is still in another branch call old. If you need that you can checkout that branch.


## How to use

Enter in your openwrt/package/lean  or  other

```
git clone https://github.com/jerrykuku/luci-theme-argon.git
make menuconfig #choose LUCI->Theme->Luci-theme-argon
make -j1 V=s
```

## Thanks to 
luci-theme-material: https://github.com/LuttyYang/luci-theme-material/
