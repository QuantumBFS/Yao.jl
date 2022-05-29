# Note: requires latex env
using Comonicon, TikzGenerator
using Yao

imgpath(filename) = pkgdir(Yao, "docs", "src", "assets", "images", filename)

function matrix!(c::Canvas, offset::Tuple, size::Tuple; text_row="", text_col="")
    dx, dy = offset
    X, Y = size
    rectangle!(c, dx, dy, X, Y; draw="", line_width=0.05, pattern="grid", fill=false)
    #text!(c, dx-1, dy+Y/2, text_row)
    brace!(c, (dx, dy), (dx, dy+Y), text_row; mirror=false)
    #text!(c, dx+X/2, dy-1, text_col)
    brace!(c, (dx, dy), (dx+X, dy), text_col; mirror=true)
end

@cast function regstorage()
    canvas(imgpath("regstorage.svg"); libs=["patterns","decorations.pathreplacing"]) do c
        # output register
        matrix!(c, (5, 0), (5, 3); text_row=raw"\large $d^a$", text_col=raw"\large $d^r \times b$")
        # input register
        #matrix!(c, (-7, 0), (5, 3); text_row=raw"\large $2^a$", text_col=raw"\large $2^r \times b$")
        # input operator
        #matrix!(c, (0, 0), (3, 3); text_row=raw"\large $2^a$", text_col=raw"\large $2^r \times b$")
    end
end

@cast function regstorage()
    Y = 3.0
    canvas(imgpath("regstorage.svg"); libs=["patterns","decorations.pathreplacing"]) do c
        rectangle!(c, 0, 0, 5, Y; draw="", line_width=0.05, pattern="grid", fill=false)
        text!(c, -1, Y/2, raw"\large $2^a$")
        text!(c, 2.5, -1, raw"\large $2^r \times b$")
    end
end
