using BenchmarkTools

A = rand(100, 100);
B = rand(100, 100);

function assign1(A, B)
    @inbounds @simd for i = 1:size(A, 2)
        A[:, i] = B[:, i]
    end
end

function assign2(A, B)
    @inbounds @simd for i = 1:size(A, 2)
        for j = 1:size(A, 1)
            A[j, i] = B[j, i]
        end
    end
end

function assign3(A, B)
    @inbounds @simd for i = 1:size(A, 2)
        A[:, i] .= B[:, i]
    end
end

display(@benchmark assign1($A, $B))
println("----")
display(@benchmark assign2($A, $B))
println("----")
display(@benchmark assign3($A, $B))
println("----")