using BenchmarkTools

A = rand(100, 100);
B = rand(100, 100);

function assign1(A, B)
    @inbounds for i = 1:size(A, 2)
        A[:, i] = B[:, i]
    end
end

function assign2(A, B)
    @inbounds for i = 1:size(A, 2)
        for j = 1:size(A, 1)
            A[j, i] = B[j, i]
        end
    end
end

function assign3(A, B)
    @inbounds for i = 1:size(A, 2)
        A[:, i] .= B[:, i]
    end
end

function assign4(A, B)
    @inbounds for i = 1:size(A, 2)
        @views A[:, i] = B[:, i]
    end
end

function assign5(A, B)
    @inbounds for i = 1:size(A, 2)
        @views A[:, i] .= B[:, i]
    end
end

function assign6(A, B)
    @inbounds for i = 1:size(A, 2)
        @. @views A[:, i] = B[:, i]
    end
end

function assign7(A, B)
    copy!(A, B)
end

display(@benchmark assign1($A, $B))
println("\n----")
display(@benchmark assign2($A, $B))
println("\n----")
display(@benchmark assign3($A, $B))
println("\n----")
display(@benchmark assign4($A, $B))
println("\n----")
display(@benchmark assign5($A, $B))
println("\n----")
display(@benchmark assign6($A, $B))
println("\n----")
display(@benchmark assign7($A, $B))


function func3(A, b)
    for i = 1:size(A, 2)
        @inbounds @simd for j = 1:length(b)
            A[j, i] = b[j]
        end
    end
end

function func2(A, b)
    @inbounds @simd for i = 1:size(A, 2)
    @views A[:, i] = b
    end
end

