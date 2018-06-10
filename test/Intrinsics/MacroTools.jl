using Compat.Test
using Compat.Iterators

using Yao
using Yao.Intrinsics

@testset "assert addr" begin
    @test @assert_addr_safe 8 [1:3, 4:5, 7:7]
    @test_throws AssertionError @assert_addr_safe 8 [1:3, 2:5]
    @test_throws AssertionError @assert_addr_safe 8 [1:3, 2:9]
end
