# This file is a part of BitManip.jl, licensed under the MIT License (MIT).

using Compat.Test
include("bitops.jl")

@testset "bit operations" begin
    @testset "bsizeof" begin
        @test bsizeof(one(Int64)) == 64
        @test bsizeof(Int16) == 16
    end


    @testset "multi-bit bmask" begin
        @test bmask(UInt64, 0:0) == 0x1
        @test bmask(UInt64, 0:3) == 0xf
        @test bmask(UInt64, 0:63) == 0xffffffffffffffff
        @test bmask(UInt64, 60:63) == 0xf000000000000000
        @test bmask(UInt64, 60:63) == 0xf000000000000000
        @test bmask(UInt64, 63:63) == 0x8000000000000000
    end


    @testset "single-bit lsbmask and msbmask" begin
        @test lsbmask(UInt64) == 0x1
        @test msbmask(UInt64) == 0x8000000000000000

        @test lsbmask(Int64) == 1
        @test msbmask(Int64) == signed(0x8000000000000000)
    end


    @testset "multi-bit lsbmask and msbmask" begin
        @test lsbmask(UInt64, 0) == 0x0
        @test lsbmask(UInt64, 64) == 0xffffffffffffffff
        @test lsbmask(UInt64, 6) == 0x000000000000003f

        @test msbmask(UInt64, 0) == 0x0
        @test msbmask(UInt64, 64) == 0xffffffffffffffff
        @test msbmask(UInt64, 6) == 0xfc00000000000000
    end


    @testset "single-bit bget and bset" begin
        @test bget(8, 0) == false
        @test bget(8, 3) == true
        @test bget(0x8000000000000000, 63) == true
        @test bget(0x8000000000000000, 64) == false

        @test bset(0x04, 7, true) == 0x84
        @test bset(0xff, 7, false) == 0x7f
    end


    @testset "multi-bit bget and bset" begin
        @test bget(0x1234, 4:11) == 0x23
        @test bset(0x15a4, 4:11, 0x23) == 0x1234
    end


    @testset "single-bit bflip" begin
        @test bflip(0b1001000110100, 5) == 0b1001000010100
        @test bflip(0b1001000110100, 9) == 0b1000000110100
    end


    @testset "multi-bit bflip" begin
        @test bflip(0xa5a5, 4:11) == 0xaa55
    end


    @testset "single-bit lsbget and msbget" begin
        @test lsbget(0) == false
        @test lsbget(1) == true

        @test msbget(0x7fffffffffffffff) == false
        @test msbget(0x8000000000000000) == true
    end


    @testset "multi-bit lsbget and msbget" begin
        const x = 0xabffffffffffffd5

        @test lsbget(x, 0) == 0
        @test lsbget(x, 6) == 0x15
        @test lsbget(x, 64) == x

        @test msbget(x, 0) == 0
        @test msbget(x, 6) == 0x2a
        @test msbget(x, 64) == x
    end
end
