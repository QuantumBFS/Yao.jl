"""
    cuproduct_state([T=ComplexF64], total::Int, bit_config::Integer; nbatch=NoBatch())

The GPU version of [`product_state`](@ref).
"""
function cuproduct_state end

"""
    curand_state([T=ComplexF64], n::Int; nbatch=1)

The GPU version of [`rand_state`](@ref).
"""
function curand_state end

"""
    cuzero_state([T=ComplexF64], n::Int; nbatch=1)

The GPU version of [`zero_state`](@ref).
"""
function cuzero_state end

"""
    cuuniform_state([T=ComplexF64], n::Int; nbatch=1)

The GPU version of [`uniform_state`](@ref).
"""
function cuuniform_state end

"""
    cughz_state([T=ComplexF64], n::Int; nbatch=1)

The GPU version of [`ghz_state`](@ref).
"""
function cughz_state end

"""
    cpu(cureg)

Download the register state from GPU to CPU.
"""
function cpu end