using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Intrinsics

@testset "assert addr safe" begin
    N = 8
    @test assert_addr_safe(N, [7:7, 1:3, 4:5])
    @test_throws AddressConflictError assert_addr_safe(N, [2:5, 1:3])
    @test_throws AddressConflictError assert_addr_safe(N, [1:3, 2:9])
end

@testset "assert addr fit" begin
    @test assert_addr_fit 8 [1:3, 7:8, 4:5, 6:6]
    @test_throws AddressConflictError assert_addr_fit 8 [1:3, 7:7, 4:5]
    @test_throws AddressConflictError assert_addr_fit 8 [1:3, 2:9]
end

@testset "assert addr inbounds" begin
    @test assert_addr_inbounds 8 [1:3, 7:7, 4:5]
    @test assert_addr_inbounds 8 [2:5, 1:3]
    @test_throws AddressConflictError assert_addr_inbounds 8 [2:9, 1:3]
end
