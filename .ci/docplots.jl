# Note: requires latex env
using Comonicon, TikzGenerator
using Yao

imgpath(filename) = pkgdir(Yao, "docs", "src", "assets", filename)

@cast function regstorage()
    Y = 3.0
    canvas(imgpath("regstorage.svg"); libs=["patterns","decorations.pathreplacing"]) do c
        rectangle!(c, 0, 0, 5, Y; draw="", line_width=0.05, pattern="grid", fill=false)
        text!(c, -1, Y/2, raw"\large $2^a$")
        text!(c, 2.5, -1, raw"\large $2^r \times b$")
        edge!(c, (0, 0.0), (0, Y); decoration="{brace,raise=0.5cm}",decorate=true, thick=true, draw="black")
        edge!(c, (0.0, 0), (5.0, 0); decoration="{brace,mirror,raise=0.5cm}",decorate=true,thick=true, draw="black")
    end
end
