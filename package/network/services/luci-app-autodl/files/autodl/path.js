function vt(t) {
                this._randomSeed = t,
                this.cg_hun()
            }
            vt.prototype = {
                cg_hun: function() {
                    this._cgStr = "";
                    var t = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/\\:._-1234567890"
                      , e = t.length
                      , n = 0;
                    for (n = 0; n < e; n++) {
                        var r = this.ran() * t.length
                          , o = parseInt(r);
                        this._cgStr += t.charAt(o),
                        t = t.split(t.charAt(o)).join("")
                    }
                },
                cg_fun: function(t) {
                    t = t.split("*");
                    var e = ""
                      , n = 0;
                    for (n = 0; n < t.length - 1; n++)
                        e += this._cgStr.charAt(t[n]);
                    return e
                },
                ran: function() {
                    this._randomSeed = (211 * this._randomSeed + 30031) % 65536;
                    return this._randomSeed / 65536
                },

            };

c = function(t, e) {
    var n = new vt(t).cg_fun(e);
    return "/" === n[0] ? n : "/".concat(n)
}

console.log(c(seedcode,"fieldcode"))
