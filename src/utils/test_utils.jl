module TestUtils

using ..YaoBase

# mocked registers
export TestRegister
struct TestRegister{B, T} <: AbstractRegister{B, T}
end

TestRegister() = TestRegister{1, Float64}()

YaoBase.nqubits(::TestRegister) = 8
YaoBase.nactive(::TestRegister) = 2

export TestInterfaceRegister
struct TestInterfaceRegister{B, T} <: AbstractRegister{B, T}
end

TestInterfaceRegister() = TestInterfaceRegister{1, Float64}()

# IO tests

using Test
export @test_io

"""
    @test_io ex expected_output

Tests whether the printing of expression `ex` is the same with expected output.

## Example

@test_io (2, 3) "(2, 3)"
"""
macro test_io(ex, expect::String)
    :(@test test_io($(esc(ex)), $(esc(expect))))
end

"""
    @test_io mime ex expected_output

Tests whether the output to MIME type `mime` is the same as expected.

You can implement specific checking methods by overloading [`test_io`](@ref) with
different mime types.
"""
macro test_io(mime, ex, expect)
    :(@test test_io($(esc(ex)), $(esc(mime)), $(esc(expect))))
end

"""
    test_io(x, mime, expect)

IO testing method, by default, this compares the output in `MIME"text/plain"`.
"""
function test_io end

test_io(x, expect::String) = test_io(x, MIME("text/plain"), expect)

function test_io(x, ::MIME"text/plain", expect::String)
    x isa Nothing && expect == "" && return true
    x isa Nothing && return false

    string(x) == expect && return true
    return false
end

end
