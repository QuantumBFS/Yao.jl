"""
    nactive(reg)->Int

get the number of active qubits.
"""
function nactive end

"""
nremain(reg)->Int

get the number of remained qubits.
"""
function nremain end

"""
    nbatch(reg)->Int

get the number of batch.
"""
function nbatch end

"""
    address(reg)->Int

get the address of this register.
"""
function address end

"""
    state(reg)

get the state of this register. It always return
the matrix stored inside.
"""
function state end

"""
    statevec(reg)

get the state vector of this register. It will always return
the vector form (a matrix for batched register).
"""
function statevec end

"""
    register(::Type{RT}, raw, nbatch)

an general initializer for input raw state array.

    register(::Type{InitMethod}, ::Type{RT}, ::Type{T}, n, nbatch)

init register type `RT` with `InitMethod` type (e.g `InitMethod{:zero}`) with
element type `T` and total number qubits `n` with `nbatch`. This will be
auto-binded to some shortcuts like `zero_state`, `rand_state`, `randn_state`.
"""
function register end

"""
    zero_state(n, nbatch)

construct a zero state ``|00\\cdots 00\\rangle``.
"""
function zero_state end

"""
    rand_state(n, nbatch)

construct a normalized random state with uniform distributed
``\\theta`` and ``r`` with amplitude ``r\\cdot e^{i\\theta}``.
"""
function rand_state end

"""

    randn_state(n, nbatch)

construct normalized a random state with normal distributed
``\\theta`` and ``r`` with amplitude ``r\\cdot e^{i\\theta}``.
"""
function randn_state end
