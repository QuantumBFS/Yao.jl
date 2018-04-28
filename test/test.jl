import QuCircuit: log2i

function nbits(x)
    n = 0
    while x!=0
        n += 1
        x >>= 1
    end;
    return n
end

function log2i(x)
    n = 0
    while x!=0
        n += 1
        x >>= 1
    end
    return n - 1
end

nbits(8)
