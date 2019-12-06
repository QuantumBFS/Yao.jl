# Quantum Fourier Transformation and Phase Estimation

Let's use Yao first

````julia
using Yao
````





## Quantum Fourier Transformation

The Quantum Fourier Transformation (QFT) circuit is to repeat
two kinds of blocks repeatly:

![ghz](../assets/figures/qft.png)

The basic building block control phase shift gate is defined
as

```math
R(k)=\begin{bmatrix}
1 & 0\\
0 & \exp\left(\frac{2\pi i}{2^k}\right)
\end{bmatrix}
```

Let's define block `A` and block `B`, block `A` is actually
a control block.

````julia
A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))))
````


````
A (generic function with 1 method)
````





Once you construct the blockl you can inspect its matrix using [`mat`](@ref)
function. Let's construct the circuit in dash box A, and see the matrix of
``R_4`` gate.

````julia
R4 = A(4, 1)
````


````
(n -> control(n, 4, 1 => shift(0.39269908169872414)))
````





If you have read about [preparing GHZ state](@ref example-ghz),
you probably know that in Yao, we could just leave the number of qubits, and it
will be evaluated when possible.

````julia
R4(5)
````


````
nqubits: 5
control(4)
└─ (1,) shift(0.39269908169872414)
````





its matrix will be

````julia
mat(R4(5))
````


````
32×32 LinearAlgebra.Diagonal{Complex{Float64},Array{Complex{Float64},1}}:
 1.0+0.0im      ⋅          ⋅          ⋅      …      ⋅              ⋅       
  
     ⋅      1.0+0.0im      ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅      1.0+0.0im      ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅      1.0+0.0im         ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅      …      ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
    ⋮                                        ⋱     ⋮                       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅      …      ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅              ⋅       
  
     ⋅          ⋅          ⋅          ⋅      …  1.0+0.0im          ⋅       
  
     ⋅          ⋅          ⋅          ⋅             ⋅      0.92388+0.382683
im
````





Then we repeat this control block over
and over on different qubits, and put a Hadamard gate
to `i`th qubit to construct `i`-th `B` block.

````julia
B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)
````


````
B (generic function with 1 method)
````





We need to input the total number of qubits `n` here because we have to iterate
through from `k`-th location to the last.

Now, let's construct the circuit by chaining all the `B` blocks together

````julia
qft(n) = chain(B(n, k) for k in 1:n)

qft(4)
````


````
nqubits: 4
chain
├─ chain
│  ├─ put on (1)
│  │  └─ H gate
│  ├─ control(2)
│  │  └─ (1,) shift(1.5707963267948966)
│  ├─ control(3)
│  │  └─ (1,) shift(0.7853981633974483)
│  └─ control(4)
│     └─ (1,) shift(0.39269908169872414)
├─ chain
│  ├─ put on (2)
│  │  └─ H gate
│  ├─ control(3)
│  │  └─ (2,) shift(1.5707963267948966)
│  └─ control(4)
│     └─ (2,) shift(0.7853981633974483)
├─ chain
│  ├─ put on (3)
│  │  └─ H gate
│  └─ control(4)
│     └─ (3,) shift(1.5707963267948966)
└─ chain
   └─ put on (4)
      └─ H gate
````





## Wrap QFT to an external block

In most cases, `function`s are enough to wrap quantum circuits, like `A`
and `B` we defined above, but sometimes, we need to dispatch specialized
methods on certain kinds of quantum circuit, or we want to define an external
block to export, thus, it's useful to be able to wrap circuit to custom blocks.

First, we define a new type as subtype of [`PrimitiveBlock`](@ref) since we are not
going to use the subblocks of `QFT`, if you need to use its subblocks, it'd
be better to define it under [`CompositeBlock`](@ref).

````julia
struct QFT{N} <: PrimitiveBlock{N} end
QFT(n::Int) = QFT{n}()
````


````
Main.WeaveSandBox1.QFT
````





Now, let's define its circuit

````julia
circuit(::QFT{N}) where N = qft(N)
````


````
circuit (generic function with 1 method)
````





And forward [`mat`](@ref) to its circuit's matrix

````julia
YaoBlocks.mat(::Type{T}, x::QFT) where T = mat(T, circuit(x))
````





You may notice, it is a little ugly to print `QFT` at the moment,
this is because we print the type summary by default, you can define
your own printing by overloading [`print_block`](@ref)

````julia
YaoBlocks.print_block(io::IO, x::QFT{N}) where N = print(io, "QFT($N)")
````





Since it is possible to use FFT to simulate the results of QFT (like cheating),
we could define our custom [`apply!`](@ref) method:

````julia
using FFTW, LinearAlgebra

function YaoBlocks.apply!(r::ArrayReg, x::QFT)
    α = sqrt(length(statevec(r)))
    invorder!(r)
    lmul!(α, ifft!(statevec(r)))
    return r
end
````





Now let's check if our `apply!` method is correct:

````julia
r = rand_state(5)
r1 = r |> copy |> QFT(5)
r2 = r |> copy |> circuit(QFT(5))
r1 ≈ r2
````


````
true
````





We can get iQFT (inverse QFT) directly by calling `adjoint`

````julia
QFT(5)'
````


````
[†]QFT(5)
````





QFT and iQFT are different from FFT and IFFT in three ways,

1. they are different by a factor of ``\sqrt{2^n}`` with ``n`` the number of qubits.
2. the [bit numbering](https://quantumbfs.github.io/BitBasis.jl/stable/tutorial/#Conventions-1) will exchange after applying QFT or iQFT.
3. due to the convention, QFT is more related to IFFT rather than FFT.

## Phase Estimation

Since we have QFT and iQFT blocks we can then use them to
realize phase estimation circuit, what we want to realize
is the following circuit:

![phase estimation](../assets/figures/phaseest.png)

````julia
using Yao
````





First we call Hadamard gates repeatly on first `n` qubits.

````julia
Hadamards(n) = repeat(H, 1:n)
````


````
Hadamards (generic function with 1 method)
````





Then in dashed box `B`, we have controlled unitaries:

````julia
ControlU(n, m, U) = chain(n+m, control(k, n+1:n+m=>matblock(U^(2^(k-1)))) for k in 1:n)
````


````
ControlU (generic function with 1 method)
````





each of them is a `U` of power ``2^(k-1)``.

Since we will only apply the qft and Hadamard on first `n` qubits,
we could use [`Concentrator`](@ref), which creates a context of
a sub-scope of the qubits.

````julia
PE(n, m, U) =
    chain(n+m, # total number of the qubits
        concentrate(Hadamards(n), 1:n), # apply H in local scope
        ControlU(n, m, U),
        concentrate(QFT(n)', 1:n))
````


````
PE (generic function with 1 method)
````





we use the first `n` qubits as the output space to store phase ``ϕ``, and the
other `m` qubits as the input state which corresponds to an eigenvector of
oracle matrix `U`.

The concentrator here uses [`focus!`](@ref) and [`relax!`](@ref) to manage
a local scope of quantum circuit, and only active the first `n` qubits while applying
the block inside the concentrator context, and the scope will be [`relax!`](@ref)ed
back, after the context. This is equivalent to manually [`focus!`](@ref)
then [`relax!`](@ref)

fullly activated

````julia
r = rand_state(5)
````


````
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 5/5
````





first 3 qubits activated

````julia
focus!(r, 1:3)
````


````
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 3/5
````





relax back to the original

````julia
relax!(r, 1:3)
````


````
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 5/5
````





In this way, we will be able to apply small operator directly
on the subset of the qubits.

Details about the algorithm can be found here:
[Quantum Phase Estimation Algorithm](ttps://en.wikipedia.org/wiki/Quantum_phase_estimation_algorithm)

Now let's check the results of our phase estimation.


First we need to set up a unitary with known phase, we set the phase to be
0.75, which is `0.75 * 2^3 == 6 == 0b110` .

````julia
using LinearAlgebra

N, M = 3, 5
P = eigen(rand_unitary(1<<M)).vectors
θ = Int(0b110) / 1<<N
phases = rand(1<<M)
phases[0b010+1] = θ
U = P * Diagonal(exp.(2π * im * phases)) * P'
````


````
32×32 Array{Complex{Float64},2}:
  -0.0413438-0.0636054im   …    0.190763+0.0620385im 
   0.0259797+0.0465801im       0.0150829+0.0575048im 
   -0.147225+0.121178im        -0.117897+0.258642im  
   -0.174325-0.0251342im       0.0651907-0.0268478im 
   -0.203596-0.133765im         0.137496+0.137912im  
 -0.00676258-0.00678356im  …   0.0184228+0.045387im  
   0.0646907+0.10334im         0.0274704-0.009996im  
  -0.0340245+0.161723im        -0.219399+0.0698527im 
    0.050553-0.084142im        -0.128248-0.00814664im
   0.0542558-0.286343im       -0.0291044+0.133584im  
            ⋮              ⋱                         
    0.142599+0.0393999im       0.0386863-0.0429105im 
    0.121193-0.108744im       -0.0591857-0.114916im  
    0.227741-0.169482im    …   0.0331019-0.0277773im 
  -0.0213868-0.0473522im        0.172307+0.0680361im 
   0.0166624-0.0561616im       -0.062673-0.086537im  
   -0.131748-0.0183856im        0.276368+0.088108im  
   0.0215932-0.322125im        0.0107398-0.0983985im 
   0.0349548+0.0895041im   …   0.0153706-0.00197784im
   -0.124275-0.0713032im       0.0227648-0.143886im
````





and then generate the state ``ψ``

````julia
psi = P[:, 3]
````


````
32-element Array{Complex{Float64},1}:
  0.018004589258473275 + 0.047049156784694166im
   -0.1196496501409389 - 0.024530025857502226im
  -0.04394124403138487 + 0.17384251581647972im 
    0.2968524458612214 + 0.0im                 
  -0.16238094420193197 + 0.16739692134590442im 
  -0.20416361222898163 + 0.1195101433519263im  
   0.11472412527802464 - 0.13824646797170478im 
   0.07595464946705258 - 0.12252680801289521im 
   0.06151099915443516 - 0.03964547182868243im 
   0.04220417561523802 - 0.07587547337494452im 
                       ⋮                       
   0.19061161147104314 - 0.1559919731516806im  
   0.18391308495894076 + 0.15301480296821743im 
  0.008569470599353916 + 0.13006665818783475im 
   0.09145264130764236 - 0.11770155604964955im 
   0.10525466116953876 - 0.06835249599843052im 
   0.14639263780750983 - 0.037089858768175867im
 -0.024885015816634784 + 0.20555636040956726im 
    0.1936366028828697 + 0.01611254637409497im 
   0.10393045803532254 - 0.1570180583100812im
````





In the phase estimation process, we will feed the state to circuit and measure
the first `n` qubits processed by iQFT.

````julia
r = join(ArrayReg(psi), zero_state(N))
r |> PE(N, M, U)
````


````
ArrayReg{1, Complex{Float64}, Array...}
    active qubits: 8/8
````





Since our phase can be represented by 3 qubits precisely, we only need to measure once

````julia
results = measure(r, 1:N; nshots=1)
````


````
1-element Array{BitBasis.BitStr{3,Int64},1}:
 011 ₍₂₎
````





Recall that our QFT's bit numbering is reversed, let's reverse it back

````julia
using BitBasis
estimated_phase = bfloat(results[]; nbits=N)
````


````
0.75
````





the phase is exactly `0.75`!
