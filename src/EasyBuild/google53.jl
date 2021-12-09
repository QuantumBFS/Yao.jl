export Lattice53, rand_google53

entangler_google53(nbits::Int, i::Int, j::Int) = put(nbits, (i,j)=>FSimGate(π/2, π/6))

struct Lattice53
    labels::Matrix{Int}
end

function Lattice53(;nbits::Int=53)
    config = ones(Bool, 5, 12)
    config[end,2:2:end] .= false
    config[1, 7] = false
    labels = zeros(Int, 5, 12)
    k = 0
    for (i,c) in enumerate(config)
        if c
            k += 1
            labels[i] = k
            k>=nbits && break
        end
    end
    return Lattice53(labels)
end

nbits(lattice::Lattice53) = maximum(lattice.labels)

function Base.getindex(lattice::Lattice53, i, j)
    1<=i<=size(lattice.labels, 1) && 1<=j<=size(lattice.labels, 2) ? lattice.labels[i,j] : 0
end
upperleft(lattice::Lattice53,i,j) = lattice[i-j%2,j-1]
lowerleft(lattice::Lattice53,i,j) = lattice[i+(j-1)%2,j-1]
upperright(lattice::Lattice53,i,j) = lattice[i-j%2,j+1]
lowerright(lattice::Lattice53,i,j) = lattice[i+(j-1)%2,j+1]

function pattern53(lattice::Lattice53, chr::Char)
    res = Tuple{Int,Int}[]
    # i0, di, j0, dj and direction
    di = 1 + (chr>'D')
    dj = 2 - (chr>'D')
    j0 = 1 + min(dj-1, mod(chr-'A',2))
    direction = 'C'<=chr<='F' ? lowerright : upperright
    for j=j0:dj:12
        i0 = chr>'D' ? mod((chr-'D') + (j-(chr>='G'))÷2, 2) : 1
        for i = i0:di:5
            src = lattice[i, j]
            dest = direction(lattice, i, j)
            src!=0 && dest !=0 && push!(res, (src, dest))
        end
    end
    return res
end

function print_lattice53(lattice, pattern)
    for i_=1:10
        i = (i_+1)÷2
        for j=1:12
            if i_%2 == j%2 && lattice[i,j]!=0
                print(" ∘  ")
            else
                print("    ")
            end
        end
        println()
        for j=1:12
            if i_%2 == j%2 && lattice[i,j]!=0
                hasll = (lowerleft(lattice, i, j), lattice[i,j]) in pattern
                haslr = (lattice[i,j], lowerright(lattice, i, j)) in pattern
                print(hasll ? "/ " : "  ")
                print(haslr ? " \\" : "  ")
            else
                print("    ")
            end
        end
        println()
    end
end

"""
    rand_google53(depth::Int; nbits=53) -> AbstactBlock

random google supremacy circuit with 53 qubits.
"""
function rand_google53(depth::Int; nbits::Int=53)
    c = chain(nbits)
    lattice = Lattice53(nbits=nbits)
    k = 0
    for pattern in Iterators.cycle(['A', 'B', 'C', 'D', 'C', 'D', 'A', 'B'])
        push!(c, rand_google53_layer(lattice, pattern))
        k += 1
        k>=depth && break
    end
    return c
end

function rand_google53_layer(lattice, pattern)
    nbit = nbits(lattice)
    chain(nbit, chain(nbit, [put(nbit, i=>rand([SqrtW, SqrtX, SqrtY])) for i=1:nbit]),
        chain(nbit, [entangler_google53(nbit,i,j) for (i,j) in pattern53(lattice, pattern)])
        )
end
