var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": "CurrentModule = Yao"
},

{
    "location": "#Yao-1",
    "page": "Home",
    "title": "Yao",
    "category": "section",
    "text": "A General Purpose Quantum Computation Simulation FrameworkWelcome to Yao, a Flexible, Extensible, Efficient Framework for Quantum Algorithm Design. Yao (幺) is the Chinese character for unitary. It is also means the first (一) in Chinese (it is the first released package from QuantumBFS).We aim to provide a powerful tool for researchers, students to study and explore quantum computing in near term future, before quantum computer being used in large-scale."
},

{
    "location": "#Tutorial-1",
    "page": "Home",
    "title": "Tutorial",
    "category": "section",
    "text": "Pages = [\n    \"tutorial/GHZ.md\",\n    \"tutorial/QFT.md\",\n    \"tutorial/Grover.md\",\n    \"tutorial/Diff.md\",\n    \"tutorial/QCBM.md\",\n]\nDepth = 1"
},

{
    "location": "#Manual-1",
    "page": "Home",
    "title": "Manual",
    "category": "section",
    "text": "Pages = [\n    \"man/interfaces.md\",\n    \"man/registers.md\",\n    \"man/blocks.md\",\n    \"man/intrinsics.md\",\n]\nDepth = 1"
},

{
    "location": "tutorial/GHZ/#",
    "page": "Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit",
    "title": "Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial/GHZ/#Prepare-Greenberger–Horne–Zeilinger-state-with-Quantum-Circuit-1",
    "page": "Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit",
    "title": "Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit",
    "category": "section",
    "text": "First, you have to use this package in Julia.using YaoThen let\'s define the oracle, it is a function of the number of qubits. The circuit looks like this:(Image: ghz)n = 4\ncircuit(n) = chain(\n    n,\n    repeat(X, [1, ]),\n    kron(i=>H for i in 2:n),\n    control([2, ], 1=>X),\n    control([4, ], 3=>X),\n    control([3, ], 1=>X),\n    control([4, ], 3=>X),\n    kron(i=>H for i in 1:n),\n)Let me explain what happens here. Firstly, we have a X gate which is applied to the first qubit. We need decide how we calculate this numerically, Yao offers serveral different approach to this. The simplest (but not the most efficient) one is to use kronecker product which will product X with I on other lines to gather an operator in the whole space and then apply it to the register. The first argument n means the number of qubits.kron(n, 1=>X)Similar with kron, we then need to apply some controled gates.control(n, [2, ], 1=>X)This means there is a X gate on the first qubit that is controled by the second qubit. In fact, you can also create a controled gate with multiple control qubits, likecontrol(n, [2, 3], 1=>X)In the end, we need to apply H gate to all lines, of course, you can do it by kron, but we offer something more efficient called roll, this applies a single gate each time on each qubit without calculating a new large operator, which will be extremely efficient for calculating small gates that tiles on almost every lines.The whole circuit is a chained structure of the above blocks. And we actually store a quantum circuit in a tree structure.circuitAfter we have an circuit, we can construct a quantum register, and input it into the oracle. You will then receive this register after processing it.r = apply!(register(bit\"0000\"), circuit(4))Let\'s check the output:statevec(r)We have a GHZ state here, try to measure the first qubitmeasure(r, 1000)(Image: GHZ)GHZ state will collapse to 0000rangle or 1111rangle due to entanglement!"
},

{
    "location": "tutorial/QFT/#",
    "page": "Quantum Fourier Transformation and Phase Estimation",
    "title": "Quantum Fourier Transformation and Phase Estimation",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial/QFT/#Quantum-Fourier-Transformation-and-Phase-Estimation-1",
    "page": "Quantum Fourier Transformation and Phase Estimation",
    "title": "Quantum Fourier Transformation and Phase Estimation",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial/QFT/#Quantum-Fourier-Transformation-1",
    "page": "Quantum Fourier Transformation and Phase Estimation",
    "title": "Quantum Fourier Transformation",
    "category": "section",
    "text": "(Image: ghz)using Yao\n\n# Control-R(k) gate in block-A\nA(i::Int, j::Int, k::Int) = control([i, ], j=>shift(2π/(1<<k)))\n# block-B\nB(n::Int, i::Int) = chain(i==j ? kron(i=>H) : A(j, i, j-i+1) for j = i:n)\nQFT(n::Int) = chain(n, B(n, i) for i = 1:n)\n\n# define QFT and IQFT block.\nnum_bit = 5\nqft = QFT(num_bit)\niqft = qft\'   # get the hermitian conjugateThe basic building block - controled phase shift gate is defined asR(k)=beginbmatrix\n1  0\n0  expleft(frac2pi i2^kright)\nendbmatrixIn Yao, factory methods for blocks will be loaded lazily. For example, if you missed the total number of qubits of chain, then it will return a function that requires an input of an integer. So the following two statements are equivalentcontrol([4, ], 1=>shift(-2π/(1<<4)))(5) == control(5, [4, ], 1=>shift(-2π/(1<<4)))Both of then will return a ControlBlock instance. If you missed the total number of qubits. It is OK. Just go on, it will be filled when its possible.Once you have construct a block, you can inspect its matrix using mat function. Let\'s construct the circuit in dashed box A, and see the matrix of R_4 gatejulia> a = A(4, 1, 4)(5)\nTotal: 5, DataType: Complex{Float64}\ncontrol(4)\n└─ 1=>Phase Shift Gate:-0.39269908169872414\n\n\njulia> mat(a.block)\n2×2 Diagonal{Complex{Float64}}:\n 1.0+0.0im          ⋅         \n     ⋅      0.92388-0.382683imSimilarly, you can use put and chain to construct PutBlock (basic placement of a single gate) and ChainBlock (sequential application of MatrixBlocks) instances. Yao.jl view every component in a circuit as an AbstractBlock, these blocks can be integrated to perform higher level functionality.You can check the result using classical fft# if you\'re using lastest julia, you need to add the fft package.\nusing FFTW: fft, ifft\nusing LinearAlgebra: I\nusing Test\n\n@test chain(num_bit, qft, iqft) |> mat ≈ I\n\n# define a register and get its vector representation\nreg = rand_state(num_bit)\nrv = reg |> statevec |> copy\n\n# test fft\nreg_qft = apply!(copy(reg) |>invorder!, qft)\nkv = ifft(rv)*sqrt(length(rv))\n@test reg_qft |> statevec ≈ kv\n\n# test ifft\nreg_iqft = apply!(copy(reg), iqft)\nkv = fft(rv)/sqrt(length(rv))\n@test reg_iqft |> statevec ≈ kv |> invorderQFT and IQFT are different from FFT and IFFT in three ways,they are different by a factor of sqrt2^n with n the number of qubits.\nthe little end and big end will exchange after applying QFT or IQFT.\ndue to the convention, QFT is more related to IFFT rather than FFT."
},

{
    "location": "tutorial/QFT/#Phase-Estimation-1",
    "page": "Quantum Fourier Transformation and Phase Estimation",
    "title": "Phase Estimation",
    "category": "section",
    "text": "Since we have QFT and IQFT blocks we can then use them to realize phase estimation circuit, what we want to realize is the following circuit (Image: phase estimation)In the following simulation, we use equivalent QFTBlock in the Yao.Zoo module rather than the above chain block, it is faster than the above construction because it hides all the simulation details (yes, we are cheating :D) and get the equivalent output.using Yao\nusing Yao.Blocks\nusing Yao.Intrinsics\n\nfunction phase_estimation(reg1::DefaultRegister, reg2::DefaultRegister, U::GeneralMatrixGate{N}, nshot::Int=1) where {N}\n    M = nqubits(reg1)\n    iqft = QFT(M) |> adjoint\n    HGates = rollrepeat(M, H)\n\n    control_circuit = chain(M+N)\n    for i = 1:M\n        push!(control_circuit, control(M+N, (i,), (M+1:M+N...,)=>U))\n        if i != M\n            U = matrixgate(mat(U) * mat(U))\n        end\n    end\n\n    # calculation\n    # step1 apply hadamard gates.\n    apply!(reg1, HGates)\n    # join two registers\n    reg = join(reg1, reg2)\n    # using iqft to read out the phase\n    apply!(reg, sequence(control_circuit, focus(1:M...), iqft))\n    # measure the register (on focused bits), if the phase can be exactly represented by M qubits, only a single shot is needed.\n    res = measure(reg, nshot)\n    # inverse the bits in result due to the exchange of big and little ends, so that we can get the correct phase.\n    breflect.(M, res)./(1<<M), reg\nendHere, reg1 (Q_1-5) is used as the output space to store phase ϕ, and reg2 (Q_6-8) is the input state which corresponds to an eigenvector of oracle matrix U. The algorithm detials can be found here.In this function, HGates corresponds to circuit block in dashed box A, control_circuit corresponds to block in dashed box B. matrixgate is a factory function for GeneralMatrixGate.Here, the only difficult concept is focus, focus returns a FunctionBlock, that will make focused bits the active bits. An operator sees only active bits, and operating active space is more efficient, most importantly, it becomes much easier to integrate blocks. However, it has the potential ability to change line orders, for safety consideration, you may also need safer Concentrator.r = rand_state(6)\napply!(r, focus(4,1,2))  # or equivalently using focus!(r, [4,1,2])\nnactive(r)Then we will have a check to above functionusing LinearAlgebra: qr, Diagonal\nrand_unitary(N::Int) = qr(randn(N, N)).Q\n\nM = 5\nN = 3\n\n# prepair oracle matrix U\nV = rand_unitary(1<<N)\nphases = rand(1<<N)\nϕ = Int(0b11101)/(1<<M)\nphases[3] = ϕ  # set the phase of the 3rd eigenstate manually.\nsigns = exp.(2pi*im.*phases)\nU = V*Diagonal(signs)*V\'  # notice U is unitary\n\n# the state with phase ϕ\npsi = U[:,3]\n\nres, reg = phase_estimation(zero_state(M), register(psi), GeneralMatrixGate(U))\nprintln(\"Phase is 2π * $(res[]), the exact value is 2π * $ϕ\")"
},

{
    "location": "tutorial/Grover/#",
    "page": "Grover Search and Quantum Inference",
    "title": "Grover Search and Quantum Inference",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial/Grover/#Grover-Search-and-Quantum-Inference-1",
    "page": "Grover Search and Quantum Inference",
    "title": "Grover Search and Quantum Inference",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial/Grover/#Grover-Search-1",
    "page": "Grover Search and Quantum Inference",
    "title": "Grover Search",
    "category": "section",
    "text": "(Image: grover)First, we construct the reflection block R(psirangle) = 2psiranglelanglepsi-1, given we know how to construct psirangle=A0rangle. Then it equivalent to construct R(psirangle) = A(20ranglelangle 0-1)A^daggerusing Yao\nusing Yao.Blocks\nusing Test, LinearAlgebra\nusing StatsBase\n\n\"\"\"\nA way to construct oracle, e.g. inference_oracle([1,2,-3,5]) will\ninvert the sign when a qubit configuration matches: 1=>1, 2=>1, 3=>0, 5=>1.\n\"\"\"\nfunction inference_oracle(locs::Vector{Int})\n    control(locs[1:end-1], abs(locs[end]) => (locs[end]>0 ? Z : chain(phase(π), Z)))\nend\n\nfunction reflectblock(A::MatrixBlock{N}) where N\n    chain(N, A |> adjoint, inference_oracle(-collect(1:N)), A)\nend\n\nnbit = 12\nA = repeat(nbit, H)\nref = reflectblock(A)\n\n@testset \"test reflect\" begin\n    reg = rand_state(nbit)\n    ref_vec = apply!(zero_state(nbit), A) |> statevec\n    v0 = reg |> statevec\n    @test -2*(ref_vec\'*v0)*ref_vec + v0 ≈ apply!(copy(reg), ref) |> statevec\nendThen we define the oracle and target state# first, construct the oracle with desired state in the range 100-105.\noracle!(reg::DefaultRegister) = (reg.state[100:105,:]*=-1; reg)\n\n# transform it into a function block, so it can be put inside a `Sequential`.\nfb_oracle = FunctionBlock{:Oracle}(reg->oracle!(reg))\n\n\"\"\"\nratio of components in a wavefunction that flip sign under oracle.\n\"\"\"\nfunction prob_match_oracle(psi::DefaultRegister, oracle)\n    fliped_reg = apply!(register(ones(ComplexF64, 1<<nqubits(psi))), oracle)\n    match_mask = fliped_reg |> statevec |> real .< 0\n    norm(statevec(psi)[match_mask])^2\nend\n\n# uniform state as initial state\npsi0 = apply!(zero_state(nbit), A)\n\n# the number of grover steps that can make it reach first maximum overlap.\nnum_grover_step(prob::Real) = Int(round(pi/4/sqrt(prob)))-1\nniter = num_grover_step(prob_match_oracle(psi0, fb_oracle))\n\n# construct the whole circuit\ngb = sequence(sequence(fb_oracle, ref) for i = 1:niter);Now, let\'s start trainingfor (i, blk) in enumerate(gb)\n    apply!(psi0, blk)\n    overlap = prob_match_oracle(psi0, fb_oracle)\n    println(\"step $i, overlap = $overlap\")\nendThe above is the standard Grover Search algorithm, it can find target state in O(sqrt N) time, with N the size of an unordered database. Similar algorithm can be used in more useful applications, like inference, i.e. get conditional probability distribution p(xy) given p(x y).function rand_circuit(nbit::Int, ngate::Int)\n    circuit = chain(nbit)\n    gate_list = [X, H, Ry(0.3), CNOT]\n    for i = 1:ngate\n        gate = rand(gate_list)\n        push!(circuit, put(nbit, (sample(1:nbit, nqubits(gate),replace=false)...,)=>gate))\n    end\n    circuit\nend\nA = rand_circuit(nbit, 200)\npsi0 = apply!(zero_state(nbit), A)\n\n# now we want to search the subspace with [1,3,5,8,9,11,12]\n# fixed to 1 and [4,6] fixed to 0.\nevidense = [1, 3, -4, 5, -6, 8, 9, 11, 12]\n\n\"\"\"\nDoing Inference, psi is the initial state,\nthe target is to search target space with specific evidense.\ne.g. evidense [1, -3, 6] means the [1, 3, 6]-th bits take value [1, 0, 1].\n\"\"\"\noracle_infer = inference_oracle(evidense)(nqubits(psi0))\n\nniter = num_grover_step(prob_match_oracle(psi0, oracle_infer))\ngb_infer = chain(nbit, chain(oracle_infer, reflectblock(A)) for i = 1:niter);Now, let\'s start trainingfor (i, blk) in enumerate(gb_infer)\n    apply!(psi0, blk)\n    p_target = prob_match_oracle(psi0, oracle_infer)\n    println(\"step $i, overlap^2 = $p_target\")\nendHere is an application, suppose we have constructed some digits and stored it in a wave vector.using Yao.Intrinsics\n\nx1 = [0 1 0; 0 1 0; 0 1 0; 0 1 0; 0 1 0]\nx2 = [1 1 1; 0 0 1; 1 1 1; 1 0 0; 1 1 1]\nx0 = [1 1 1; 1 0 1; 1 0 1; 1 0 1; 1 1 1]\n\nnbit = 15\nv = zeros(1<<nbit)\n\n# they occur with different probabilities.\nfor (x, p) in [(x0, 0.7), (x1, 0.29), (x2,0.01)]\n    v[(x |> vec |> BitArray |> packbits)+1] = sqrt(p)\nendPlot them, you will see these digits(Image: digits)Then we construct the inference circuit. Here, we choose to use reflect to construct a ReflectBlock, instead of constructing it explicitly.rb = reflect(copy(v))\npsi0 = register(v)\n\n# we want to find the digits with the first 5 qubits [1, 0, 1, 1, 1].\nevidense = [1, -2, 3, 4, 5]\noracle_infer = inference_oracle(evidense)(nbit)\n\nniter = num_grover_step(prob_match_oracle(psi0, oracle_infer))\ngb_infer = chain(nbit, chain(oracle_infer, rb) for i = 1:niter)Now, let\'s start trainingfor (i, blk) in enumerate(gb_infer)\n    apply!(psi0, blk)\n    p_target = prob_match_oracle(psi0, oracle_infer)\n    println(\"step $i, overlap^2 = $p_target\")\nendThe result ispl = psi0 |> probs\nconfig = findfirst(pi->pi>0.5, pl) - 1 |> bitarray(nbit)\nres = reshape(config, 5,3)It is 2 ~(Image: infer)Congratuations! You get state of art quantum inference circuit!"
},

{
    "location": "tutorial/Diff/#",
    "page": "Differentiatiable Quantum Circuits",
    "title": "Differentiatiable Quantum Circuits",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial/Diff/#Differentiatiable-Quantum-Circuits-1",
    "page": "Differentiatiable Quantum Circuits",
    "title": "Differentiatiable Quantum Circuits",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial/Diff/#Classical-back-propagation-1",
    "page": "Differentiatiable Quantum Circuits",
    "title": "Classical back propagation",
    "category": "section",
    "text": "Back propagation has O(M) complexity in obtaining gradients, with M the number of circuit parameters. We can use autodiff(:BP) to mark differentiable units in a circuit. Let\'s see an example."
},

{
    "location": "tutorial/Diff/#Example:-Classical-back-propagation-1",
    "page": "Differentiatiable Quantum Circuits",
    "title": "Example: Classical back propagation",
    "category": "section",
    "text": "using Yao\ncircuit = chain(4, repeat(4, H, 1:4), put(4, 3=>Rz(0.5)), control(2, 1=>X), put(4, 4=>Ry(0.2)))\ncircuit = circuit |> autodiff(:BP)From the output, we can see parameters of blocks marked by [∂] will be differentiated automatically.op = put(4, 3=>Y);  # loss is defined as its expectation.\nψ = rand_state(4);\nψ |> circuit;\nδ = ψ |> op;     # ∂f/∂ψ*\nbackward!(δ, circuit);    # classical back propagation!Here, the loss is L = <ψ|op|ψ>, δ = ∂f/∂ψ* is the error to be back propagated. The gradient is related to δ as fracpartial fpartialtheta = 2Refracpartial fpartialpsi^*fracpartial psi^*partialthetaIn face, backward!(δ, circuit) on wave function is equivalent to calculating δ |> circuit\' (apply!(reg, Daggered{<:BPDiff})). This function is overloaded so that gradientis for parameters are also calculated and stored in BPDiff block at the same time.Finally, we use gradient to collect gradients in the ciruits.g1 = gradient(circuit)  # collect gradientnote: Note\nIn real quantum devices, gradients can not be back propagated, this is why we need the following section."
},

{
    "location": "tutorial/Diff/#Quantum-circuit-differentiation-1",
    "page": "Differentiatiable Quantum Circuits",
    "title": "Quantum circuit differentiation",
    "category": "section",
    "text": "Experimental applicable differentiation strategies are based on the following two papersQuantum Circuit Learning, Kosuke Mitarai, Makoto Negoro, Masahiro Kitagawa, Keisuke Fujii\nDifferentiable Learning of Quantum Circuit Born Machine, Jin-Guo Liu, Lei WangThe former differentiation scheme is for observables, and the latter is for V-statistics. One may find the derivation of both schemes in this post.Realizable quantum circuit gradient finding algorithms have complexity O(M^2)."
},

{
    "location": "tutorial/Diff/#Example:-Practical-quantum-differenciation-1",
    "page": "Differentiatiable Quantum Circuits",
    "title": "Example: Practical quantum differenciation",
    "category": "section",
    "text": "We use QDiff block to mark differentiable circuitsusing Yao, Yao.Blocks\nc = chain(put(4, 1=>Rx(0.5)), control(4, 1, 2=>Ry(0.5)), kron(4, 2=>Rz(0.3), 3=>Rx(0.7))) |> autodiff(:QC)  # automatically mark differentiable blocksBlocks marked by [̂∂] will be differentiated.dbs = collect(c, QDiff)  # collect all QDiff blocksHere, we recommend collect QDiff blocks into a sequence using collect API for future calculations. Then, we can get the gradient one by one, using opdiffed = opdiff(dbs[1], put(4, 1=>Z)) do   # the exact differentiation with respect to first QDiff block.\n    zero_state(4) |> c\nendHere, contents in the do-block returns the loss, it must be the expectation value of an observable.For results checking, we get the numeric gradient use numdiffed = numdiff(dbs[1]) do    # compare with numerical differentiation\n   expect(put(4, 1=>Z), zero_state(4) |> c) |> real\nendThis numerical differentiation scheme is always applicable (even the loss is not an observable), but with numeric errors introduced by finite step size.We can also get all gradients using broadcastinged = opdiff.(()->zero_state(4) |> c, dbs, Ref(kron(4, 1=>Z, 2=>X)))   # using broadcast to get all gradients.note: Note\nSince BP is not implemented for QDiff blocks, the memory consumption is much less since we don\'t cache intermediate results anymore."
},

{
    "location": "tutorial/QCBM/#",
    "page": "Quantum Circuit Born Machine",
    "title": "Quantum Circuit Born Machine",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial/QCBM/#Quantum-Circuit-Born-Machine-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Quantum Circuit Born Machine",
    "category": "section",
    "text": "Quantum circuit born machine is a fresh approach to quantum machine learning. It use a parameterized quantum circuit to learning machine learning tasks with gradient based optimization. In this tutorial, we will show how to implement it with Yao (幺) framework.about the frameworkusing Yao # hide\n@doc 幺"
},

{
    "location": "tutorial/QCBM/#Training-target-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Training target",
    "category": "section",
    "text": "a gaussian distributionfunction gaussian_pdf(n, μ, σ)\n    x = collect(1:1<<n)\n    pl = @. 1 / sqrt(2pi * σ^2) * exp(-(x - μ)^2 / (2 * σ^2))\n    pl / sum(pl)\nendf(x left mu sigma^2right) = frac1sqrt2pisigma^2 e^-frac(x-mu)^22sigma^2const n = 6\nconst maxiter = 20\npg = gaussian_pdf(n, 2^5-0.5, 2^4)\nnothing # hidefig = plot(0:1<<n-1, pg)(Image: Gaussian Distribution)"
},

{
    "location": "tutorial/QCBM/#Build-Circuits-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Build Circuits",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial/QCBM/#Building-Blocks-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Building Blocks",
    "category": "section",
    "text": "Gates are grouped to become a layer in a circuit, this layer can be Arbitrary Rotation or CNOT entangler. Which are used as our basic building blocks of Born Machines.(Image: differentiable ciruit)"
},

{
    "location": "tutorial/QCBM/#Arbitrary-Rotation-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Arbitrary Rotation",
    "category": "section",
    "text": "Arbitrary Rotation is built with Rotation Gate on Z, Rotation Gate on X and Rotation Gate on Z:Rz(theta) cdot Rx(theta) cdot Rz(theta)Since our input will be a 0dots 0rangle state. The first layer of arbitrary rotation can just use Rx(theta) cdot Rz(theta) and the last layer of arbitrary rotation could just use Rz(theta)cdot Rx(theta)In 幺, every Hilbert operator is a block type, this includes all quantum gates and quantum oracles. In general, operators appears in a quantum circuit can be divided into Composite Blocks and Primitive Blocks.We follow the low abstraction principle and thus each block represents a certain approach of calculation. The simplest Composite Block is a Chain Block, which chains other blocks (oracles) with the same number of qubits together. It is just a simple mathematical composition of operators with same size. e.g.textchain(X Y Z) iff X cdot Y cdot ZWe can construct an arbitrary rotation block by chain Rz, Rx, Rz together.chain(Rz(0), Rx(0), Rz(0))Rx, Ry and Rz will construct new rotation gate, which are just shorthands for rot(X, 0.0), etc.Then, let\'s pile them up vertically with another method called rollrepeatlayer(x::Symbol) = layer(Val(x))\nlayer(::Val{:first}) = rollrepeat(chain(Rx(0), Rz(0)))In 幺, the factory method rollrepeat will construct a block called Roller. It is mathematically equivalent to the kronecker product of all operators in this layer:rollrepeat(n U) iff roll(n texti=U for i = 1n) iff kron(n texti=U for i=1n) iff U otimes dots otimes Uroll(4, i=>X for i = 1:4)rollrepeat(4, X)kron(4, i=>X for i = 1:4)However, kron is calculated differently comparing to roll. In principal, Roller will be able to calculate small blocks with same size with higher efficiency. But for large blocks Roller may be slower. In 幺, we offer you this freedom to choose the most suitable solution.all factory methods will lazy evaluate the first arguements, which is the number of qubits. It will return a lambda function that requires a single interger input. The instance of desired block will only be constructed until all the information is filled.rollrepeat(X)rollrepeat(X)(4)When you filled all the information in somewhere of the declaration, 幺 will be able to infer the others.chain(4, rollrepeat(X), rollrepeat(Y))We will now define the rest of rotation layerslayer(::Val{:last}) = rollrepeat(chain(Rz(0), Rx(0)))\nlayer(::Val{:mid}) = rollrepeat(chain(Rz(0), Rx(0), Rz(0)))"
},

{
    "location": "tutorial/QCBM/#CNOT-Entangler-1",
    "page": "Quantum Circuit Born Machine",
    "title": "CNOT Entangler",
    "category": "section",
    "text": "Another component of quantum circuit born machine is several CNOT operators applied on different qubits.entangler(pairs) = chain(control([ctrl, ], target=>X) for (ctrl, target) in pairs)We can then define such a born machinefunction QCBM(n, nlayer, pairs)\n    circuit = chain(n)\n    push!(circuit, layer(:first))\n\n    for i = 1:(nlayer - 1)\n        push!(circuit, cache(entangler(pairs)))\n        push!(circuit, layer(:mid))\n    end\n\n    push!(circuit, cache(entangler(pairs)))\n    push!(circuit, layer(:last))\n\n    circuit\nend\nnothing # hideWe use the method cache here to tag the entangler block that it should be cached after its first run, because it is actually a constant oracle. Let\'s see what will be constructedQCBM(4, 1, [1=>2, 2=>3, 3=>4])Let\'s define a circuit to use latercircuit = QCBM(6, 10, [1=>2, 3=>4, 5=>6, 2=>3, 4=>5, 6=>1]) |> autodiff(:QC)\nnothing # hideHere, the function autodiff(:QC) will mark rotation gates in a circuit as differentiable automatically."
},

{
    "location": "tutorial/QCBM/#MMD-Loss-and-Gradients-1",
    "page": "Quantum Circuit Born Machine",
    "title": "MMD Loss & Gradients",
    "category": "section",
    "text": "The MMD loss is describe below:beginaligned\nmathcalL = left sum_x p theta(x) phi(x) - sum_x pi(x) phi(x) right^2\n            = langle K(x y) rangle_x sim p_theta ysim p_theta - 2 langle K(x y) rangle_xsim p_theta ysim pi + langle K(x y) rangle_xsimpi ysimpi\nendalignedWe will use a squared exponential kernel here.struct Kernel\n    sigma::Float64\n    matrix::Matrix{Float64}\nend\n\nfunction Kernel(nqubits, sigma)\n    basis = collect(0:(1<<nqubits - 1))\n    Kernel(sigma, kernel_matrix(basis, basis, sigma))\nend\n\nexpect(kernel::Kernel, px::Vector{Float64}, py::Vector{Float64}) = px\' * kernel.matrix * py\nloss(qcbm, kernel::Kernel, ptrain) = (p = get_prob(qcbm) - ptrain; expect(kernel, p, p))\nnothing # hideNext, let\'s define the kernel matrixfunction kernel_matrix(x, y, sigma)\n    dx2 = (x .- y\').^2\n    gamma = 1.0 / (2 * sigma)\n    K = exp.(-gamma * dx2)\n    K\nend\nnothing # hide"
},

{
    "location": "tutorial/QCBM/#Gradients-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Gradients",
    "category": "section",
    "text": "the gradient of MMD loss isbeginaligned\nfracpartial mathcalLpartial theta^i_l = langle K(x y) rangle_xsim p_theta^+ ysim p_theta - langle K(x y) rangle_xsim p_theta^- ysim p_theta\n- langle K(x y) rangle _xsim p_theta^+ ysimpi + langle K(x y) rangle_xsim p_theta^- ysimpi\nendalignedWe have to update one parameter of each rotation gate each time, and calculate its gradient then collect them. Since we will need to calculate the probability from the state vector frequently, let\'s define a shorthand first.Firstly, you have to define a quantum register. Each run of a QCBM\'s input is a simple 00cdots 0rangle state. We provide string literal bit to help you define one-hot state vectors like thisr = register(bit\"0000\")Now, we define its shorthandget_prob(qcbm) = apply!(register(bit\"0\"^6), qcbm) |> statevec .|> abs2"
},

{
    "location": "tutorial/QCBM/#Optimizer-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Optimizer",
    "category": "section",
    "text": "We will use the Adam optimizer. Since we don\'t want you to install another package for this, the following code for this optimizer is copied from Knet.jlReference: Kingma, D. P., & Ba, J. L. (2015). Adam: a Method for Stochastic Optimization. International Conference on Learning Representations, 1–13.using LinearAlgebra\n\nmutable struct Adam\n    lr::AbstractFloat\n    gclip::AbstractFloat\n    beta1::AbstractFloat\n    beta2::AbstractFloat\n    eps::AbstractFloat\n    t::Int\n    fstm\n    scndm\nend\n\nAdam(; lr=0.001, gclip=0, beta1=0.9, beta2=0.999, eps=1e-8)=Adam(lr, gclip, beta1, beta2, eps, 0, nothing, nothing)\n\nfunction update!(w, g, p::Adam)\n    gclip!(g, p.gclip)\n    if p.fstm===nothing; p.fstm=zeros(w); p.scndm=zeros(w); end\n    p.t += 1\n    lmul!(p.beta1, p.fstm)\n    BLAS.axpy!(1-p.beta1, g, p.fstm)\n    lmul!(p.beta2, p.scndm)\n    BLAS.axpy!(1-p.beta2, g .* g, p.scndm)\n    fstm_corrected = p.fstm / (1 - p.beta1 ^ p.t)\n    scndm_corrected = p.scndm / (1 - p.beta2 ^ p.t)\n    BLAS.axpy!(-p.lr, @.(fstm_corrected / (sqrt(scndm_corrected) + p.eps)), w)\nend\n\nfunction gclip!(g, gclip)\n    if gclip == 0\n        g\n    else\n        gnorm = vecnorm(g)\n        if gnorm <= gclip\n            g\n        else\n            BLAS.scale!(gclip/gnorm, g)\n        end\n    end\nend"
},

{
    "location": "tutorial/QCBM/#Start-Training-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Start Training",
    "category": "section",
    "text": "The training of the quantum circuit is simple, just iterate through the steps.function train!(qcbm, ptrain, optim; learning_rate=0.1, niter=50)\n    # initialize the parameters\n    params = 2pi * rand(nparameters(qcbm))\n    dispatch!(qcbm, params)\n    kernel = Kernel(nqubits(qcbm), 0.25)\n\n    n, nlayers = nqubits(qcbm), (length(qcbm)-1)÷2\n    history = Float64[]\n\n    for i = 1:niter\n        grad = exactdiff.(n, nlayers, qcbm, kernel, ptrain)\n        curr_loss = loss(qcbm, kernel, ptrain)\n        push!(history, curr_loss)        \n        params = parameters(qcbm)\n        update!(params, grad, optim)\n        dispatch!(qcbm, params)\n    end\n    history\nendoptim = Adam(lr=0.1)\nhis = train!(circuit, pg, optim, niter=50, learning_rate=0.1)\nplot(1:50, his, xlabel=\"iteration\", ylabel=\"loss\")(Image: History)p = get_prob(circuit)\nplot(0:1<<n-1, p, pg, xlabel=\"x\", ylabel=\"p\")(Image: Learnt Distribution)"
},

{
    "location": "man/yao/#",
    "page": "Yao",
    "title": "Yao",
    "category": "page",
    "text": ""
},

{
    "location": "man/yao/#Yao.Yao",
    "page": "Yao",
    "title": "Yao.Yao",
    "category": "module",
    "text": "Extensible Framework for Quantum Algorithm Design for Humans.\n\n简单易用可扩展的量子算法设计框架。\n\n\n\n\n\n"
},

{
    "location": "man/yao/#Yao.幺",
    "page": "Yao",
    "title": "Yao.幺",
    "category": "module",
    "text": "Extensible Framework for Quantum Algorithm Design for Humans.\n\n简单易用可扩展的量子算法设计框架。\n\n幺 means unitary in Chinese.\n\n\n\n\n\n"
},

{
    "location": "man/yao/#Yao.nactive",
    "page": "Yao",
    "title": "Yao.nactive",
    "category": "function",
    "text": "nactive(x) -> Int\n\nReturns number of active qubits\n\n\n\n\n\n"
},

{
    "location": "man/yao/#Yao.nqubits",
    "page": "Yao",
    "title": "Yao.nqubits",
    "category": "function",
    "text": "nqubits(m::AbstractRegister) -> Int\n\nReturns number of qubits in a register,\n\nnqubits(m::AbstractBlock) -> Int\n\nReturns number of qubits applied for a block,\n\nnqubits(m::AbstractArray) -> Int\n\nReturns size of the first dimension of an array, in 2^nqubits.\n\n\n\n\n\n"
},

{
    "location": "man/yao/#Yao.reorder",
    "page": "Yao",
    "title": "Yao.reorder",
    "category": "function",
    "text": "Reorder the lines of qubits.\n\n\n\n\n\n"
},

{
    "location": "man/yao/#Yao-1",
    "page": "Yao",
    "title": "Yao",
    "category": "section",
    "text": "(Image: Framework-Structure)Modules = [Yao]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/interfaces/#",
    "page": "Interfaces",
    "title": "Interfaces",
    "category": "page",
    "text": "CurrentModule = Yao.Interfaces"
},

{
    "location": "man/interfaces/#Yao.Blocks.H",
    "page": "Interfaces",
    "title": "Yao.Blocks.H",
    "category": "constant",
    "text": "H\n\nThe Hadamard gate acts on a single qubit. It maps the basis state 0rangle to frac0rangle + 1ranglesqrt2 and 1rangle to frac0rangle - 1ranglesqrt2, which means that a measurement will have equal probabilities to become 1 or 0. It is representated by the Hadamard matrix:\n\nH = frac1sqrt2 beginpmatrix\n1  1 \n1  -1\nendpmatrix\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.X",
    "page": "Interfaces",
    "title": "Yao.Blocks.X",
    "category": "constant",
    "text": "X\n\nThe Pauli-X gate acts on a single qubit. It is the quantum equivalent of the NOT gate for classical computers (with respect to the standard basis 0rangle, 1rangle). It is represented by the Pauli X matrix:\n\nX = beginpmatrix\n0  1\n1  0\nendpmatrix\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.Y",
    "page": "Interfaces",
    "title": "Yao.Blocks.Y",
    "category": "constant",
    "text": "Y\n\nThe Pauli-Y gate acts on a single qubit. It equates to a rotation around the Y-axis of the Bloch sphere by pi radians. It maps 0rangle to i1rangle and 1rangle to -i0rangle. It is represented by the Pauli Y matrix:\n\nY = beginpmatrix\n0  -i\ni  0\nendpmatrix\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.Z",
    "page": "Interfaces",
    "title": "Yao.Blocks.Z",
    "category": "constant",
    "text": "Z\n\nThe Pauli-Z gate acts on a single qubit. It equates to a rotation around the Z-axis of the Bloch sphere by pi radians. Thus, it is a special case of a phase shift gate (see shift) with theta = pi. It leaves the basis state 0rangle unchanged and maps 1rangle to -1rangle. Due to this nature, it is sometimes called phase-flip. It is represented by the Pauli Z matrix:\n\nZ = beginpmatrix\n1  0\n0  -1\nendpmatrix\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.InvOrder",
    "page": "Interfaces",
    "title": "Yao.Interfaces.InvOrder",
    "category": "constant",
    "text": "InvOrder\n\nReturn a FunctionBlock of inversing the order.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Reset",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Reset",
    "category": "constant",
    "text": "Reset\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Vstat",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Vstat",
    "category": "type",
    "text": "Vstat{N, AT}\nVstat(data) -> Vstat\n\nV-statistic functional.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.@fn",
    "page": "Interfaces",
    "title": "Yao.Interfaces.@fn",
    "category": "macro",
    "text": "macro fn([name,] f)\n\nDefine a in-place function on a register inside circuits.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Rx",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Rx",
    "category": "function",
    "text": "Rx([type=Yao.DefaultType], theta) -> RotationGate{1, type, X}\n\nReturns a rotation X gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Ry",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Ry",
    "category": "function",
    "text": "Ry([type=Yao.DefaultType], theta) -> RotationGate{1, type, Y}\n\nReturns a rotation Y gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Rz",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Rz",
    "category": "function",
    "text": "Rz([type=Yao.DefaultType], theta) -> RotationGate{1, type, Z}\n\nReturns a rotation Z gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.addbit-Tuple{Int64}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.addbit",
    "category": "method",
    "text": "addbit(n::Int) -> FunctionBlock{:AddBit}\n\nReturn a FunctionBlock of adding n bits.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.autodiff",
    "page": "Interfaces",
    "title": "Yao.Interfaces.autodiff",
    "category": "function",
    "text": "autodiff(mode::Symbol, block::AbstractBlock) -> AbstractBlock\nautodiff(mode::Symbol) -> Function\n\nautomatically mark differentiable items in a block tree as differentiable.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.chain",
    "page": "Interfaces",
    "title": "Yao.Interfaces.chain",
    "category": "function",
    "text": "chain([T], n::Int) -> ChainBlock\nchain([n], blocks) -> ChainBlock\n\nReturns a ChainBlock. This factory method can be called lazily if you missed the total number of qubits.\n\nThis chains several blocks with the same size together.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.concentrate-Tuple{Int64,AbstractBlock,Any}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.concentrate",
    "category": "method",
    "text": "concentrate(nbit::Int, block::AbstractBlock, addrs) -> Concentrator{nbit}\n\nconcentrate blocks on serveral addrs.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.control",
    "page": "Interfaces",
    "title": "Yao.Interfaces.control",
    "category": "function",
    "text": "control([total], controls, target) -> ControlBlock\n\nConstructs a ControlBlock\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.matrixgate-Tuple{AbstractArray{T,2} where T}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.matrixgate",
    "category": "method",
    "text": "matrixgate(matrix::AbstractMatrix) -> GeneralMatrixGate\nmatrixgate(matrix::MatrixBlock) -> GeneralMatrixGate\n\nConstruct a general matrix gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.numdiff-Tuple{Any,AbstractDiff}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.numdiff",
    "category": "method",
    "text": "numdiff(loss, diffblock::AbstractDiff; δ::Real=1e-2)\n\nNumeric differentiation.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.opdiff-Tuple{Any,AbstractDiff,MatrixBlock}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.opdiff",
    "category": "method",
    "text": "opdiff(psifunc, diffblock::AbstractDiff, op::MatrixBlock)\n\nOperator differentiation.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.paulistring",
    "page": "Interfaces",
    "title": "Yao.Interfaces.paulistring",
    "category": "function",
    "text": "paulistring([n], blocks::PauliGate...) -> PauliString\npaulistring([n], blocks::Pair{Int, PauliGate}...) -> PauliString\n\nReturns a PauliString. This factory method can be called lazily if you missed the total number of qubits.\n\nThis krons several pauli gates, either dict (more flexible) like input and chain like input are allowed. i.e. paulistring(3, X, Y, Z) is equivalent to paulistring(3, 1=>X, 2=>Y, 3=>Z)\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.phase",
    "page": "Interfaces",
    "title": "Yao.Interfaces.phase",
    "category": "function",
    "text": "phase([type=Yao.DefaultType], theta) -> PhaseGate{:global}\n\nReturns a global phase gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.put-Union{Tuple{M}, Tuple{Int64,Pair{Tuple{Vararg{Int64,M}},#s294} where #s294<:AbstractBlock}} where M",
    "page": "Interfaces",
    "title": "Yao.Interfaces.put",
    "category": "method",
    "text": "put([total::Int, ]pa::Pair) -> PutBlock{total}\n\nput a block at the specific position(s), can be lazy constructed.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.reflect",
    "page": "Interfaces",
    "title": "Yao.Interfaces.reflect",
    "category": "function",
    "text": "reflect(mirror::DefaultRegister{1}) -> ReflectBlock\nreflect(mirror::Vector) -> ReflectBlock\n\nReturn an ReflectBlock along with state vector mirror as the axis.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.roll",
    "page": "Interfaces",
    "title": "Yao.Interfaces.roll",
    "category": "function",
    "text": "roll([n::Int, ], blocks...,) -> Roller{n}\n\nConstruct a Roller block, which is a faster than KronBlock to calculate similar small blocks tile on the whole address.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.rollrepeat",
    "page": "Interfaces",
    "title": "Yao.Interfaces.rollrepeat",
    "category": "function",
    "text": "rollrepeat([n::Int,] block::MatrixBlock) -> Roller{n}\n\nConstruct a Roller block, which is a faster than KronBlock to calculate similar small blocks tile on the whole address.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.rot",
    "page": "Interfaces",
    "title": "Yao.Interfaces.rot",
    "category": "function",
    "text": "rot([type=Yao.DefaultType], U, theta) -> RotationGate{N, type, U}\n\nReturns an arbitrary rotation gate on U.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.sequence",
    "page": "Interfaces",
    "title": "Yao.Interfaces.sequence",
    "category": "function",
    "text": "Returns a Sequential block. This factory method can be called lazily if you missed the total number of qubits.\n\nThis is the loose version of sequence, that does not support the mat related interfaces.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.shift",
    "page": "Interfaces",
    "title": "Yao.Interfaces.shift",
    "category": "function",
    "text": "shift([type=Yao.DefaultType], theta) -> PhaseGate{:shift}\n\nReturns a phase shift gate.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.swap",
    "page": "Interfaces",
    "title": "Yao.Interfaces.swap",
    "category": "function",
    "text": "swap([n], [type], line1, line2) -> Swap\n\nReturns a swap gate on line1 and line2\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.timeevolve",
    "page": "Interfaces",
    "title": "Yao.Interfaces.timeevolve",
    "category": "function",
    "text": "timeevolve([block::MatrixBlock], t::Real) -> TimeEvolution\n\nMake a time machine! If block is not provided, it will become lazy.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.vstatdiff-Tuple{Any,AbstractDiff,Vstat}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.vstatdiff",
    "category": "method",
    "text": "vstatdiff(psifunc, diffblock::AbstractDiff, vstat::Vstat; p0::AbstractVector=psifunc()|>probs)\n\nDifferentiation for V-statistics.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.XGate",
    "page": "Interfaces",
    "title": "Yao.Blocks.XGate",
    "category": "type",
    "text": "XGate{T} <: ConstantGate{1, T}\n\nThe block type for Pauli-X gate. See docs for X for more information.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.YGate",
    "page": "Interfaces",
    "title": "Yao.Blocks.YGate",
    "category": "type",
    "text": "YGate{T} <: ConstantGate{1, T}\n\nThe block type for Pauli-Y gate. See docs for Y for more information.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.ZGate",
    "page": "Interfaces",
    "title": "Yao.Blocks.ZGate",
    "category": "type",
    "text": "ZGate{T} <: ConstantGate{1, T}\n\nThe block type for Pauli-Z gate. See docs for Z for more information.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Base.kron-Tuple{Int64,Vararg{Pair{Int64,#s294} where #s294<:MatrixBlock,N} where N}",
    "page": "Interfaces",
    "title": "Base.kron",
    "category": "method",
    "text": "kron([total::Int, ]block0::Pair, blocks::Union{MatrixBlock, Pair}...,) -> KronBlock{total}\n\ncreate a KronBlock with a list of blocks or tuple of heads and blocks. If total is not provided, return a lazy constructor.\n\nExample\n\nkron(4, 1=>X, 3=>Z, 4=>Y)\n\nThis will automatically generate a block list looks like\n\n1 -- [X] --\n2 ---------\n3 -- [Z] --\n4 -- [Y] --\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Base.repeat-Tuple{Int64,MatrixBlock,Any}",
    "page": "Interfaces",
    "title": "Base.repeat",
    "category": "method",
    "text": "repeat([n::Int,] x::MatrixBlock, [addrs]) -> RepeatedBlock{n}\n\nConstruct a RepeatedBlock, if n (the number of qubits) not supplied, using lazy evaluation. If addrs not supplied, blocks will fill the qubit space.\n\n\n\n\n\n"
},

{
    "location": "man/interfaces/#Interfaces-1",
    "page": "Interfaces",
    "title": "Interfaces",
    "category": "section",
    "text": "Modules = [Interfaces]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/registers/#",
    "page": "Registers",
    "title": "Registers",
    "category": "page",
    "text": ""
},

{
    "location": "man/registers/#Registers-1",
    "page": "Registers",
    "title": "Registers",
    "category": "section",
    "text": "Quantum circuits process quantum states. A quantum state being processing by a quantum circuit will be stored on a quantum register. In Yao we provide several types for registers. The default type for registers is the Yao.Registers.DefaultRegister.You can directly use factory method register"
},

{
    "location": "man/registers/#Storage-1",
    "page": "Registers",
    "title": "Storage",
    "category": "section",
    "text": ""
},

{
    "location": "man/registers/#LDT-format-1",
    "page": "Registers",
    "title": "LDT format",
    "category": "section",
    "text": "Concepturely, a wave function psirangle can be represented in a low dimentional tensor (LDT) format of order-3, L(f, r, b).f: focused (i.e. operational) dimensions\nr: remaining dimensions\nb: batch dimension.For simplicity, let\'s ignore batch dimension for the momentum, we havepsirangle = sumlimits_xy L(x y ) jrangleirangleGiven a configuration x (in operational space), we want get the i-th bit using (x<<i) & 0x1, which means putting the small end the qubit with smaller index. In this representation L(x) will get return langle xpsirangle.note: Note\nWhy not the other convension: Using the convention of putting 1st bit on the big end will need to know the total number of qubits n in order to know such positional information."
},

{
    "location": "man/registers/#HDT-format-1",
    "page": "Registers",
    "title": "HDT format",
    "category": "section",
    "text": "Julia storage is column major, if we reshape the wave function to a shape of 2times2times  times2 and get the HDT (high dimensional tensor) format representation H, we can use H(x_1 x_2  x_3) to get langle xpsirangle."
},

{
    "location": "man/registers/#Operations-1",
    "page": "Registers",
    "title": "Operations",
    "category": "section",
    "text": ""
},

{
    "location": "man/registers/#Kronecker-product-of-operators-1",
    "page": "Registers",
    "title": "Kronecker product of operators",
    "category": "section",
    "text": "In order to put small bits on little end, the Kronecker product is O = o_n otimes ldots otimes o_2 otimes o_1 where the subscripts are qubit indices."
},

{
    "location": "man/registers/#Measurements-1",
    "page": "Registers",
    "title": "Measurements",
    "category": "section",
    "text": "Measure means sample and projection."
},

{
    "location": "man/registers/#Sample-1",
    "page": "Registers",
    "title": "Sample",
    "category": "section",
    "text": "Suppose we want to measure operational subspace, we can first getp(x) = langle xpsirangle^2 = sumlimits_y L(x y )^2Then we sample an asim p(x). If we just sample and don\'t really measure (change wave function), its over."
},

{
    "location": "man/registers/#Projection-1",
    "page": "Registers",
    "title": "Projection",
    "category": "section",
    "text": "psirangle = sum_y L(a y )sqrtp(a) arangle yrangleGood! then we can just remove the operational qubit space since x and y spaces are totally decoupled and x is known as in state a, then we getpsirangle_r = sum_y l(0 y ) yranglewhere l = L(a:a, :, :)/sqrt(p(a))."
},

{
    "location": "man/registers/#Yao.Registers.AbstractRegister",
    "page": "Registers",
    "title": "Yao.Registers.AbstractRegister",
    "category": "type",
    "text": "AbstractRegister{B, T}\n\nabstract type that registers will subtype from. B is the batch size, T is the data type.\n\nRequired Properties\n\nProperty Description default\nnqubits(reg) get the total number of qubits. \nnactive(reg) get the number of active qubits. \nnremain(reg) get the number of remained qubits. nqubits - nactive\nnbatch(reg) get the number of batch. B\nstate(reg) get the state of this register. It always return the matrix stored inside. \nstatevec(reg) get the raveled state of this register.                                  . \nhypercubic(reg) get the hypercubic form of this register.                                  . \neltype(reg) get the element type stored by this register on classical memory. (the type Julia should use to represent amplitude) T\ncopy(reg) copy this register. \nsimilar(reg) construct a new register with similar configuration. \n\nRequired Methods\n\nMultiply\n\n*(op, reg)\n\ndefine how operator op act on this register. This is quite useful when there is a special approach to apply an operator on this register. (e.g a register with no batch, or a register with a MPS state, etc.)\n\nnote: Note\nbe careful, generally, operators can only be applied to a register, thus we should only overload this operation and do not overload *(reg, op).\n\nPack Address\n\npack addrs together to the first k-dimensions.\n\nExample\n\nGiven a register with dimension [2, 3, 1, 5, 4], we pack [5, 4] to the first 2 dimensions. We will get [5, 4, 2, 3, 1].\n\nFocus Address\n\nfocus!(reg, range)\n\nmerge address in range together as one dimension (the active space).\n\nExample\n\nGiven a register with dimension (2^4)x3 and address [1, 2, 3, 4], we focus address [3, 4], will pack [3, 4] together and merge them as the active space. Then we will have a register with size 2^2x(2^2x3), and address [3, 4, 1, 2].\n\nInitializers\n\nInitializers are functions that provide specific quantum states, e.g zero states, random states, GHZ states and etc.\n\nregister(::Type{RT}, raw, nbatch)\n\nan general initializer for input raw state array.\n\nregister(::Val{InitMethod}, ::Type{RT}, ::Type{T}, n, nbatch)\n\ninit register type RT with InitMethod type (e.g Val{:zero}) with element type T and total number qubits n with nbatch. This will be auto-binded to some shortcuts like zero_state, rand_state.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.DefaultRegister",
    "page": "Registers",
    "title": "Yao.Registers.DefaultRegister",
    "category": "type",
    "text": "DefaultRegister{B, T} <: AbstractRegister{B, T}\n\nDefault type for a quantum register. It contains a dense array that represents a batched quantum state with batch size B of type T.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.@bit_str-Tuple{Any}",
    "page": "Registers",
    "title": "Yao.Registers.@bit_str",
    "category": "macro",
    "text": "@bit_str -> QuBitStr\n\nConstruct a bit string. such as bit\"0000\". The bit strings also supports string concat. Just use it like normal strings.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Intrinsics.hypercubic",
    "page": "Registers",
    "title": "Yao.Intrinsics.hypercubic",
    "category": "function",
    "text": "hypercubic(r::AbstractRegister) -> AbstractArray\n\nReturn the hypercubic form (high dimensional tensor) of this register, only active qubits are considered.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.density_matrix",
    "page": "Registers",
    "title": "Yao.Registers.density_matrix",
    "category": "function",
    "text": "density_matrix(register)\n\nReturns the density matrix of this register.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.extend!-Union{Tuple{T}, Tuple{B}, Tuple{DefaultRegister{B,T,MT} where MT<:AbstractArray{T,2},Int64}} where T where B",
    "page": "Registers",
    "title": "Yao.Registers.extend!",
    "category": "method",
    "text": "extend!(r::DefaultRegister, n::Int) -> DefaultRegister\nextend!(n::Int) -> Function\n\nextend the register by n bits in state |0>. i.e. |psi> -> |000> ⊗ |psi>, extended bits have higher indices. If only an integer is provided, then perform lazy evaluation.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.fidelity",
    "page": "Registers",
    "title": "Yao.Registers.fidelity",
    "category": "function",
    "text": "fidelity(reg1::DefaultRegister, reg2::DefaultRegister) -> Vector\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.focus!",
    "page": "Registers",
    "title": "Yao.Registers.focus!",
    "category": "function",
    "text": "focus!(reg::DefaultRegister, bits::Ints) -> DefaultRegister\nfocus!(locs::Int...) -> Function\n\nFocus register on specified active bits.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.focus!-Tuple{Any,DefaultRegister,Any}",
    "page": "Registers",
    "title": "Yao.Registers.focus!",
    "category": "method",
    "text": "focus!(func, reg::DefaultRegister, locs) -> DefaultRegister\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.isnormalized-Tuple{DefaultRegister}",
    "page": "Registers",
    "title": "Yao.Registers.isnormalized",
    "category": "method",
    "text": "isnormalized(reg::DefaultRegister) -> Bool\n\nReturn true if a register is normalized else false.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.measure",
    "page": "Registers",
    "title": "Yao.Registers.measure",
    "category": "function",
    "text": "measure(register, [n=1]) -> Vector\n\nmeasure active qubits for n times.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.measure!-Union{Tuple{AbstractRegister{B,T} where T}, Tuple{B}} where B",
    "page": "Registers",
    "title": "Yao.Registers.measure!",
    "category": "method",
    "text": "measure!(reg::AbstractRegister) -> Int\n\nmeasure and collapse to result state.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.measure_remove!-Union{Tuple{AbstractRegister{B,T} where T}, Tuple{B}} where B",
    "page": "Registers",
    "title": "Yao.Registers.measure_remove!",
    "category": "method",
    "text": "measure_remove!(register) -> Int\n\nmeasure the active qubits of this register and remove them.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.measure_reset!-Union{Tuple{AbstractRegister{B,T} where T}, Tuple{B}} where B",
    "page": "Registers",
    "title": "Yao.Registers.measure_reset!",
    "category": "method",
    "text": "measure_and_reset!(reg::AbstractRegister, [mbits]; val=0) -> Int\n\nmeasure and set the register to specific value.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.product_state-Union{Tuple{T}, Tuple{Type{T},Int64,Integer}, Tuple{Type{T},Int64,Integer,Int64}} where T",
    "page": "Registers",
    "title": "Yao.Registers.product_state",
    "category": "method",
    "text": "product_state([::Type{T}], n::Int, config::Int, nbatch::Int=1) -> DefaultRegister\n\na product state on given configuration config, e.g. product_state(ComplexF64, 5, 0) will give a zero state on a 5 qubit register.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.rand_state-Union{Tuple{T}, Tuple{Type{T},Int64}, Tuple{Type{T},Int64,Int64}} where T",
    "page": "Registers",
    "title": "Yao.Registers.rand_state",
    "category": "method",
    "text": "rand_state([::Type{T}], n::Int, nbatch::Int=1) -> DefaultRegister\n\nhere, random complex numbers are generated using randn(ComplexF64).\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.register",
    "page": "Registers",
    "title": "Yao.Registers.register",
    "category": "function",
    "text": "register([type], bit_str, [nbatch=1]) -> DefaultRegister\n\nReturns a DefaultRegister by inputing a bit string, e.g\n\nusing Yao\nregister(bit\"0000\")\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.register-Tuple{AbstractArray{T,2} where T}",
    "page": "Registers",
    "title": "Yao.Registers.register",
    "category": "method",
    "text": "register(raw) -> DefaultRegister\n\nReturns a DefaultRegister from a raw dense array (Vector or Matrix).\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.relax!",
    "page": "Registers",
    "title": "Yao.Registers.relax!",
    "category": "function",
    "text": "relax!(reg::DefaultRegister; nbit::Int=nqubits(reg)) -> DefaultRegister\nrelax!(reg::DefaultRegister, bits::Ints; nbit::Int=nqubits(reg)) -> DefaultRegister\nrelax!(bits::Ints...; nbit::Int=-1) -> Function\n\nInverse transformation of focus, with nbit is the number of active bits of target register.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.relaxedvec",
    "page": "Registers",
    "title": "Yao.Registers.relaxedvec",
    "category": "function",
    "text": "relaxedvec(r::AbstractRegister) -> AbstractArray\n\nActivate all qubits, and return a matrix (vector) for B>1 (B=1).\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.select!-Union{Tuple{B}, Tuple{AbstractRegister{B,T} where T,Any}} where B",
    "page": "Registers",
    "title": "Yao.Registers.select!",
    "category": "method",
    "text": "select!(reg::AbstractRegister, b::Integer) -> AbstractRegister\nselect!(b::Integer) -> Function\n\nselect specific component of qubit, the inplace version, the currified version will return a Function.\n\ne.g. select!(reg, 0b110) will select the subspace with (focused) configuration 110. After selection, the focused qubit space is 0, so you may want call relax! manually.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.select-Union{Tuple{B}, Tuple{DefaultRegister{B,T,MT} where MT<:AbstractArray{T,2} where T,Any}} where B",
    "page": "Registers",
    "title": "Yao.Registers.select",
    "category": "method",
    "text": "select(reg::AbstractRegister, b::Integer) -> AbstractRegister\n\nthe non-inplace version of select! function.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.stack-Tuple{Vararg{DefaultRegister,N} where N}",
    "page": "Registers",
    "title": "Yao.Registers.stack",
    "category": "method",
    "text": "stack(regs::DefaultRegister...) -> DefaultRegister\n\nstack multiple registers into a batch.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.statevec",
    "page": "Registers",
    "title": "Yao.Registers.statevec",
    "category": "function",
    "text": "statevec(r::AbstractRegister) -> AbstractArray\n\nReturn a state matrix/vector by droping the last dimension of size 1.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.tracedist",
    "page": "Registers",
    "title": "Yao.Registers.tracedist",
    "category": "function",
    "text": "tracedist(reg1::DefaultRegister, reg2::DefaultRegister) -> Vector\ntracedist(reg1::DensityMatrix, reg2::DensityMatrix) -> Vector\n\ntrace distance.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.uniform_state-Union{Tuple{T}, Tuple{Type{T},Int64}, Tuple{Type{T},Int64,Int64}} where T",
    "page": "Registers",
    "title": "Yao.Registers.uniform_state",
    "category": "method",
    "text": "uniform_state([::Type{T}], n::Int, nbatch::Int=1) -> DefaultRegister\n\nuniform state, the state after applying H gates on |0> state.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.zero_state-Union{Tuple{T}, Tuple{Type{T},Int64}, Tuple{Type{T},Int64,Int64}} where T",
    "page": "Registers",
    "title": "Yao.Registers.zero_state",
    "category": "method",
    "text": "zero_state([::Type{T}], n::Int, nbatch::Int=1) -> DefaultRegister\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.ρ",
    "page": "Registers",
    "title": "Yao.Registers.ρ",
    "category": "function",
    "text": "ρ(register)\n\nReturns the density matrix of this register.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.QuBitStr",
    "page": "Registers",
    "title": "Yao.Registers.QuBitStr",
    "category": "type",
    "text": "QuBitStr\n\nString literal for qubits.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Base.kron-Union{Tuple{RT}, Tuple{B}, Tuple{RT,AbstractRegister{B,T} where T}} where RT<:(AbstractRegister{B,T} where T) where B",
    "page": "Registers",
    "title": "Base.kron",
    "category": "method",
    "text": "kron(lhs, rhs)\n\nMerge two registers together with kronecker tensor product.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#LinearAlgebra.normalize!-Tuple{AbstractRegister}",
    "page": "Registers",
    "title": "LinearAlgebra.normalize!",
    "category": "method",
    "text": "normalize!(r::AbstractRegister) -> AbstractRegister\n\nReturn the register with normalized state.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.shapeorder-Tuple{Tuple{Vararg{T,N}} where T where N,Array{Int64,1}}",
    "page": "Registers",
    "title": "Yao.Registers.shapeorder",
    "category": "method",
    "text": "Get the compact shape and order for permutedims.\n\n\n\n\n\n"
},

{
    "location": "man/registers/#Registers-2",
    "page": "Registers",
    "title": "Registers",
    "category": "section",
    "text": "Modules = [Yao.Registers]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/blocks/#",
    "page": "Blocks System",
    "title": "Blocks System",
    "category": "page",
    "text": "CurrentModule = Yao.Blocks"
},

{
    "location": "man/blocks/#Blocks-System-1",
    "page": "Blocks System",
    "title": "Blocks System",
    "category": "section",
    "text": "Blocks are the basic component of a quantum circuit in Yao."
},

{
    "location": "man/blocks/#Block-System-1",
    "page": "Blocks System",
    "title": "Block System",
    "category": "section",
    "text": "The whole framework is consist of a block system. The whole system characterize a quantum circuit into serveral kinds of blocks. The uppermost abstract type for the whole system is AbstractBlock(Image: Block-System)"
},

{
    "location": "man/blocks/#Composite-Blocks-1",
    "page": "Blocks System",
    "title": "Composite Blocks",
    "category": "section",
    "text": ""
},

{
    "location": "man/blocks/#Roller-1",
    "page": "Blocks System",
    "title": "Roller",
    "category": "section",
    "text": "Roller is a special pattern of quantum circuits. Usually is equivalent to a KronBlock, but we can optimize the computation by rotate the tensor form of a quantum state and apply each small block on it each time.(Image: Block-System)"
},

{
    "location": "man/blocks/#Yao.Blocks.AbstractBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.AbstractBlock",
    "category": "type",
    "text": "AbstractBlock\n\nabstract type that all block will subtype from. N is the number of qubits.\n\nRequired interfaces     * apply! or (and) mat\n\nInterfaces for parametric blocks.\n\n* iparameters\n* setiparameters\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.AbstractContainer",
    "page": "Blocks System",
    "title": "Yao.Blocks.AbstractContainer",
    "category": "type",
    "text": "ContainerBlock{N, T} <: MatrixBlock{N, T}\n\nabstract supertype which container blocks will inherit from.\n\nextended APIs\n\nblock: the block contained by this ContainerBlock\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.AbstractMeasure",
    "page": "Blocks System",
    "title": "Yao.Blocks.AbstractMeasure",
    "category": "type",
    "text": "AbstractMeasure <: AbstractBlock\n\nAbstract block supertype which measurement block will inherit from.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.BPDiff",
    "page": "Blocks System",
    "title": "Yao.Blocks.BPDiff",
    "category": "type",
    "text": "BPDiff{GT, N, T, PT, RT<:AbstractRegister} <: AbstractDiff{GT, N, Complex{T}}\nBPDiff(block, [input::AbstractRegister, grad]) -> BPDiff\n\nMark a block as differentiable, here GT, PT and RT are gate type, parameter type and register type respectively.\n\nWarning:     please don\'t use the adjoint after BPDiff! adjoint is reserved for special purpose! (back propagation)\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.BlockTreeIterator",
    "page": "Blocks System",
    "title": "Yao.Blocks.BlockTreeIterator",
    "category": "type",
    "text": "BlockTreeIterator{BT}\n\nIterate through the whole block tree with breadth first search.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.CacheFragment",
    "page": "Blocks System",
    "title": "Yao.Blocks.CacheFragment",
    "category": "type",
    "text": "CacheFragment{BT, K, MT}\n\nA fragment that will be stored for each cached block (of type BT) on a cache server.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.CachedBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.CachedBlock",
    "category": "type",
    "text": "CachedBlock{ST, BT, N, T} <: TagBlock{N, T}\n\nA label type that tags an instance of type BT. It forwards every methods of the block it contains, except mat and apply!, it will cache the matrix form whenever the program has.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ChainBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.ChainBlock",
    "category": "type",
    "text": "ChainBlock{N, T} <: CompositeBlock{N, T}\n\nChainBlock is a basic construct tool to create user defined blocks horizontically. It is a Vector like composite type.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.CompositeBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.CompositeBlock",
    "category": "type",
    "text": "CompositeBlock{N, T} <: MatrixBlock{N, T}\n\nabstract supertype which composite blocks will inherit from.\n\nextended APIs\n\nblocks: get an iteratable of all blocks contained by this CompositeBlock\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Concentrator",
    "page": "Blocks System",
    "title": "Yao.Blocks.Concentrator",
    "category": "type",
    "text": "Concentrator{N, T, BT <: AbstractBlock} <: AbstractContainer{N, T}\n\nconcentrates serveral lines together in the circuit, and expose it to other blocks.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ConstantGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.ConstantGate",
    "category": "type",
    "text": "ConstantGate{N, T} <: PrimitiveBlock{N, T}\n\nAbstract type for constant gates.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ControlBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.ControlBlock",
    "category": "type",
    "text": "ControlBlock{BT, N, C, B, T} <: AbstractContainer{N, T}\n\nN: number of qubits, BT: controlled block type, C: number of control bits, T: type of matrix.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Daggered",
    "page": "Blocks System",
    "title": "Yao.Blocks.Daggered",
    "category": "type",
    "text": "Daggered{N, T, BT} <: TagBlock{N, T}\n\nDaggered(blk::BT)\nDaggered{N, T, BT}(blk)\n\nDaggered Block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.FunctionBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.FunctionBlock",
    "category": "type",
    "text": "FunctionBlock <: AbstractBlock\n\nThis block contains a general function that perform an in-place operation over a register\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.KronBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.KronBlock",
    "category": "type",
    "text": "KronBlock{N, T, MT<:MatrixBlock} <: CompositeBlock{N, T}\n\ncomposite block that combine blocks by kronecker product.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.MathBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.MathBlock",
    "category": "type",
    "text": "MathBlock{L, N, T} <: PrimitiveBlock{N, T}\n\nBlock for arithmatic operations, the operation name can be specified by type parameter L. Note the T parameter represents the kind of view of basis (the input format of func), which should be one of bint, bint_r, bfloat, bfloat_r.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.MatrixBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.MatrixBlock",
    "category": "type",
    "text": "MatrixBlock{N, T} <: AbstractBlock\n\nabstract type that all block with a matrix form will subtype from.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Measure",
    "page": "Blocks System",
    "title": "Yao.Blocks.Measure",
    "category": "type",
    "text": "Measure <: AbstractMeasure\nMeasure() -> Measure\n\nMeasure block, collapse a state and store measured value, e.g.\n\nExamples\n\njulia> m = Measure();\n\njulia> reg = product_state(4, 7)\nDefaultRegister{1, Complex{Float64}}\n    active qubits: 4/4\n\njulia> reg |> m\nDefaultRegister{1, Complex{Float64}}\n    active qubits: 4/4\n\njulia> m.result\n1-element Array{Int64,1}:\n 7\n\nNote: Measure returns a vector here, the length corresponds to batch dimension of registers.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.MeasureAndRemove",
    "page": "Blocks System",
    "title": "Yao.Blocks.MeasureAndRemove",
    "category": "type",
    "text": "MeasureAndRemove <: AbstractMeasure\nMeasureAndRemove() -> MeasureAndRemove\n\nMeasure and remove block, remove measured qubits and store measured value.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.MeasureAndReset",
    "page": "Blocks System",
    "title": "Yao.Blocks.MeasureAndReset",
    "category": "type",
    "text": "MeasureAndReset <: AbstractMeasure\nMeasureAndReset([val=0]) -> MeasureAndReset\n\nMeasure and reset block, reset measured qubits to val and store measured value.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.PhaseGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.PhaseGate",
    "category": "type",
    "text": "PhiGate\n\nGlobal phase gate.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.PrimitiveBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.PrimitiveBlock",
    "category": "type",
    "text": "PrimitiveBlock{N, T} <: MatrixBlock{N, T}\n\nabstract type that all primitive block will subtype from. A primitive block is a concrete block who can not be decomposed into other blocks. All composite block can be decomposed into several primitive blocks.\n\nNOTE: subtype for primitive block with parameter should implement hash and == method to enable key value cache.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.PutBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.PutBlock",
    "category": "type",
    "text": "PutBlock{N, C, GT, T} <: AbstractContainer{N, T}\n\nput a block on given addrs.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.QDiff",
    "page": "Blocks System",
    "title": "Yao.Blocks.QDiff",
    "category": "type",
    "text": "QDiff{GT, N, T} <: AbstractDiff{GT, N, Complex{T}}\nQDiff(block) -> QDiff\n\nMark a block as quantum differentiable.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ReflectBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.ReflectBlock",
    "category": "type",
    "text": "ReflectBlock{N, T} <: PrimitiveBlock{N, T}\n\nHouseholder reflection with respect to some target state, psirangle = 2sranglelangle s-1.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.RepeatedBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.RepeatedBlock",
    "category": "type",
    "text": "RepeatedBlock{N, C, GT, T} <: AbstractContainer{N, T}\n\nrepeat the same block on given addrs.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Roller",
    "page": "Blocks System",
    "title": "Yao.Blocks.Roller",
    "category": "type",
    "text": "Roller{N, T, BT} <: CompositeBlock{N, T}\n\nmap a block type to all lines and use a rolling method to evaluate them.\n\nTODO\n\nfill identity like KronBlock -> To interface.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.RotationGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.RotationGate",
    "category": "type",
    "text": "RotationGate{N, T, GT <: MatrixBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}\n\nRotationGate, with GT both hermitian and isreflexive.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Scale",
    "page": "Blocks System",
    "title": "Yao.Blocks.Scale",
    "category": "type",
    "text": "Scale{X, N, T, BT} <: TagBlock{N, T}\n\nScale{X}(blk::MatrixBlock)\nScale{X, N, T, BT}(blk::MatrixBlock)\n\nScale Block, by a factor of X, notice X is static!\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Sequential",
    "page": "Blocks System",
    "title": "Yao.Blocks.Sequential",
    "category": "type",
    "text": "Sequential <: AbstractBlock\n\nsequencial structure that looser than a chain, it does not require qubit consistency and does not have mat method.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ShiftGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.ShiftGate",
    "category": "type",
    "text": "ShiftGate <: PrimitiveBlock\n\nPhase shift gate.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.TimeEvolution",
    "page": "Blocks System",
    "title": "Yao.Blocks.TimeEvolution",
    "category": "type",
    "text": "TimeEvolution{N, T, GT <: MatrixBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}\n\nTimeEvolution, with GT hermitian\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.apply!",
    "page": "Blocks System",
    "title": "Yao.Blocks.apply!",
    "category": "function",
    "text": "apply!(reg, block, [signal])\n\napply a block to a register reg with or without a cache signal.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.applymatrix-Tuple{AbstractBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.applymatrix",
    "category": "method",
    "text": "applymatrix(g::AbstractBlock) -> Matrix\n\nTransform the apply! function of specific block to dense matrix.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.backward!-Tuple{AbstractRegister,MatrixBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.backward!",
    "category": "method",
    "text": "backward!(δ::AbstractRegister, circuit::MatrixBlock) -> AbstractRegister\n\nback propagate and calculate the gradient ∂f/∂θ = 2Re(∂f/∂ψ⋅∂ψ/∂θ), given ∂f/∂ψ.\n\nNote: Here, the input circuit should be a matrix block, otherwise the back propagate may not apply (like Measure operations).\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.block",
    "page": "Blocks System",
    "title": "Yao.Blocks.block",
    "category": "function",
    "text": "block(container::AbstractContainer) -> AbstractBlock\n\nget the contained block (i.e. subblock) of a container.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.blockfilter-Tuple{Any,AbstractBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.blockfilter",
    "category": "method",
    "text": "blockfilter(func, blk::AbstractBlock) -> Vector{AbstractBlock}\nblockfilter!(func, rgs::Vector, blk::AbstractBlock) -> Vector{AbstractBlock}\n\ntree wise filtering for blocks.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.chblock",
    "page": "Blocks System",
    "title": "Yao.Blocks.chblock",
    "category": "function",
    "text": "chblock(block, blk)\n\nchange the block of a container.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.chsubblocks-Tuple{AbstractBlock,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.chsubblocks",
    "category": "method",
    "text": "chsubblocks(pb::AbstractBlock, blks) -> AbstractBlock\n\nChange subblocks of target block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.datatype-Union{Tuple{MatrixBlock{N,T}}, Tuple{T}, Tuple{N}} where T where N",
    "page": "Blocks System",
    "title": "Yao.Blocks.datatype",
    "category": "method",
    "text": "datatype(x) -> DataType\n\nReturns the data type of x.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.dispatch!!-Tuple{AbstractBlock,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.dispatch!!",
    "category": "method",
    "text": "dispatch!!([func::Function], block::AbstractBlock, params) -> AbstractBlock\n\nSimilar to dispatch!, but will pop! out params inplace, it can not more efficient.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.dispatch!-Tuple{AbstractBlock,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.dispatch!",
    "category": "method",
    "text": "dispatch!([func::Function], block::AbstractBlock, params) -> AbstractBlock\ndispatch!([func::Function], block::AbstractBlock, :random) -> AbstractBlock\ndispatch!([func::Function], block::AbstractBlock, :zero) -> AbstractBlock\n\ndispatch! parameters into this circuit, here params is an iterable.\n\nIf instead of iterable, a symbol :random or :zero is provided, random numbers (its behavior is specified by setiparameters!) or 0s will be broadcasted into circuits.\n\nusing dispatch!! is more efficient, but will pop! out all params inplace.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.expect",
    "page": "Blocks System",
    "title": "Yao.Blocks.expect",
    "category": "function",
    "text": "expect(op::AbstractBlock, reg::AbstractRegister{B}) -> Vector\nexpect(op::AbstractBlock, dm::DensityMatrix{B}) -> Vector\n\nexpectation value of an operator.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.generator-Tuple{RotationGate}",
    "page": "Blocks System",
    "title": "Yao.Blocks.generator",
    "category": "method",
    "text": "generator(rot::Rotor) -> MatrixBlock\n\nReturn the generator of rotation block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.gradient",
    "page": "Blocks System",
    "title": "Yao.Blocks.gradient",
    "category": "function",
    "text": "gradient(circuit::AbstractBlock, mode::Symbol=:ANY) -> Vector\n\ncollect all gradients in a circuit, mode can be :BP/:QC/:ANY, they will collect grad from BPDiff/QDiff/AbstractDiff respectively.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.iparameter_type-Tuple{AbstractBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.iparameter_type",
    "category": "method",
    "text": "iparameter_type(block::AbstractBlock) -> Type\n\nelement type of iparameters(block).\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.iparameters",
    "page": "Blocks System",
    "title": "Yao.Blocks.iparameters",
    "category": "function",
    "text": "iparameters(block) -> Vector\n\nReturns a list of all intrinsic (not from sublocks) parameters in block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.mat",
    "page": "Blocks System",
    "title": "Yao.Blocks.mat",
    "category": "function",
    "text": "mat(block) -> Matrix\n\nReturns the matrix form of this block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.niparameters",
    "page": "Blocks System",
    "title": "Yao.Blocks.niparameters",
    "category": "function",
    "text": "niparameters(x) -> Integer\n\nReturns the number of parameters of x.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.nparameters-Tuple{AbstractBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.nparameters",
    "category": "method",
    "text": "nparameters(c::AbstractBlock) -> Int\n\nnumber of parameters, including parameters in sublocks.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.parameter_type",
    "page": "Blocks System",
    "title": "Yao.Blocks.parameter_type",
    "category": "function",
    "text": "parameter_type(block) -> Type\n\nthe type of iparameters.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.parameters",
    "page": "Blocks System",
    "title": "Yao.Blocks.parameters",
    "category": "function",
    "text": "parameters(c::AbstractBlock, [output]) -> Vector\n\nget all parameters including sublocks.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.setiparameters!",
    "page": "Blocks System",
    "title": "Yao.Blocks.setiparameters!",
    "category": "function",
    "text": "setparameters!([elementwisefunction], r::AbstractBlock, params::Number...) -> AbstractBlock\nsetparameters!([elementwisefunction], r::AbstractBlock, :random) -> AbstractBlock\nsetparameters!([elementwisefunction], r::AbstractBlock, :zero) -> AbstractBlock\n\nset intrinsics parameter for block, input params can be numbers or :random or :zero.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.subblocks",
    "page": "Blocks System",
    "title": "Yao.Blocks.subblocks",
    "category": "function",
    "text": "subblocks(blk::AbstractBlock) -> Tuple\n\nreturn a tuple of all sub-blocks in this block.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.traverse-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.traverse",
    "category": "method",
    "text": "traverse(blk; algorithm=:DFS) -> BlockTreeIterator\n\nReturns an iterator that traverse through the block tree.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.usedbits-Union{Tuple{MatrixBlock{N,T} where T}, Tuple{N}} where N",
    "page": "Blocks System",
    "title": "Yao.Blocks.usedbits",
    "category": "method",
    "text": "addrs(block::AbstractBlock) -> Vector{Int}\n\nOccupied addresses (include control bits and bits occupied by blocks), fall back to all bits if this method is not provided.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Intrinsics.isreflexive",
    "page": "Blocks System",
    "title": "Yao.Intrinsics.isreflexive",
    "category": "function",
    "text": "isreflexive(x) -> Bool\n\nTest whether this operator is reflexive.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Intrinsics.isunitary",
    "page": "Blocks System",
    "title": "Yao.Intrinsics.isunitary",
    "category": "function",
    "text": "isunitary(x) -> Bool\n\nTest whether this operator is unitary.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks._allmatblock-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks._allmatblock",
    "category": "method",
    "text": "all blocks are matrix blocks\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks._blockpromote-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks._blockpromote",
    "category": "method",
    "text": "promote types of blocks\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.cache_key",
    "page": "Blocks System",
    "title": "Yao.Blocks.cache_key",
    "category": "function",
    "text": "cache_key(block)\n\nReturns the key that identify the matrix cache of this block. By default, we use the returns of parameters as its key.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.cache_type-Tuple{Type{#s14} where #s14<:MatrixBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.cache_type",
    "category": "method",
    "text": "cache_type(::Type) -> DataType\n\nA type trait that defines the element type that a CacheFragment will use.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.print_block-Tuple{IO,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.print_block",
    "category": "method",
    "text": "print_block(io, block)\n\ndefine the style to print this block\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.render_params-Tuple{AbstractBlock,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.render_params",
    "category": "method",
    "text": "render_params(r::AbstractBlock, raw_parameters) -> Iterable\n\nMore elegant way of rendering parameters for symbols.\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ConstGateTools.@const_gate-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.ConstGateTools.@const_gate",
    "category": "macro",
    "text": "@const_gate NAME = MAT_EXPR\n@const_gate NAME::Type = MAT_EXPR\n@const_Gate NAME::Type\n\nThis macro simplify the definition of a constant gate. It will automatically bind the matrix form to a constant which will reduce memory allocation in the runtime.\n\n@const_gate X = ComplexF64[0 1;1 0]\n\nor\n\n@const_gate X::ComplexF64 = [0 1;1 0]\n\nYou can bind new element types by simply re-declare with a type annotation.\n\n@const_gate X::ComplexF32\n\n\n\n\n\n"
},

{
    "location": "man/blocks/#Blocks-1",
    "page": "Blocks System",
    "title": "Blocks",
    "category": "section",
    "text": "Modules = [Yao.Blocks, Yao.Blocks.ConstGateTools]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/intrinsics/#",
    "page": "Intrinsics",
    "title": "Intrinsics",
    "category": "page",
    "text": ""
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.AddressConflictError",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.AddressConflictError",
    "category": "type",
    "text": "AddressConflictError <: Exception\n\nAddress conflict error in Block Construction.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.IterControl",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.IterControl",
    "category": "type",
    "text": "IterControl{N, C}\n\nN is the size of hilbert space, C is the number of shifts.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.QubitMismatchError",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.QubitMismatchError",
    "category": "type",
    "text": "QubitMismatchError <: Exception\n\nQubit number mismatch error when applying a Block to a Register or concatenating Blocks.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#LinearAlgebra.ishermitian-Tuple{Any}",
    "page": "Intrinsics",
    "title": "LinearAlgebra.ishermitian",
    "category": "method",
    "text": "ishermitian(op) -> Bool\n\ncheck if this operator is hermitian.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.baddrs-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.baddrs",
    "category": "method",
    "text": "baddrs(b::DInt) -> Vector\n\nget the locations of nonzeros bits, i.e. the inverse operation of bmask.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.basis-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.basis",
    "category": "method",
    "text": "basis(num_bit::Int) -> UnitRange{Int}\nbasis(state::AbstractArray) -> UnitRange{Int}\n\nReturns the UnitRange for basis in Hilbert Space of num_bit qubits. If an array is supplied, it will return a basis having the same size with the first diemension of array.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.batch_normalize",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.batch_normalize",
    "category": "function",
    "text": "batch_normalize\n\nnormalize a batch of vector.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.batch_normalize!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.batch_normalize!",
    "category": "function",
    "text": "batch_normalize!(matrix)\n\nnormalize a batch of vector.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bdistance-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bdistance",
    "category": "method",
    "text": "bdistance(i::DInt, j::DInt) -> Int\n\nReturn number of different bits.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bfloat-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bfloat",
    "category": "method",
    "text": "bfloat(b::Int; nbit::Int=bit_length(b)) -> Float64\n\nfloat view, with big end qubit 1.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bfloat_r-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bfloat_r",
    "category": "method",
    "text": "bfloat_r(b::Int; nbit::Int) -> Float64\n\nfloat view, with bits read in inverse order.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bint-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bint",
    "category": "method",
    "text": "bint(b::Int; nbit=nothing) -> Int\n\ninteger view, with little end qubit 1.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bint_r-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bint_r",
    "category": "method",
    "text": "bint_r(b::Int; nbit::Int) -> Int\n\ninteger read in inverse order.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bit_length-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bit_length",
    "category": "method",
    "text": "bit_length(x::Int) -> Int\n\nReturn the number of bits required to represent input integer x.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bitarray-Union{Tuple{T}, Tuple{Array{T,1},Int64}} where T<:Number",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bitarray",
    "category": "method",
    "text": "bitarray(v::Vector, [num_bit::Int]) -> BitArray\nbitarray(v::Int, num_bit::Int) -> BitArray\nbitarray(num_bit::Int) -> Function\n\nConstruct BitArray from an integer vector, if num_bit not supplied, it is 64. If an integer is supplied, it returns a function mapping a Vector/Int to bitarray.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bmask",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bmask",
    "category": "function",
    "text": "bmask(ibit::Int...) -> Int\nbmask(bits::UnitRange{Int}) ->Int\n\nReturn an integer with specific position masked, which is offten used as a mask for binary operations.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.breflect",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.breflect",
    "category": "function",
    "text": "breflect(num_bit::Int, b::Int[, masks::Vector{Int}]) -> Int\n\nReturn left-right reflected integer.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bsizeof-Tuple{Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bsizeof",
    "category": "method",
    "text": "bsizeof(x) -> Int\n\nReturn the size of object, in number of bit.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.controller-Tuple{Any,Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.controller",
    "category": "method",
    "text": "controller(cbits, cvals) -> Function\n\nReturn a function that test whether a basis at cbits takes specific value cvals.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.cunapply!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.cunapply!",
    "category": "function",
    "text": "control-unitary\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.cunmat",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.cunmat",
    "category": "function",
    "text": "cunmat(nbit::Int, cbits::NTuple{C, Int}, cvals::NTuple{C, Int}, U0::AbstractMatrix, locs::NTuple{M, Int}) where {C, M} -> AbstractMatrix\n\ncontrol-unitary matrix\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.fidelity_mix-Tuple{Array{T,2} where T,Array{T,2} where T}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.fidelity_mix",
    "category": "method",
    "text": "fidelity_mix(m1::Matrix, m2::Matrix)\n\nFidelity for mixed states.\n\nReference:     http://iopscience.iop.org/article/10.1088/1367-2630/aa6a4b/meta\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.fidelity_pure-Tuple{Array{T,1} where T,Array{T,1} where T}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.fidelity_pure",
    "category": "method",
    "text": "fidelity for pure states.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.flip-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.flip",
    "category": "method",
    "text": "flip(index::Int, mask::Int) -> Int\n\nReturn an Integer with bits at masked position flipped.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.general_c1_gates-Union{Tuple{Tp}, Tuple{Tg}, Tuple{Int64,Tp,Int64,Array{Tg,1},Array{Int64,1}}} where Tp<:(AbstractArray{T,2} where T) where Tg<:(AbstractArray{T,2} where T)",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.general_c1_gates",
    "category": "method",
    "text": "general_c1_gates(num_bit::Int, projector::AbstractMatrix, cbit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix\n\ngeneral (low performance) construction method for control gate on different lines.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.general_controlled_gates-Tuple{Int64,Array{#s12,1} where #s12<:(AbstractArray{T,2} where T),Array{Int64,1},Array{#s16,1} where #s16<:(AbstractArray{T,2} where T),Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.general_controlled_gates",
    "category": "method",
    "text": "general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix\n\nReturn general multi-controlled gates in hilbert space of num_bit qubits,\n\nprojectors are often chosen as P0 and P1 for inverse-Control and Control at specific position.\ncbits should have the same length as projectors, specifing the controling positions.\ngates are a list of controlled single qubit gates.\nlocs should have the same length as gates, specifing the gates positions.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.getcol-Tuple{Union{SSparseMatrixCSC, SparseMatrixCSC},Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.getcol",
    "category": "method",
    "text": "getcol(csc::SDparseMatrixCSC, icol::Int) -> (View, View)\n\nget specific col of a CSC matrix, returns a slice of (rowval, nzval)\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.hilbertkron-Union{Tuple{T}, Tuple{Int64,Array{T,1},Array{Int64,1}}} where T<:(AbstractArray{T,2} where T)",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.hilbertkron",
    "category": "method",
    "text": "hilbertkron(num_bit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix\n\nReturn general kronecher product form of gates in Hilbert space of num_bit qubits.\n\ngates are a list of matrices.\nstart_locs should have the same length as gates, specifing the gates starting positions.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.hypercubic-Tuple{Array}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.hypercubic",
    "category": "method",
    "text": "hypercubic(A::Union{Array, DefaultRegister}) -> Array\n\nget the hypercubic representation for an array or a regiseter.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.indices_with-Tuple{Int64,Array{Int64,1},Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.indices_with",
    "category": "method",
    "text": "indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{Int}) -> Vector{Int}\n\nReturn indices with specific positions poss with value vals in a hilbert space of num_bit qubits.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.isreflexive-Tuple{Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.isreflexive",
    "category": "method",
    "text": "isreflexive(op) -> Bool\n\ncheck if this operator is reflexive.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.isunitary-Tuple{Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.isunitary",
    "category": "method",
    "text": "isunitary(op) -> Bool\n\ncheck if this operator is a unitary operator.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.itercontrol-Tuple{Int64,Array{Int64,1},Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.itercontrol",
    "category": "method",
    "text": "itercontrol(num_bit::Int, poss::Vector{Int}, vals::Vector{Int}) -> IterControl\n\nReturn the iterator for basis with poss controlled to values vals, with the total number of bits num_bit.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.linop2dense-Tuple{Function,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.linop2dense",
    "category": "method",
    "text": "linop2dense(applyfunc!::Function, num_bit::Int) -> Matrix\n\nget the dense matrix representation given matrix*matrix function.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.log2i",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.log2i",
    "category": "function",
    "text": "log2i(x::Integer) -> Integer\n\nReturn log2(x), this integer version of log2 is fast but only valid for number equal to 2^n.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.matvec",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.matvec",
    "category": "function",
    "text": "matvec(x::VecOrMat) -> MatOrVec\n\nReturn vector if a matrix is a column vector, else untouched.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.mulcol!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.mulcol!",
    "category": "function",
    "text": "mulcol!(v::AbstractVector, i::Int, f) -> VecOrMat\n\nmultiply col i of v by f inplace.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.mulrow!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.mulrow!",
    "category": "function",
    "text": "mulrow!(v::AbstractVector, i::Int, f) -> VecOrMat\n\nmultiply row i of v by f inplace.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.neg-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.neg",
    "category": "method",
    "text": "neg(index::Int, num_bit::Int) -> Int\n\nReturn an integer with all bits flipped (with total number of bit num_bit).\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.onehotvec-Union{Tuple{T}, Tuple{Type{T},Int64,Int64}} where T",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.onehotvec",
    "category": "method",
    "text": "onehotvec(::Type{T}, num_bit::Int, x::DInt) -> Vector{T}\n\none-hot wave vector.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.packbits-Tuple{AbstractArray{T,1} where T}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.packbits",
    "category": "method",
    "text": "packbits(arr::AbstractArray) -> AbstractArray\n\npack bits to integers, usually take a BitArray as input.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.rand_hermitian-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.rand_hermitian",
    "category": "method",
    "text": "rand_hermitian(N::Int) -> Matrix\n\nRandom hermitian matrix.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.rand_unitary-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.rand_unitary",
    "category": "method",
    "text": "rand_unitary(N::Int) -> Matrix\n\nRandom unitary matrix.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.reordered_basis-Tuple{Int64,Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.reordered_basis",
    "category": "method",
    "text": "Reordered Basis\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.setbit-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.setbit",
    "category": "method",
    "text": "setbit(index::Int, mask::Int) -> Int\n\nset the bit at masked position to 1.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.setcol!-Tuple{SparseArrays.SparseMatrixCSC,Int64,AbstractArray{T,1} where T,Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.setcol!",
    "category": "method",
    "text": "setcol!(csc::SparseMatrixCSC, icol::Int, rowval::AbstractVector, nzval) -> SparseMatrixCSC\n\nset specific col of a CSC matrix\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.swapbits-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.swapbits",
    "category": "method",
    "text": "swapbits(num::Int, mask12::Int) -> Int\n\nReturn an integer with bits at i and j flipped.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.swapcols!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.swapcols!",
    "category": "function",
    "text": "swapcols!(v::VecOrMat, i::Int, j::Int[, f1, f2]) -> VecOrMat\n\nswap col i and col j of v inplace, with f1, f2 factors applied on i and j (before swap).\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.swaprows!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.swaprows!",
    "category": "function",
    "text": "swaprows!(v::VecOrMat, i::Int, j::Int[, f1, f2]) -> VecOrMat\n\nswap row i and row j of v inplace, with f1, f2 factors applied on i and j (before swap).\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.takebit-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.takebit",
    "category": "method",
    "text": "takebit(index::Int, bits::Int...) -> Int\n\nReturn a bit(s) at specific position.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.testall-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.testall",
    "category": "method",
    "text": "testall(index::Int, mask::Int) -> Bool\n\nReturn true if all masked position of index is 1.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.testany-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.testany",
    "category": "method",
    "text": "testany(index::Int, mask::Int) -> Bool\n\nReturn true if any masked position of index is 1.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.testval-Tuple{Int64,Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.testval",
    "category": "method",
    "text": "testval(index::Int, mask::Int, onemask::Int) -> Bool\n\nReturn true if values at positions masked by mask with value 1 at positions masked by onemask and 0 otherwise.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.u1rows!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.u1rows!",
    "category": "function",
    "text": "u1rows!(state::VecOrMat, i::Int, j::Int, a, b, c, d) -> VecOrMat\n\napply u1 on row i and row j of state inplace.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.unmat-Tuple{Int64,AbstractArray{T,2} where T,Tuple{Vararg{T,N}} where T where N}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.unmat",
    "category": "method",
    "text": "unmat(nbit::Int, U::AbstractMatrix, locs::NTuple) -> AbstractMatrix\n\nReturns the matrix representation of putting matrix at locs.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Base.sort-Tuple{Tuple}",
    "page": "Intrinsics",
    "title": "Base.sort",
    "category": "method",
    "text": "sort(t::Tuple; lt=isless, by=identity, rev::Bool=false) -> ::Tuple\n\nSorts the tuple t.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Base.sortperm-Tuple{Tuple}",
    "page": "Intrinsics",
    "title": "Base.sortperm",
    "category": "method",
    "text": "sortperm(t::Tuple; lt=isless, by=identity, rev::Bool=false) -> ::Tuple\n\nComputes a tuple that contains the permutation required to sort t.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.autostatic-Tuple{Union{AbstractArray{T,1}, AbstractArray{T,2}} where T}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.autostatic",
    "category": "method",
    "text": "turn a vector/matrix to static vector/matrix (only if its length <= 256).\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.u1ij!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.u1ij!",
    "category": "function",
    "text": "u1ij!(target, i, j, a, b, c, d)\n\nsingle u1 matrix into a target matrix.\n\nNote: For coo, we take a additional parameter     * ptr: starting position to store new data.\n\n\n\n\n\n"
},

{
    "location": "man/intrinsics/#Intrinsics-1",
    "page": "Intrinsics",
    "title": "Intrinsics",
    "category": "section",
    "text": "Modules = [Yao.Intrinsics]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/boost/#",
    "page": "Boost",
    "title": "Boost",
    "category": "page",
    "text": ""
},

{
    "location": "man/boost/#Yao.Boost.controlled_U1",
    "page": "Boost",
    "title": "Yao.Boost.controlled_U1",
    "category": "function",
    "text": "controlled_U1(num_bit::Int, gate::AbstractMatrix, cbits::Vector{Int}, b2::Int) -> AbstractMatrix\n\nReturn general multi-controlled single qubit gate in hilbert space of num_bit qubits.\n\ncbits specify the controling positions.\nb2 is the controlled position.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.cxgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Any,Any,Union{UnitRange{Int64}, Int64, Array{Int64,1}}}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.cxgate",
    "category": "method",
    "text": "cxgate(::Type{MT}, num_bit::Int, b1::Ints, b2::Ints) -> PermMatrix\n\nSingle (Multiple) Controlled-X Gate on single (multiple) bits.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.cygate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Any,Any,Int64}} where MT<:Complex",
    "page": "Boost",
    "title": "Yao.Boost.cygate",
    "category": "method",
    "text": "cygate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) -> PermMatrix\n\nSingle Controlled-Y Gate on single bit.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.czgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Any,Any,Int64}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.czgate",
    "category": "method",
    "text": "czgate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) -> Diagonal\n\nSingle Controlled-Z Gate on single bit.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.xgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Union{UnitRange{Int64}, Int64, Array{Int64,1}}}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.xgate",
    "category": "method",
    "text": "xgate(::Type{MT}, num_bit::Int, bits::Ints) -> PermMatrix\n\nX Gate on multiple bits.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.ygate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Union{UnitRange{Int64}, Int64, Array{Int64,1}}}} where MT<:Complex",
    "page": "Boost",
    "title": "Yao.Boost.ygate",
    "category": "method",
    "text": "ygate(::Type{MT}, num_bit::Int, bits::Ints) -> PermMatrix\n\nY Gate on multiple bits.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.zgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Union{UnitRange{Int64}, Int64, Array{Int64,1}}}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.zgate",
    "category": "method",
    "text": "zgate(::Type{MT}, num_bit::Int, bits::Ints) -> Diagonal\n\nZ Gate on multiple bits.\n\n\n\n\n\n"
},

{
    "location": "man/boost/#Boost-1",
    "page": "Boost",
    "title": "Boost",
    "category": "section",
    "text": "Boost is an optimization module that offers many functions for optimization.Modules = [Yao.Boost]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "dev/extending-blocks/#",
    "page": "Extending Blocks",
    "title": "Extending Blocks",
    "category": "page",
    "text": "CurrentModule = Yao.Blocks"
},

{
    "location": "dev/extending-blocks/#Extending-Blocks-1",
    "page": "Extending Blocks",
    "title": "Extending Blocks",
    "category": "section",
    "text": ""
},

{
    "location": "dev/extending-blocks/#Extending-constant-gate-1",
    "page": "Extending Blocks",
    "title": "Extending constant gate",
    "category": "section",
    "text": "We prepared a macro for you about constant gates like X, Y, Z.Simply use @const_gate."
},

{
    "location": "dev/extending-blocks/#Extending-Primitive-Block-with-parameters-1",
    "page": "Extending Blocks",
    "title": "Extending Primitive Block with parameters",
    "category": "section",
    "text": "First, define your own block type by subtyping PrimitiveBlock. And import methods you will need to overloadusing Yao, Yao.Blocks\nimport Yao.Blocks: mat, dispatch!, parameters # this is the mimimal methods you will need to overload\n\nmutable struct NewPrimitive{T} <: PrimitiveBlock{1, T}\n   theta::T\nendSecond define its matrix form.mat(g::NewPrimitive{T}) where T = Complex{T}[sin(g.theta) 0; cos(g.theta) 0]Yao will use this matrix to do the simulation by default. However, if you know how to directly apply your block to a quantum register, you can also overload apply! to make your simulation become more efficient. But this is not required.import Yao.Blocks: apply!\napply!(r::AbstractRegister, x::NewPrimitive) = # some efficient way to simulate this blockThird If your block contains parameters, declare which member it is with dispatch! and how to get them by parametersdispatch!(g::NewPrimitive, theta) = (g.theta = theta; g)\nparameters(x::NewPrimitive) = x.thetaThe prototype of dispatch! is simple, just directly write the parameters as your function argument. e.gmutable struct MultiParam{N, T} <: PrimitiveBlock{N, Complex{T}}\n  theta::T\n  phi::T\nendjust write:dispatch!(x::MultiParam, theta, phi) = (x.theta = theta; x.phi = phi; x)or maybe your block contains a vector of parameters:mutable struct VecParam{N, T} <: PrimitiveBlock{N, T}\n  params::Vector{T}\nendjust write:dispatch!(x::VecParam, params) = (x.params .= params; x)be careful, the assignment should be in-placed with .= rather than =.If the number of parameters in your new block is fixed, we recommend you to declare this with a type trait nparameters:import Yao.Blocks: nparameters\nnparameters(::Type{<:NewPrimitive}) = 1But it is OK if you do not define this trait, Yao will find out how many parameters you have dynamically.Fourth If you want to enable cache of this new block, you have to define your own cachekey. usually just use your parameters as the key if you want to cache the matrix form of different parameters, which will accelerate your simulation with a cost of larger memory allocation. You can simply define it with [`cachekey`](@ref)import Yao.Blocks: cache_key\ncache_key(x::NewPrimitive) = x.theta"
},

{
    "location": "dev/extending-blocks/#Extending-Composite-Blocks-1",
    "page": "Extending Blocks",
    "title": "Extending Composite Blocks",
    "category": "section",
    "text": "Composite blocks are blocks that are able to contain other blocks. To define a new composite block you only need to define your new type as a subtype of CompositeBlock, and define a new method called subblocks which will provide an iterator that iterates the blocks contained by this composite block."
},

{
    "location": "dev/extending-blocks/#Custom-Pretty-Printing-1",
    "page": "Extending Blocks",
    "title": "Custom Pretty Printing",
    "category": "section",
    "text": "The whole quantum circuit is represented as a tree in the block system. Therefore, we print a block as a tree. To define your own syntax to print, simply overloads the print_block method. Then it will appears in the block tree syntax automatically.print_block(io::IO, block::MyBlockType)"
},

{
    "location": "dev/extending-blocks/#Adding-Operator-Traits-to-Your-Blocks-1",
    "page": "Extending Blocks",
    "title": "Adding Operator Traits to Your Blocks",
    "category": "section",
    "text": "A gate G can have following traitsisunitary - G^dagger G = mathbb1\nisreflexive - GG = mathbb1\nishermitian - G^dagger = GIf G is a MatrixBlock, these traits can fall back to using mat method albiet not efficient. If you can know these traits of a gate clearly, you can define them by hand to improve performance.These traits are useful, e.g. a RotationGate defines an SU(2) rotation, which requires its generator both hermitian a reflexive so that R_G(theta) = cosfractheta2 - isinfractheta2 G, so that you can use R_rm X and R_rm CNOT but not R_rm R_X(03)."
},

{
    "location": "dev/extending-blocks/#Adding-Tags-to-Your-Blocks-1",
    "page": "Extending Blocks",
    "title": "Adding Tags to Your Blocks",
    "category": "section",
    "text": "A tag refers toDaggered - G^dagger   We use Base.adjoint(G) to generate a daggered block.\nIf a block is hermitian, do nothing,\nFor many blocks, e.g. Rx(0.3), we can still define some rule like Base.adjoint(r::RotationBlock) = (res = copy(r); res.theta = -r.theta; res),\nif even simple rule does not exist, its mat function will fall back to mat(G)\'.\nCachedBlock - the matrix of this block under current parameter will be stored in cache server for future use.\nG |> cache can be useful when you are trying to compile a block into a reuseable matrix, to use cache, you should define cache_key."
},

{
    "location": "dev/benchmark/#",
    "page": "Benchmark with ProjectQ",
    "title": "Benchmark with ProjectQ",
    "category": "page",
    "text": ""
},

{
    "location": "dev/benchmark/#Benchmark-with-ProjectQ-1",
    "page": "Benchmark with ProjectQ",
    "title": "Benchmark with ProjectQ",
    "category": "section",
    "text": "ProjectQ is an open source software framework for quantum computing. Here we present the single process benchmark result<img src=\"../assets/benchmarks/xyz-bench.png\"    alt=\"xyz\" height=\"200\">\n<img src=\"../assets/benchmarks/repeatxyz-bench.png\" alt=\"xyz\" height=\"200\">\n<img src=\"../assets/benchmarks/cxyz-bench.png\"      alt=\"xyz\" height=\"200\">\n<img src=\"../assets/benchmarks/crot-bench.png\"      alt=\"xyz\" height=\"200\">\n<img src=\"../assets/benchmarks/hgate-bench.png\"     alt=\"xyz\" height=\"200\">\n<img src=\"../assets/benchmarks/rot-bench.png\"       alt=\"xyz\" height=\"200\">From this benchmark, we see the performance of ProjectQ and Yao.jl are quite similar, both of them are close to the theoretical bound in performance.ProjectQ is a state of art quantum simulator, it kept the record of 45 qubit quantum circuit simulation for several months: https://arxiv.org/abs/1704.01127 4 It uses parallisms like SIMD, OpenMP, MPI to speed up calculation.ProjectQ has C++ backend, while Yao.jl uses pure julia. Yao.jl has significantly less overhead than ProjectQ, which benefits from julia’s jit and multile dispatch.In some benchmarks, like repeated blocks, Yao.jl can perform much better, this is an algorithmic win. Thanks to julia’s multiple dispatch, we can dispatch any advanced-speciallized algortihm to push the performance for frequently used gates easily, without touching the backend!"
},

{
    "location": "dev/benchmark/#CPU-Information-1",
    "page": "Benchmark with ProjectQ",
    "title": "CPU Information",
    "category": "section",
    "text": "Architecture:          x86_64\nCPU op-mode(s):        32-bit, 64-bit\nByte Order:            Little Endian\nCPU(s):                48\nOn-line CPU(s) list:   0-47\nThread(s) per core:    2\nCore(s) per socket:    12\nSocket(s):             2\nNUMA node(s):          2\nVendor ID:             GenuineIntel\nCPU family:            6\nModel:                 79\nStepping:              1\nCPU MHz:               2499.921\nBogoMIPS:              4401.40\nVirtualization:        VT-x\nL1d cache:             32K\nL1i cache:             32K\nL2 cache:              256K\nL3 cache:              30720K\nNUMA node0 CPU(s):     0-11,24-35\nNUMA node1 CPU(s):     12-23,36-47"
},

{
    "location": "dev/benchmark/#ProjectQ-1",
    "page": "Benchmark with ProjectQ",
    "title": "ProjectQ",
    "category": "section",
    "text": "We use ProjectQ v0.3.6 in this benchmark, with python version 3.6.Github Repo\nDamian S. Steiger, Thomas Häner, and Matthias Troyer \"ProjectQ: An Open Source Software Framework for Quantum Computing\" [arxiv:1612.08091]\nThomas Häner, Damian S. Steiger, Krysta M. Svore, and Matthias Troyer \"A Software Methodology for Compiling Quantum Programs\" [arxiv:1604.01401]"
},

{
    "location": "dev/benchmark/#Julia-Version-1",
    "page": "Benchmark with ProjectQ",
    "title": "Julia Version",
    "category": "section",
    "text": "Julia Version 0.7.0-alpha.147\nCommit 5e3259e (2018-06-16 18:43 UTC)\nPlatform Info:\n  OS: Linux (x86_64-linux-gnu)\n  CPU: Intel(R) Xeon(R) CPU E5-2650 v4 @ 2.20GHz\n  WORD_SIZE: 64\n  LIBM: libopenlibm\n  LLVM: libLLVM-6.0.0 (ORCJIT, broadwell)"
},

]}
