using Test, Revise, YaoBlocks
import YaoBlocks: print_annotation

g1 = kron(2, 1=>(im * X))
g2 = control(2, 1, 2=>(im * X))
g3 = chain(im * X, X, Y)

io = IOBuffer()
print_annotation(io, g1, g1, g1[1])
@test String(take!(io)) == "1=>[+im] "

print_annotation(io, g2, g2, content(g2))
@test String(take!(io)) == "(2,)[+im] "
