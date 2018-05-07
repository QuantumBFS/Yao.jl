# Integer Logrithm of 2
# Ref: https://stackoverflow.com/questions/21442088
export log2i

function bit_length(x)
    local n = 0
    while x!=0
        n += 1
        x >>= 1
    end
    return n
end

"""
    log2i(x)

logrithm for integer pow of 2
"""
function log2i(x::T)::T where T
    local n::T = 0
    while x&0x1!=1
        n += 1
        x >>= 1
    end
    return n
end

export batch_normalize!

function batch_normalize!(s::AbstractMatrix)
    B = size(s, 2)
    for i = 1:B
        normalize!(view(s, :, i))
    end
    s
end

function batch_normalize(s::AbstractMatrix)
    ts = copy(s)
    batch_normalize!(ts)
end
