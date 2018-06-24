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
    "text": "Pages = [\n    \"tutorial/GHZ.md\",\n    \"tutorial/QFT.md\",\n    \"tutorial/QCBM.md\",\n]\nDepth = 1"
},

{
    "location": "#Manual-1",
    "page": "Home",
    "title": "Manual",
    "category": "section",
    "text": "Pages = [\n    \"man/interfaces.md\",\n    \"man/registers.md\",\n    \"man/blocks.md\",\n    \"man/cache.md\",\n    \"man/intrinsics.md\",\n    \"man/luxurysparse.md\",\n]\nDepth = 1"
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
    "text": "First, you have to use this package in Julia.using YaoThen let\'s define the oracle, it is a function of the number of qubits. The circuit looks like this:(Image: ghz)n = 4\ncircuit(n) = chain(\n    n,\n    repeat(X, [1, ]),\n    kron(i=>H for i in 2:n),\n    control([2, ], 1=>X),\n    control([4, ], 3=>X),\n    control([3, ], 1=>X),\n    control([4, ], 3=>X),\n    kron(i=>H for i in 1:n),\n)Let me explain what happens here. Firstly, we have a X gate which is applied to the first qubit. We need decide how we calculate this numerically, Yao offers serveral different approach to this. The simplest (but not the most efficient) one is to use kronecker product which will product X with I on other lines to gather an operator in the whole space and then apply it to the register. The first argument n means the number of qubits.kron(n, 1=>X)Similar with kron, we then need to apply some controled gates.control(n, [2, ], 1=>X)This means there is a X gate on the first qubit that is controled by the second qubit. In fact, you can also create a controled gate with multiple control qubits, likecontrol(n, [2, 3], 1=>X)In the end, we need to apply H gate to all lines, of course, you can do it by kron, but we offer something more efficient called roll, this applies a single gate each time on each qubit without calculating a new large operator, which will be extremely efficient for calculating small gates that tiles on almost every lines.The whole circuit is a chained structure of the above blocks. And we actually store a quantum circuit in a tree structure.circuitAfter we have an circuit, we can construct a quantum register, and input it into the oracle. You will then receive this register after processing it.r = with(register(bit\"0000\")) do r\n  r |> circuit(4)\nendLet\'s check the output:statevec(r)We have a GHZ state here, try to measure the first qubitmeasure(r, 1000)(Image: GHZ)GHZ state will collapse to 0000rangle or 1111rangle due to entanglement!"
},

{
    "location": "tutorial/QFT/#",
    "page": "Quantum Fourier Transform",
    "title": "Quantum Fourier Transform",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial/QFT/#Quantum-Fourier-Transform-1",
    "page": "Quantum Fourier Transform",
    "title": "Quantum Fourier Transform",
    "category": "section",
    "text": "(Image: ghz)using Yao\n\n# Control-R(k) gate in block-A\nA(i::Int, j::Int, k::Int) = control([i, ], j=>shift(-2π/(1<<k)))\n# block-B\nB(n::Int, i::Int) = chain(i==j ? kron(i=>H) : A(j, i, j-i+1) for j = i:n)\nQFT(n::Int) = chain(n, B(n, i) for i = 1:n)\n\n# define QFT and IQFT block.\nnum_bit = 5\nqft = QFT(num_bit)\niqft = adjoint(qft)The basic building block - controled phase shift gate is defined asR(k)=beginbmatrix\n1  0\n0  expleft(frac2pi i2^kright)\nendbmatrixNow let\'s check the result using classical fft# if you\'re using lastest julia, you need to add the fft package.\n@static if VERSION >= v\"0.7-\"\n    using FFTW\nend\nusing Compat.Test\n\n@test chain(num_bit, qft, iqft) |> mat ≈ eye(2^num_bit)\n\n# define a register and get its vector representation\nreg = rand_state(num_bit)\nrv = reg |> statevec |> copy\n\n# test fft\nreg_qft = copy(reg) |>invorder! |> qft\nkv = fft(rv)/sqrt(length(rv))\n@test reg_qft |> statevec ≈ kv\n\n# test ifft\nreg_iqft = copy(reg) |>iqft\nkv = ifft(rv)*sqrt(length(rv))\n@test reg_iqft |> statevec ≈ kv |> invorderQFT and IQFT are different from FFT and IFFT in two ways,they are different by a factor of sqrt2^n with n the number of qubits.\nthe little end and big end will exchange after applying QFT or IQFT.In Yao, factory methods for blocks will be loaded lazily. For example, if you missed the total number of qubits of chain, then it will return a function that requires an input of an integer.If you missed the total number of qubits. It is OK. Just go on, it will be filled when its possible.chain(4, repeat(1=>X), kron(2=>Y))"
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
    "text": "Arbitrary Rotation is built with Rotation Gate on Z, Rotation Gate on X and Rotation Gate on Z:Rz(theta) cdot Rx(theta) cdot Rz(theta)Since our input will be a 0dots 0rangle state. The first layer of arbitrary rotation can just use Rx(theta) cdot Rz(theta) and the last layer of arbitrary rotation could just use Rz(theta)cdot Rx(theta)In 幺, every Hilbert operator is a block type, this includes all quantum gates and quantum oracles. In general, operators appears in a quantum circuit can be divided into Composite Blocks and Primitive Blocks.We follow the low abstraction principle and thus each block represents a certain approach of calculation. The simplest Composite Block is a Chain Block, which chains other blocks (oracles) with the same number of qubits together. It is just a simple mathematical composition of operators with same size. e.g.textchain(X Y Z) iff X cdot Y cdot ZWe can construct an arbitrary rotation block by chain Rz, Rx, Rz together.chain(Rz(), Rx(), Rz())Rx, Ry and Rz will construct new rotation gate, which are just shorthands for rot(X, 0.0), etc.Then, let\'s pile them up vertically with another method called rollrepeatlayer(x::Symbol) = layer(Val(x))\nlayer(::Val{:first}) = rollrepeat(chain(Rx(), Rz()))In 幺, the factory method rollrepeat will construct a block called Roller. It is mathematically equivalent to the kronecker product of all operators in this layer:rollrepeat(n U) iff roll(n texti=U for i = 1n) iff kron(n texti=U for i=1n) iff U otimes dots otimes Uroll(4, i=>X for i = 1:4)rollrepeat(4, X)kron(4, i=>X for i = 1:4)However, kron is calculated differently comparing to roll. In principal, Roller will be able to calculate small blocks with same size with higher efficiency. But for large blocks Roller may be slower. In 幺, we offer you this freedom to choose the most suitable solution.all factory methods will lazy evaluate the first arguements, which is the number of qubits. It will return a lambda function that requires a single interger input. The instance of desired block will only be constructed until all the information is filled.rollrepeat(X)rollrepeat(X)(4)When you filled all the information in somewhere of the declaration, 幺 will be able to infer the others.chain(4, rollrepeat(X), rollrepeat(Y))We will now define the rest of rotation layerslayer(::Val{:last}) = rollrepeat(chain(Rz(), Rx()))\nlayer(::Val{:mid}) = rollrepeat(chain(Rz(), Rx(), Rz()))"
},

{
    "location": "tutorial/QCBM/#CNOT-Entangler-1",
    "page": "Quantum Circuit Born Machine",
    "title": "CNOT Entangler",
    "category": "section",
    "text": "Another component of quantum circuit born machine is several CNOT operators applied on different qubits.entangler(pairs) = chain(control([ctrl, ], target=>X) for (ctrl, target) in pairs)We can then define such a born machinefunction QCBM(n, nlayer, pairs)\n    circuit = chain(n)\n    push!(circuit, layer(:first))\n\n    for i = 1:(nlayer - 1)\n        push!(circuit, cache(entangler(pairs)))\n        push!(circuit, layer(:mid))\n    end\n\n    push!(circuit, cache(entangler(pairs)))\n    push!(circuit, layer(:last))\n\n    circuit\nend\nnothing # hideWe use the method cache here to tag the entangler block that it should be cached after its first run, because it is actually a constant oracle. Let\'s see what will be constructedQCBM(4, 1, [1=>2, 2=>3, 3=>4])Let\'s define a circuit to use latercircuit = QCBM(6, 10, [1=>2, 3=>4, 5=>6, 2=>3, 4=>5, 6=>1])\nnothing # hide"
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
    "text": "the gradient of MMD loss isbeginaligned\nfracpartial mathcalLpartial theta^i_l = langle K(x y) rangle_xsim p_theta^+ ysim p_theta - langle K(x y) rangle_xsim p_theta^- ysim p_theta\n- langle K(x y) rangle _xsim p_theta^+ ysimpi + langle K(x y) rangle_xsim p_theta^- ysimpi\nendalignedWe have to update one parameter of each rotation gate each time, and calculate its gradient then collect them. Since we will need to calculate the probability from the state vector frequently, let\'s define a shorthand first.Firstly, you have to define a quantum register. Each run of a QCBM\'s input is a simple 00cdots 0rangle state. We provide string literal bit to help you define one-hot state vectors like thisr = register(bit\"0000\")We provide two method to apply a block to a register:with(f, register)This method declares a context that has no side-effect, which means rather than apply a block directly to a register, it will copy the register first and then apply the block to this copy.with!(f, register)This method declares a context that will have side-effect, which means the block will be applied to the register directly.In side the context you should use a pip |> to apply a block, which will looks like this:our_register = register(bit\"0\"^5)\n\nnew_register = with(our_register) do r\n    r |> kron(1=>X)\n    r |> kron(2=>X)\nendstate(new_register) ≈ state(our_register)\nstate(new_register) ≈ state(register(bit\"00011\"))For convenience, we also provide the following interface, which allows you to apply a pre-defined circuit to a register.with(block, register)\nwith!(block, register)with(circuit, register(bit\"0\"^6))Now, we define its shorthandget_prob(qcbm) = with!(qcbm, register(bit\"0\"^6)) |> statevec .|> abs2We will first iterate through each layer contains rotation gates and allocate an array to store our gradientfunction gradient(n, nlayers, qcbm, kernel, ptrain)\n    prob = get_prob(qcbm)\n    grad = zeros(real(datatype(qcbm)), nparameters(qcbm))\n    idx = 0\n    for ilayer = 1:2:(2 * nlayers + 1)\n        idx = grad_layer!(grad, idx, prob, qcbm, qcbm[ilayer], kernel, ptrain)\n    end\n    grad\nendThen we iterate through each rotation gate.function grad_layer!(grad, idx, prob, qcbm, layer, kernel, ptrain)\n    count = idx\n    for each_line in blocks(layer)\n        for each in blocks(each_line)\n            gradient!(grad, count+1, prob, qcbm, each, kernel, ptrain)\n            count += 1\n        end\n    end\n    count\nendWe update each parameter by rotate it -pi2 and pi2function gradient!(grad, idx, prob, qcbm, gate, kernel, ptrain)\n    dispatch!(+, gate, pi / 2)\n    prob_pos = get_prob(qcbm)\n\n    dispatch!(-, gate, pi)\n    prob_neg = get_prob(qcbm)\n\n    dispatch!(+, gate, pi / 2) # set back\n\n    grad_pos = expect(kernel, prob, prob_pos) - expect(kernel, prob, prob_neg)\n    grad_neg = expect(kernel, ptrain, prob_pos) - expect(kernel, ptrain, prob_neg)\n    grad[idx] = grad_pos - grad_neg\n    grad\nend"
},

{
    "location": "tutorial/QCBM/#Optimizer-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Optimizer",
    "category": "section",
    "text": "We will use the Adam optimizer. Since we don\'t want you to install another package for this, the following code for this optimizer is copied from Knet.jlReference: Kingma, D. P., & Ba, J. L. (2015). Adam: a Method for Stochastic Optimization. International Conference on Learning Representations, 1–13.mutable struct Adam\n    lr::AbstractFloat\n    gclip::AbstractFloat\n    beta1::AbstractFloat\n    beta2::AbstractFloat\n    eps::AbstractFloat\n    t::Int\n    fstm\n    scndm\nend\n\nAdam(; lr=0.001, gclip=0, beta1=0.9, beta2=0.999, eps=1e-8)=Adam(lr, gclip, beta1, beta2, eps, 0, nothing, nothing)\n\nfunction update!(w, g, p::Adam)\n    gclip!(g, p.gclip)\n    if p.fstm===nothing; p.fstm=zeros(w); p.scndm=zeros(w); end\n    p.t += 1\n    BLAS.scale!(p.beta1, p.fstm)\n    BLAS.axpy!(1-p.beta1, g, p.fstm)\n    BLAS.scale!(p.beta2, p.scndm)\n    BLAS.axpy!(1-p.beta2, g .* g, p.scndm)\n    fstm_corrected = p.fstm / (1 - p.beta1 ^ p.t)\n    scndm_corrected = p.scndm / (1 - p.beta2 ^ p.t)\n    BLAS.axpy!(-p.lr, (fstm_corrected ./ (sqrt.(scndm_corrected) + p.eps)), w)\nend\n\nfunction gclip!(g, gclip)\n    if gclip == 0\n        g\n    else\n        gnorm = vecnorm(g)\n        if gnorm <= gclip\n            g\n        else\n            BLAS.scale!(gclip/gnorm, g)\n        end\n    end\nend"
},

{
    "location": "tutorial/QCBM/#Start-Training-1",
    "page": "Quantum Circuit Born Machine",
    "title": "Start Training",
    "category": "section",
    "text": "The training of the quantum circuit is simple, just iterate through the steps.function train!(qcbm, ptrain, optim; learning_rate=0.1, niter=50)\n    # initialize the parameters\n    params = 2pi * rand(nparameters(qcbm))\n    dispatch!(qcbm, params)\n    kernel = Kernel(nqubits(qcbm), 0.25)\n\n    n, nlayers = nqubits(qcbm), (length(qcbm)-1)÷2\n    history = Float64[]\n\n    for i = 1:niter\n        grad = gradient(n, nlayers, qcbm, kernel, ptrain)\n        curr_loss = loss(qcbm, kernel, ptrain)\n        push!(history, curr_loss)        \n        params = parameters(qcbm)\n        update!(params, grad, optim)\n        dispatch!(qcbm, params)\n    end\n    history\nendoptim = Adam(lr=0.1)\nhis = train!(circuit, pg, optim, niter=50, learning_rate=0.1)\nplot(1:50, his, xlabel=\"iteration\", ylabel=\"loss\")(Image: History)p = get_prob(circuit)\nplot(0:1<<n-1, p, pg, xlabel=\"x\", ylabel=\"p\")(Image: Learnt Distribution)"
},

{
    "location": "man/yao/#",
    "page": "Yao",
    "title": "Yao",
    "category": "page",
    "text": ""
},

{
    "location": "man/yao/#Yao",
    "page": "Yao",
    "title": "Yao",
    "category": "module",
    "text": "Extensible Framework for Quantum Algorithm Design for Humans.\n\n简单易用可扩展的量子算法设计框架。\n\n\n\n"
},

{
    "location": "man/yao/#Yao.幺",
    "page": "Yao",
    "title": "Yao.幺",
    "category": "module",
    "text": "Extensible Framework for Quantum Algorithm Design for Humans.\n\n简单易用可扩展的量子算法设计框架。\n\n幺 means unitary in Chinese.\n\n\n\n"
},

{
    "location": "man/yao/#Yao.nactive",
    "page": "Yao",
    "title": "Yao.nactive",
    "category": "function",
    "text": "nactive(x) -> Int\n\nReturns number of active qubits\n\n\n\n"
},

{
    "location": "man/yao/#Yao.nqubits",
    "page": "Yao",
    "title": "Yao.nqubits",
    "category": "function",
    "text": "nqubits(m::AbstractRegister) -> Int\n\nReturns number of qubits in a register,\n\nnqubits(m::AbstractBlock) -> Int\n\nReturns number of qubits applied for a block,\n\nnqubits(m::AbstractArray) -> Int\n\nReturns size of the first dimension of an array, in 2^nqubits.\n\n\n\n"
},

{
    "location": "man/yao/#Yao.reorder",
    "page": "Yao",
    "title": "Yao.reorder",
    "category": "function",
    "text": "Reorder the lines of qubits.\n\n\n\n"
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
    "text": "H\n\nThe Hadamard gate acts on a single qubit. It maps the basis state 0rangle to frac0rangle + 1ranglesqrt2 and 1rangle to frac0rangle - 1ranglesqrt2, which means that a measurement will have equal probabilities to become 1 or 0. It is representated by the Hadamard matrix:\n\nH = frac1sqrt2 beginpmatrix\n1  1 \n1  -1\nendpmatrix\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.X",
    "page": "Interfaces",
    "title": "Yao.Blocks.X",
    "category": "constant",
    "text": "X\n\nThe Pauli-X gate acts on a single qubit. It is the quantum equivalent of the NOT gate for classical computers (with respect to the standard basis 0rangle, 1rangle). It is represented by the Pauli X matrix:\n\nX = beginpmatrix\n0  1\n1  0\nendpmatrix\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.Y",
    "page": "Interfaces",
    "title": "Yao.Blocks.Y",
    "category": "constant",
    "text": "Y\n\nThe Pauli-Y gate acts on a single qubit. It equates to a rotation around the Y-axis of the Bloch sphere by pi radians. It maps 0rangle to i1rangle and 1rangle to -i0rangle. It is represented by the Pauli Y matrix:\n\nY = beginpmatrix\n0  -i\ni  0\nendpmatrix\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.Z",
    "page": "Interfaces",
    "title": "Yao.Blocks.Z",
    "category": "constant",
    "text": "Z\n\nThe Pauli-Z gate acts on a single qubit. It equates to a rotation around the Z-axis of the Bloch sphere by pi radians. Thus, it is a special case of a phase shift gate (see shift) with theta = pi. It leaves the basis state 0rangle unchanged and maps 1rangle to -1rangle. Due to this nature, it is sometimes called phase-flip. It is represented by the Pauli Z matrix:\n\nZ = beginpmatrix\n1  0\n0  -1\nendpmatrix\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.InvOrder",
    "page": "Interfaces",
    "title": "Yao.Interfaces.InvOrder",
    "category": "constant",
    "text": "InvOrder\n\nReturn a FunctionBlock of inversing the order.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Reset",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Reset",
    "category": "constant",
    "text": "Reset\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.@fn",
    "page": "Interfaces",
    "title": "Yao.Interfaces.@fn",
    "category": "macro",
    "text": "macro fn([name,] f)\n\nDefine a in-place function on a register inside circuits.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Rx",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Rx",
    "category": "function",
    "text": "Rx([type=Yao.DefaultType], theta) -> RotationGate{1, type, X}\n\nReturns a rotation X gate.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Ry",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Ry",
    "category": "function",
    "text": "Ry([type=Yao.DefaultType], theta) -> RotationGate{1, type, Y}\n\nReturns a rotation Y gate.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.Rz",
    "page": "Interfaces",
    "title": "Yao.Interfaces.Rz",
    "category": "function",
    "text": "Rz([type=Yao.DefaultType], theta) -> RotationGate{1, type, Z}\n\nReturns a rotation Z gate.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.addbit-Tuple{Int64}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.addbit",
    "category": "method",
    "text": "addbit(n::Int) -> FunctionBlock{:AddBit}\n\nReturn a FunctionBlock of adding n bits.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.chain",
    "page": "Interfaces",
    "title": "Yao.Interfaces.chain",
    "category": "function",
    "text": "chain([T], n::Int) -> ChainBlock\nchain([n], blocks) -> ChainBlock\n\nReturns a ChainBlock. This factory method can be called lazily if you missed the total number of qubits.\n\nThis chains several blocks with the same size together.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.concentrate-Tuple{Int64,Yao.Blocks.AbstractBlock,Array{Int64,1}}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.concentrate",
    "category": "method",
    "text": "concentrate(nbit::Int, block::AbstractBlock, addrs::Vector{Int}) -> Concentrator{nbit}\n\nconcentrate blocks on serveral addrs.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.control",
    "page": "Interfaces",
    "title": "Yao.Interfaces.control",
    "category": "function",
    "text": "control([total], controls, target) -> ControlBlock\n\nConstructs a ControlBlock\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.phase",
    "page": "Interfaces",
    "title": "Yao.Interfaces.phase",
    "category": "function",
    "text": "phase([type=Yao.DefaultType], theta) -> PhaseGate{:global}\n\nReturns a global phase gate.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.put-Union{Tuple{Int64,Pair{Tuple{Vararg{Int64,M}},#s442} where #s442<:Yao.Blocks.AbstractBlock}, Tuple{M}} where M",
    "page": "Interfaces",
    "title": "Yao.Interfaces.put",
    "category": "method",
    "text": "put([total::Int, ]pa::Pair) -> PutBlock{total}\n\nput a block at the specific position(s), can be lazy constructed.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.reflect",
    "page": "Interfaces",
    "title": "Yao.Interfaces.reflect",
    "category": "function",
    "text": "reflect(mirror::DefaultRegister{1}) -> ReflectBlock\nreflect(mirror::Vector) -> ReflectBlock\n\nReturn an ReflectBlock along with state vector mirror as the axis.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.roll",
    "page": "Interfaces",
    "title": "Yao.Interfaces.roll",
    "category": "function",
    "text": "roll([n::Int, ], blocks...) -> Roller{n}\n\nConstruct a Roller block, which is a faster than KronBlock to calculate similar small blocks tile on the whole address.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.rollrepeat",
    "page": "Interfaces",
    "title": "Yao.Interfaces.rollrepeat",
    "category": "function",
    "text": "rollrepeat([n::Int,] block::MatrixBlock) -> Roller{n}\n\nConstruct a Roller block, which is a faster than KronBlock to calculate similar small blocks tile on the whole address.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.rot",
    "page": "Interfaces",
    "title": "Yao.Interfaces.rot",
    "category": "function",
    "text": "rot([type=Yao.DefaultType], U, theta) -> RotationGate{N, type, U}\n\nReturns an arbitrary rotation gate on U.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.sequence",
    "page": "Interfaces",
    "title": "Yao.Interfaces.sequence",
    "category": "function",
    "text": "Returns a Sequential block. This factory method can be called lazily if you missed the total number of qubits.\n\nThis is the loose version of sequence, that does not support the mat related interfaces.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.shift",
    "page": "Interfaces",
    "title": "Yao.Interfaces.shift",
    "category": "function",
    "text": "shift([type=Yao.DefaultType], theta) -> PhaseGate{:shift}\n\nReturns a phase shift gate.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.swap",
    "page": "Interfaces",
    "title": "Yao.Interfaces.swap",
    "category": "function",
    "text": "swap([n], [type], line1, line2) -> Swap\n\nReturns a swap gate on line1 and line2\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.with!-Tuple{Function,Yao.Registers.AbstractRegister}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.with!",
    "category": "method",
    "text": "with!(f, register)\n\nProvide a writable context for blocks operating this register.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Interfaces.with-Tuple{Function,Yao.Registers.AbstractRegister}",
    "page": "Interfaces",
    "title": "Yao.Interfaces.with",
    "category": "method",
    "text": "with(f, register)\n\nProvide a copy context for blocks operating this register.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.XGate",
    "page": "Interfaces",
    "title": "Yao.Blocks.XGate",
    "category": "type",
    "text": "XGate{T} <: ConstantGate{1, T}\n\nThe block type for Pauli-X gate. See docs for X for more information.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.YGate",
    "page": "Interfaces",
    "title": "Yao.Blocks.YGate",
    "category": "type",
    "text": "YGate{T} <: ConstantGate{1, T}\n\nThe block type for Pauli-Y gate. See docs for Y for more information.\n\n\n\n"
},

{
    "location": "man/interfaces/#Yao.Blocks.ZGate",
    "page": "Interfaces",
    "title": "Yao.Blocks.ZGate",
    "category": "type",
    "text": "ZGate{T} <: ConstantGate{1, T}\n\nThe block type for Pauli-Z gate. See docs for Z for more information.\n\n\n\n"
},

{
    "location": "man/interfaces/#Base.kron-Tuple{Int64,Pair,Vararg{Union{Pair, Yao.Blocks.MatrixBlock},N} where N}",
    "page": "Interfaces",
    "title": "Base.kron",
    "category": "method",
    "text": "kron([total::Int, ]block0::Pair, blocks::Union{MatrixBlock, Pair}...) -> KronBlock{total}\n\ncreate a KronBlock with a list of blocks or tuple of heads and blocks. If total is not provided, return a lazy constructor.\n\nExample\n\nkron(4, 1=>X, 3=>Z, Y)\n\nThis will automatically generate a block list looks like\n\n1 -- [X] --\n2 ---------\n3 -- [Z] --\n4 -- [Y] --\n\n\n\n"
},

{
    "location": "man/interfaces/#Base.repeat-Tuple{Int64,Yao.Blocks.MatrixBlock,Any}",
    "page": "Interfaces",
    "title": "Base.repeat",
    "category": "method",
    "text": "repeat([n::Int,] x::MatrixBlock, [addrs]) -> RepeatedBlock{n}\n\nConstruct a RepeatedBlock, if n (the number of qubits) not supplied, using lazy evaluation. If addrs not supplied, blocks will fill the qubit space.\n\n\n\n"
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
    "text": "AbstractRegister{B, T}\n\nabstract type that registers will subtype from. B is the batch size, T is the data type.\n\nRequired Properties\n\nProperty Description default\nnqubits(reg) get the total number of qubits. \nnactive(reg) get the number of active qubits. \nnremain(reg) get the number of remained qubits. nqubits - nactive\nnbatch(reg) get the number of batch. B\nstate(reg) get the state of this register. It always return the matrix stored inside. \nstatevec(reg) get the raveled state of this register.                                  . \nhypercubic(reg) get the hypercubic form of this register.                                  . \neltype(reg) get the element type stored by this register on classical memory. (the type Julia should use to represent amplitude) T\ncopy(reg) copy this register. \nsimilar(reg) construct a new register with similar configuration. \n\nRequired Methods\n\nMultiply\n\n*(op, reg)\n\ndefine how operator op act on this register. This is quite useful when there is a special approach to apply an operator on this register. (e.g a register with no batch, or a register with a MPS state, etc.)\n\nnote: Note\nbe careful, generally, operators can only be applied to a register, thus we should only overload this operation and do not overload *(reg, op).\n\nPack Address\n\npack addrs together to the first k-dimensions.\n\nExample\n\nGiven a register with dimension [2, 3, 1, 5, 4], we pack [5, 4] to the first 2 dimensions. We will get [5, 4, 2, 3, 1].\n\nFocus Address\n\nfocus!(reg, range)\n\nmerge address in range together as one dimension (the active space).\n\nExample\n\nGiven a register with dimension (2^4)x3 and address [1, 2, 3, 4], we focus address [3, 4], will pack [3, 4] together and merge them as the active space. Then we will have a register with size 2^2x(2^2x3), and address [3, 4, 1, 2].\n\nInitializers\n\nInitializers are functions that provide specific quantum states, e.g zero states, random states, GHZ states and etc.\n\nregister(::Type{RT}, raw, nbatch)\n\nan general initializer for input raw state array.\n\nregister(::Val{InitMethod}, ::Type{RT}, ::Type{T}, n, nbatch)\n\ninit register type RT with InitMethod type (e.g Val{:zero}) with element type T and total number qubits n with nbatch. This will be auto-binded to some shortcuts like zero_state, rand_state, randn_state.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.DefaultRegister",
    "page": "Registers",
    "title": "Yao.Registers.DefaultRegister",
    "category": "type",
    "text": "DefaultRegister{B, T} <: AbstractRegister{B, T}\n\nDefault type for a quantum register. It contains a dense array that represents a batched quantum state with batch size B of type T.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.Focus",
    "page": "Registers",
    "title": "Yao.Registers.Focus",
    "category": "type",
    "text": "Focus{N} <: AbatractBlock\n\nFocus manager, with N the number of qubits.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.@bit_str-Tuple{Any}",
    "page": "Registers",
    "title": "Yao.Registers.@bit_str",
    "category": "macro",
    "text": "@bit_str -> QuBitStr\n\nConstruct a bit string. such as bit\"0000\". The bit strings also supports string concat. Just use it like normal strings.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Intrinsics.hypercubic",
    "page": "Registers",
    "title": "Yao.Intrinsics.hypercubic",
    "category": "function",
    "text": "hypercubic(r::AbstractRegister) -> AbstractArray\n\nReturn the hypercubic form (high dimensional tensor) of this register, only active qubits are considered.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.extend!-Union{Tuple{B}, Tuple{T}, Tuple{Yao.Registers.DefaultRegister{B,T},Int64}} where T where B",
    "page": "Registers",
    "title": "Yao.Registers.extend!",
    "category": "method",
    "text": "extend!(r::DefaultRegister, n::Int) -> DefaultRegister\nextend!(n::Int) -> Function\n\nextend the register by n bits in state |0>. i.e. |psi> -> |000> ⊗ |psi>, extended bits have higher indices. If only an integer is provided, then perform lazy evaluation.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.focus!",
    "page": "Registers",
    "title": "Yao.Registers.focus!",
    "category": "function",
    "text": "focus!(reg::DefaultRegister, bits::Ints) -> DefaultRegister\nfocus!(locs::Int...) -> Function\n\nFocus register on specified active bits.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.focuspair!-Tuple{Vararg{Int64,N} where N}",
    "page": "Registers",
    "title": "Yao.Registers.focuspair!",
    "category": "method",
    "text": "focuspair(locs::Int...) -> NTuple{2, Function}\n\nReturn focus! and relax! function for specific lines.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.isnormalized-Tuple{Yao.Registers.DefaultRegister}",
    "page": "Registers",
    "title": "Yao.Registers.isnormalized",
    "category": "method",
    "text": "isnormalized(reg::DefaultRegister) -> Bool\n\nReturn true if a register is normalized else false.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.measure",
    "page": "Registers",
    "title": "Yao.Registers.measure",
    "category": "function",
    "text": "measure(register, [n=1]) -> Vector\n\nmeasure active qubits for n times.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.measure_remove!-Union{Tuple{B}, Tuple{Yao.Registers.AbstractRegister{B,T} where T}} where B",
    "page": "Registers",
    "title": "Yao.Registers.measure_remove!",
    "category": "method",
    "text": "measure_remove!(register)\n\nmeasure the active qubits of this register and remove them.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.register",
    "page": "Registers",
    "title": "Yao.Registers.register",
    "category": "function",
    "text": "register([type], bit_str, [nbatch=1]) -> DefaultRegister\n\nReturns a DefaultRegister by inputing a bit string, e.g\n\nusing Yao\nregister(bit\"0000\")\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.register-Tuple{Array{T,1} where T}",
    "page": "Registers",
    "title": "Yao.Registers.register",
    "category": "method",
    "text": "register(raw) -> DefaultRegister\n\nReturns a DefaultRegister from a raw dense array (Vector or Matrix).\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.relax!",
    "page": "Registers",
    "title": "Yao.Registers.relax!",
    "category": "function",
    "text": "relax!(reg::DefaultRegister; nbit::Int=nqubits(reg)) -> DefaultRegister\nrelax!(reg::DefaultRegister, bits::Ints; nbit::Int=nqubits(reg)) -> DefaultRegister\nrelax!(bits::Ints...; nbit::Int=-1) -> Function\n\nInverse transformation of focus, with nbit is the number of active bits of target register.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.stack-Tuple{Vararg{Yao.Registers.DefaultRegister,N} where N}",
    "page": "Registers",
    "title": "Yao.Registers.stack",
    "category": "method",
    "text": "stack(regs::DefaultRegister...) -> DefaultRegister\n\nstack multiple registers into a batch.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.statevec",
    "page": "Registers",
    "title": "Yao.Registers.statevec",
    "category": "function",
    "text": "statevec(r::AbstractRegister) -> AbstractArray\n\nReturn the raveled state (vector) form of this register.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.QuBitStr",
    "page": "Registers",
    "title": "Yao.Registers.QuBitStr",
    "category": "type",
    "text": "QuBitStr\n\nString literal for qubits.\n\n\n\n"
},

{
    "location": "man/registers/#Base.LinAlg.normalize!-Tuple{Yao.Registers.AbstractRegister}",
    "page": "Registers",
    "title": "Base.LinAlg.normalize!",
    "category": "method",
    "text": "normalize!(r::AbstractRegister) -> AbstractRegister\n\nReturn the register with normalized state.\n\n\n\n"
},

{
    "location": "man/registers/#Base.kron-Union{Tuple{B}, Tuple{RT,Yao.Registers.AbstractRegister{B,T} where T}, Tuple{RT}} where RT<:(Yao.Registers.AbstractRegister{B,T} where T) where B",
    "page": "Registers",
    "title": "Base.kron",
    "category": "method",
    "text": "kron(lhs, rhs)\n\nMerge two registers together with kronecker tensor product.\n\n\n\n"
},

{
    "location": "man/registers/#Yao.Registers.shapeorder-Tuple{Tuple{Vararg{T,N}} where T where N,Array{Int64,1}}",
    "page": "Registers",
    "title": "Yao.Registers.shapeorder",
    "category": "method",
    "text": "Get the compact shape and order for permutedims.\n\n\n\n"
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
    "text": "AbstractBlock\n\nabstract type that all block will subtype from. N is the number of qubits.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.AbstractMeasure",
    "page": "Blocks System",
    "title": "Yao.Blocks.AbstractMeasure",
    "category": "type",
    "text": "AbstractMeasure <: AbstractBlock\n\nAbstract block supertype which measurement block will inherit from.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.CacheFragment",
    "page": "Blocks System",
    "title": "Yao.Blocks.CacheFragment",
    "category": "type",
    "text": "CacheFragment{BT, K, MT}\n\nA fragment that will be stored for each cached block (of type BT) on a cache server.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.CachedBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.CachedBlock",
    "category": "type",
    "text": "CachedBlock{ST, BT, N, T} <: MatrixBlock{N, T}\n\nA label type that tags an instance of type BT. It forwards every methods of the block it contains, except mat and apply!, it will cache the matrix form whenever the program has.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ChainBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.ChainBlock",
    "category": "type",
    "text": "ChainBlock{N, T} <: CompositeBlock{N, T}\n\nChainBlock is a basic construct tool to create user defined blocks horizontically. It is a Vector like composite type.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.CompositeBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.CompositeBlock",
    "category": "type",
    "text": "CompositeBlock{N, T} <: MatrixBlock{N, T}\n\nabstract supertype which composite blocks will inherit from.\n\nextended APIs\n\nblocks: get an iteratable of all blocks contained by this CompositeBlock\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Concentrator",
    "page": "Blocks System",
    "title": "Yao.Blocks.Concentrator",
    "category": "type",
    "text": "Concentrator{N} <: AbstractBlock\n\nconcentrates serveral lines together in the circuit, and expose it to other blocks.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ConstantGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.ConstantGate",
    "category": "type",
    "text": "ConstantGate{N, T} <: PrimitiveBlock{N, T}\n\nAbstract type for constant gates.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ControlBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.ControlBlock",
    "category": "type",
    "text": "ControlBlock{BT, N, C, B, T} <: CompositeBlock{N, T}\n\nN: number of qubits, BT: controlled block type, C: number of control bits, T: type of matrix.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Daggered",
    "page": "Blocks System",
    "title": "Yao.Blocks.Daggered",
    "category": "type",
    "text": "Daggered{N, T, BT} <: MatrixBlock{N, T}\n\nDaggered(blk::BT)\nDaggered{N, T, BT}(blk)\n\nDaggered Block.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.FunctionBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.FunctionBlock",
    "category": "type",
    "text": "FunctionBlock <: AbstractBlock\n\nThis block contains a general function that perform an in-place operation over a register\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.KronBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.KronBlock",
    "category": "type",
    "text": "KronBlock{N, T} <: CompositeBlock\n\ncomposite block that combine blocks by kronecker product.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.MatrixBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.MatrixBlock",
    "category": "type",
    "text": "MatrixBlock{N, T} <: AbstractBlock\n\nabstract type that all block with a matrix form will subtype from.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.PhaseGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.PhaseGate",
    "category": "type",
    "text": "PhiGate\n\nGlobal phase gate.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.PrimitiveBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.PrimitiveBlock",
    "category": "type",
    "text": "PrimitiveBlock{N, T} <: MatrixBlock{N, T}\n\nabstract type that all primitive block will subtype from. A primitive block is a concrete block who can not be decomposed into other blocks. All composite block can be decomposed into several primitive blocks.\n\nNOTE: subtype for primitive block with parameter should implement hash and == method to enable key value cache.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.PutBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.PutBlock",
    "category": "type",
    "text": "PutBlock{N, C, GT, T} <: CompositeBlock{N, T}\n\nput a block on given addrs.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ReflectBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.ReflectBlock",
    "category": "type",
    "text": "ReflectBlock{N, T} <: PrimitiveBlock{N, T}\n\nHouseholder reflection with respect to some target state, psi angle = 2s anglelangle s-1.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.RepeatedBlock",
    "page": "Blocks System",
    "title": "Yao.Blocks.RepeatedBlock",
    "category": "type",
    "text": "RepeatedBlock{N, C, GT, T} <: CompositeBlock{N, T}\n\nrepeat the same block on given addrs.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Roller",
    "page": "Blocks System",
    "title": "Yao.Blocks.Roller",
    "category": "type",
    "text": "Roller{N, T, BT} <: CompositeBlock{N, T}\n\nmap a block type to all lines and use a rolling method to evaluate them.\n\nTODO\n\nfill identity like KronBlock -> To interface.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.RotationGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.RotationGate",
    "category": "type",
    "text": "RotationGate{N, T, GT <: MatrixBlock{N, Complex{T}}} <: MatrixBlock{N, Complex{T}}\n\nRotationGate, with GT both hermitian and isreflexive.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.Sequential",
    "page": "Blocks System",
    "title": "Yao.Blocks.Sequential",
    "category": "type",
    "text": "Sequential <: AbstractBlock\n\nsequencial structure that looser than a chain, it does not require qubit consistency and does not have mat method.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ShiftGate",
    "page": "Blocks System",
    "title": "Yao.Blocks.ShiftGate",
    "category": "type",
    "text": "ShiftGate <: PrimitiveBlock\n\nPhase shift gate.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.apply!",
    "page": "Blocks System",
    "title": "Yao.Blocks.apply!",
    "category": "function",
    "text": "apply!(reg, block, [signal])\n\napply a block to a register reg with or without a cache signal.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.applymatrix-Tuple{Yao.Blocks.AbstractBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.applymatrix",
    "category": "method",
    "text": "applymatrix(g::AbstractBlock) -> Matrix\n\nTransform the apply! function of specific block to dense matrix.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.blockfilter-Tuple{Any,Yao.Blocks.AbstractBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.blockfilter",
    "category": "method",
    "text": "blockfilter(func, blk::AbstractBlock) -> Vector{AbstractBlock}\nblockfilter!(func, rgs::Vector, blk::AbstractBlock) -> Vector{AbstractBlock}\n\ntree wise filtering for blocks.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.blocks",
    "page": "Blocks System",
    "title": "Yao.Blocks.blocks",
    "category": "function",
    "text": "blocks(composite_block)\n\nget an iterator that iterate through all sub-blocks.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.datatype-Union{Tuple{N}, Tuple{T}, Tuple{Yao.Blocks.MatrixBlock{N,T}}} where T where N",
    "page": "Blocks System",
    "title": "Yao.Blocks.datatype",
    "category": "method",
    "text": "datatype(x) -> DataType\n\nReturns the data type of x.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.dispatch!",
    "page": "Blocks System",
    "title": "Yao.Blocks.dispatch!",
    "category": "function",
    "text": "dispatch!(block, params)\ndispatch!(block, params...)\n\ndispatch parameters to this block.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.dispatch!-Tuple{Yao.Blocks.CompositeBlock,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.dispatch!",
    "category": "method",
    "text": "dispatch!(f, c, params) -> c\n\ndispatch parameters and tweak it according to callback function f(original, parameter)->new\n\ndispatch a vector of parameters to this composite block according to each sub-block\'s number of parameters.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.expect-Tuple{Yao.Blocks.AbstractBlock,Yao.Registers.AbstractRegister}",
    "page": "Blocks System",
    "title": "Yao.Blocks.expect",
    "category": "method",
    "text": "expect(op::AbstractBlock, reg::AbstractRegister{1}) -> Float\nexpect(op::AbstractBlock, reg::AbstractRegister{B}) -> Matrix\n\nexpectation value of an operator.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.mat",
    "page": "Blocks System",
    "title": "Yao.Blocks.mat",
    "category": "function",
    "text": "mat(block) -> Matrix\n\nReturns the matrix form of this block.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.nparameters",
    "page": "Blocks System",
    "title": "Yao.Blocks.nparameters",
    "category": "function",
    "text": "nparameters(x) -> Integer\n\nReturns the number of parameters of x.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.parameters",
    "page": "Blocks System",
    "title": "Yao.Blocks.parameters",
    "category": "function",
    "text": "parameters(block) -> Vector\n\nReturns a list of all parameters in block.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.usedbits-Union{Tuple{N}, Tuple{Yao.Blocks.MatrixBlock{N,T} where T}} where N",
    "page": "Blocks System",
    "title": "Yao.Blocks.usedbits",
    "category": "method",
    "text": "addrs(block::AbstractBlock) -> Vector{Int}\n\nOccupied addresses (include control bits and bits occupied by blocks), fall back to all bits if this method is not provided.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Intrinsics.isreflexive",
    "page": "Blocks System",
    "title": "Yao.Intrinsics.isreflexive",
    "category": "function",
    "text": "isreflexive(x) -> Bool\n\nTest whether this operator is reflexive.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Intrinsics.isunitary",
    "page": "Blocks System",
    "title": "Yao.Intrinsics.isunitary",
    "category": "function",
    "text": "isunitary(x) -> Bool\n\nTest whether this operator is unitary.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks._allmatblock-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks._allmatblock",
    "category": "method",
    "text": "all blocks are matrix blocks\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks._blockpromote-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks._blockpromote",
    "category": "method",
    "text": "promote types of blocks\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.cache_key",
    "page": "Blocks System",
    "title": "Yao.Blocks.cache_key",
    "category": "function",
    "text": "cache_key(block)\n\nReturns the key that identify the matrix cache of this block. By default, we use the returns of parameters as its key.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.cache_type-Tuple{Type{#s18} where #s18<:Yao.Blocks.MatrixBlock}",
    "page": "Blocks System",
    "title": "Yao.Blocks.cache_type",
    "category": "method",
    "text": "cache_type(::Type) -> DataType\n\nA type trait that defines the element type that a CacheFragment will use.\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.print_block-Tuple{IO,Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.print_block",
    "category": "method",
    "text": "print_block(io, block)\n\ndefine the style to print this block\n\n\n\n"
},

{
    "location": "man/blocks/#Yao.Blocks.ConstGateTools.@const_gate-Tuple{Any}",
    "page": "Blocks System",
    "title": "Yao.Blocks.ConstGateTools.@const_gate",
    "category": "macro",
    "text": "@const_gate NAME = MAT_EXPR\n@const_gate NAME::Type = MAT_EXPR\n@const_Gate NAME::Type\n\nThis macro simplify the definition of a constant gate. It will automatically bind the matrix form to a constant which will reduce memory allocation in the runtime.\n\n@const_gate X = ComplexF64[0 1;1 0]\n\nor\n\n@const_gate X::ComplexF64 = [0 1;1 0]\n\nYou can bind new element types by simply re-declare with a type annotation.\n\n@const_gate X::ComplexF32\n\n\n\n"
},

{
    "location": "man/blocks/#Blocks-1",
    "page": "Blocks System",
    "title": "Blocks",
    "category": "section",
    "text": "Modules = [Yao.Blocks, Yao.Blocks.ConstGateTools]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/cache/#",
    "page": "Cache System",
    "title": "Cache System",
    "category": "page",
    "text": ""
},

{
    "location": "man/cache/#Yao.CacheServers.AbstractCacheServer",
    "page": "Cache System",
    "title": "Yao.CacheServers.AbstractCacheServer",
    "category": "type",
    "text": "AbstractCacheServer{K, ELT}\n\n\n\n"
},

{
    "location": "man/cache/#Yao.CacheServers.alloc!-Tuple{Yao.CacheServers.AbstractCacheServer,Any,Any}",
    "page": "Cache System",
    "title": "Yao.CacheServers.alloc!",
    "category": "method",
    "text": "alloc!(server, object, storage) -> server\n\nalloc new storage on the server.\n\n\n\n"
},

{
    "location": "man/cache/#Yao.CacheServers.iscacheable-Tuple{Yao.CacheServers.AbstractCacheServer,Any}",
    "page": "Cache System",
    "title": "Yao.CacheServers.iscacheable",
    "category": "method",
    "text": "iscacheable(server, object)\n\ncheck if there is available space to storage this object\'s value. (if this object was allocated on the server before.).\n\n\n\n"
},

{
    "location": "man/cache/#Yao.CacheServers.iscached-Tuple{Yao.CacheServers.AbstractCacheServer,Any,Vararg{Any,N} where N}",
    "page": "Cache System",
    "title": "Yao.CacheServers.iscached",
    "category": "method",
    "text": "iscached(server, object, [params...])\n\ncheck if this object (with params) is already cached.\n\n\n\n"
},

{
    "location": "man/cache/#Yao.CacheServers.pull-Tuple{Yao.CacheServers.AbstractCacheServer,Any,Vararg{Any,N} where N}",
    "page": "Cache System",
    "title": "Yao.CacheServers.pull",
    "category": "method",
    "text": "pull(server, object, params...) -> value\n\npull object storage from server.\n\n\n\n"
},

{
    "location": "man/cache/#Yao.CacheServers.update!-Tuple{Any,Any}",
    "page": "Cache System",
    "title": "Yao.CacheServers.update!",
    "category": "method",
    "text": "update!(storage, val) -> storage\n\n\n\n"
},

{
    "location": "man/cache/#Base.Distributed.clear!-Tuple{Yao.CacheServers.AbstractCacheServer,Any}",
    "page": "Cache System",
    "title": "Base.Distributed.clear!",
    "category": "method",
    "text": "clear!(server, object) -> server\n\nclear the storage in the server of this object.\n\n\n\n"
},

{
    "location": "man/cache/#Base.delete!-Tuple{Yao.CacheServers.AbstractCacheServer,Any}",
    "page": "Cache System",
    "title": "Base.delete!",
    "category": "method",
    "text": "delete!(server, object) -> server\n\ndelete this object from the server. (the storage will be deleted)\n\n\n\n"
},

{
    "location": "man/cache/#Base.push!-Tuple{Yao.CacheServers.AbstractCacheServer,Any,Any}",
    "page": "Cache System",
    "title": "Base.push!",
    "category": "method",
    "text": "push!(server, val, object) -> server\n\npush val to the storage of object in the server.\n\n\n\n"
},

{
    "location": "man/cache/#Cache-System-1",
    "page": "Cache System",
    "title": "Cache System",
    "category": "section",
    "text": "Modules = [Yao.CacheServers]\nOrder   = [:module, :constant, :type, :macro, :function]"
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
    "text": "AddressConflictError <: Exception\n\nAddress conflict error in Block Construction.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.IterControl",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.IterControl",
    "category": "type",
    "text": "IterControl{N, C}\n\nN is the size of hilber space, C is the number of shifts.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.QubitMismatchError",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.QubitMismatchError",
    "category": "type",
    "text": "QubitMismatchError <: Exception\n\nQubit number mismatch error when applying a Block to a Register or concatenating Blocks.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Base.LinAlg.ishermitian-Tuple{Any}",
    "page": "Intrinsics",
    "title": "Base.LinAlg.ishermitian",
    "category": "method",
    "text": "ishermitian(op) -> Bool\n\ncheck if this operator is hermitian.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.basis-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.basis",
    "category": "method",
    "text": "basis(num_bit::Int) -> UnitRange{Int}\nbasis(state::AbstractArray) -> UnitRange{Int}\n\nReturns the UnitRange for basis in Hilbert Space of num_bit qubits. If an array is supplied, it will return a basis having the same size with the first diemension of array.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.batch_normalize",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.batch_normalize",
    "category": "function",
    "text": "batch_normalize\n\nnormalize a batch of vector.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.batch_normalize!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.batch_normalize!",
    "category": "function",
    "text": "batch_normalize!(matrix)\n\nnormalize a batch of vector.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bdistance-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bdistance",
    "category": "method",
    "text": "bdistance(i::DInt, j::DInt) -> Int\n\nReturn number of different bits.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bit_length-Tuple{Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bit_length",
    "category": "method",
    "text": "bit_length(x::Int) -> Int\n\nReturn the number of bits required to represent input integer x.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bitarray-Union{Tuple{Array{T,1},Int64}, Tuple{T}} where T<:Number",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bitarray",
    "category": "method",
    "text": "bitarray(v::Vector, [num_bit::Int]) -> BitArray\nbitarray(v::Int, num_bit::Int) -> BitArray\nbitarray(num_bit::Int) -> Function\n\nConstruct BitArray from an integer vector, if num_bit not supplied, it is 64. If an integer is supplied, it returns a function mapping a Vector/Int to bitarray.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bmask",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bmask",
    "category": "function",
    "text": "bmask(ibit::Int...) -> Int\nbmask(bits::UnitRange{Int}) ->Int\n\nReturn an integer with specific position masked, which is offten used as a mask for binary operations.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.bsizeof-Tuple{Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.bsizeof",
    "category": "method",
    "text": "bsizeof(x) -> Int\n\nReturn the size of object, in number of bit.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.controller-Tuple{Any,Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.controller",
    "category": "method",
    "text": "controller(cbits, cvals) -> Function\n\nReturn a function that test whether a basis at cbits takes specific value cvals.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.cunapply!",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.cunapply!",
    "category": "function",
    "text": "control-unitary \n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.flip-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.flip",
    "category": "method",
    "text": "flip(index::Int, mask::Int) -> Int\n\nReturn an Integer with bits at masked position flipped.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.general_controlled_gates-Tuple{Int64,Array{#s17,1} where #s17<:(AbstractArray{T,2} where T),Array{Int64,1},Array{#s14,1} where #s14<:(AbstractArray{T,2} where T),Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.general_controlled_gates",
    "category": "method",
    "text": "general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix\n\nReturn general multi-controlled gates in hilbert space of num_bit qubits,\n\nprojectors are often chosen as P0 and P1 for inverse-Control and Control at specific position.\ncbits should have the same length as projectors, specifing the controling positions.\ngates are a list of controlled single qubit gates.\nlocs should have the same length as gates, specifing the gates positions.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.hilbertkron-Union{Tuple{Int64,Array{T,1},Array{Int64,1}}, Tuple{T}} where T<:(AbstractArray{T,2} where T)",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.hilbertkron",
    "category": "method",
    "text": "hilbertkron(num_bit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix\n\nReturn general kronecher product form of gates in Hilbert space of num_bit qubits.\n\ngates are a list of matrices.\nstart_locs should have the same length as gates, specifing the gates starting positions.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.indices_with-Tuple{Int64,Array{Int64,1},Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.indices_with",
    "category": "method",
    "text": "indices_with(num_bit::Int, poss::Vector{Int}, vals::Vector{Int}) -> Vector{Int}\n\nReturn indices with specific positions poss with value vals in a hilbert space of num_bit qubits.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.isreflexive-Tuple{Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.isreflexive",
    "category": "method",
    "text": "isreflexive(op) -> Bool\n\ncheck if this operator is reflexive.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.isunitary-Tuple{Any}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.isunitary",
    "category": "method",
    "text": "isunitary(op) -> Bool\n\ncheck if this operator is a unitary operator.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.itercontrol-Tuple{Int64,Array{Int64,1},Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.itercontrol",
    "category": "method",
    "text": "itercontrol(num_bit::Int, poss::Vector{Int}, vals::Vector{Int}) -> IterControl\n\nReturn the iterator for basis with poss controlled to values vals, with the total number of bits num_bit.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.log2i",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.log2i",
    "category": "function",
    "text": "log2i(x::Integer) -> Integer\n\nReturn log2(x), this integer version of log2 is fast but only valid for number equal to 2^n. Ref: https://stackoverflow.com/questions/21442088\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.neg-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.neg",
    "category": "method",
    "text": "neg(index::Int, num_bit::Int) -> Int\n\nReturn an integer with all bits flipped (with total number of bit num_bit).\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.onehotvec-Union{Tuple{Type{T},Int64,Int64}, Tuple{T}} where T",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.onehotvec",
    "category": "method",
    "text": "onehotvec(::Type{T}, num_bit::Int, x::DInt) -> Vector{T}\n\none-hot wave vector.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.packbits-Tuple{AbstractArray}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.packbits",
    "category": "method",
    "text": "packbits(arr::AbstractArray) -> AbstractArray\n\npack bits to integers, usually take a BitArray as input.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.reordered_basis-Tuple{Int64,Array{Int64,1}}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.reordered_basis",
    "category": "method",
    "text": "Reordered Basis\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.setbit-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.setbit",
    "category": "method",
    "text": "setbit(index::Int, mask::Int) -> Int\n\nset the bit at masked position to 1.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.swapbits-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.swapbits",
    "category": "method",
    "text": "swapbits(num::Int, mask12::Int) -> Int\n\nReturn an integer with bits at i and j flipped.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.takebit-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.takebit",
    "category": "method",
    "text": "takebit(index::Int, ibit::Int) -> Int\n\nReturn a bit at specific position.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.testall-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.testall",
    "category": "method",
    "text": "testall(index::Int, mask::Int) -> Bool\n\nReturn true if all masked position of index is 1.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.testany-Tuple{Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.testany",
    "category": "method",
    "text": "testany(index::Int, mask::Int) -> Bool\n\nReturn true if any masked position of index is 1.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.testval-Tuple{Int64,Int64,Int64}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.testval",
    "category": "method",
    "text": "testval(index::Int, mask::Int, onemask::Int) -> Bool\n\nReturn true if values at positions masked by mask with value 1 at positions masked by onemask and 0 otherwise.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Base.sort-Tuple{Tuple}",
    "page": "Intrinsics",
    "title": "Base.sort",
    "category": "method",
    "text": "sort(t::Tuple; lt=isless, by=identity, rev::Bool=false) -> ::Tuple\n\nSorts the tuple t.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Base.sortperm-Tuple{Tuple}",
    "page": "Intrinsics",
    "title": "Base.sortperm",
    "category": "method",
    "text": "sortperm(t::Tuple; lt=isless, by=identity, rev::Bool=false) -> ::Tuple\n\nComputes a tuple that contains the permutation required to sort t.\n\n\n\n"
},

{
    "location": "man/intrinsics/#Yao.Intrinsics.autostatic-Tuple{Union{AbstractArray{T,1}, AbstractArray{T,2}} where T}",
    "page": "Intrinsics",
    "title": "Yao.Intrinsics.autostatic",
    "category": "method",
    "text": "turn a vector/matrix to static vector/matrix (only if its length <= 256).\n\n\n\n"
},

{
    "location": "man/intrinsics/#Intrinsics-1",
    "page": "Intrinsics",
    "title": "Intrinsics",
    "category": "section",
    "text": "Modules = [Yao.Intrinsics]\nOrder   = [:module, :constant, :type, :macro, :function]"
},

{
    "location": "man/luxurysparse/#",
    "page": "LuxurySparse",
    "title": "LuxurySparse",
    "category": "page",
    "text": ""
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.IMatrix",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.IMatrix",
    "category": "type",
    "text": "IMatrix{N, Tv}()\nIMatrix{N}() where N = IMatrix{N, Int64}()\nIMatrix(A::AbstractMatrix{T}) where T -> IMatrix\n\nIMatrix matrix, with size N as label, use Int64 as its default type, both * and kron are optimized.\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.PermMatrix",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.PermMatrix",
    "category": "type",
    "text": "PermMatrix{Tv, Ti}(perm::Vector{Ti}, vals::Vector{Tv}) where {Tv, Ti<:Integer}\nPermMatrix(perm::Vector{Ti}, vals::Vector{Tv}) where {Tv, Ti}\nPermMatrix(ds::AbstractMatrix)\n\nPermMatrix represents a special kind linear operator: Permute and Multiply, which means M * v = v[perm] * val Optimizations are used to make it much faster than SparseMatrixCSC.\n\nperm is the permutation order,\nvals is the multiplication factor.\n\nGeneralized Permutation Matrix\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.fast_invperm-Tuple{Any}",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.fast_invperm",
    "category": "method",
    "text": "faster invperm\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.notdense",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.notdense",
    "category": "function",
    "text": "notdense(M) -> Bool\n\nReturn true if a matrix is not dense.\n\nNote: It is not exactly same as isparse, e.g. Diagonal, IMatrix and PermMatrix are both notdense but not isparse.\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.pmrand",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.pmrand",
    "category": "function",
    "text": "pmrand(T::Type, n::Int) -> PermMatrix\n\nReturn random PermMatrix.\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.statify",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.statify",
    "category": "function",
    "text": "statify(A::AbstractMatrix) -> AbastractMatrix\n\ntransform a matrix to a static form.\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.matvec",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.matvec",
    "category": "function",
    "text": "matvec(x::VecOrMat) -> MatOrVec\n\nReturn vector if a matrix is a column vector, else untouched.\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.mulcol!",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.mulcol!",
    "category": "function",
    "text": "mulcol!(v::Vector, i::Int, f) -> VecOrMat\n\nmultiply col i of v by f inplace.\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.mulrow!",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.mulrow!",
    "category": "function",
    "text": "mulrow!(v::Vector, i::Int, f) -> VecOrMat\n\nmultiply row i of v by f inplace.\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.swapcols!",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.swapcols!",
    "category": "function",
    "text": "swapcols!(v::VecOrMat, i::Int, j::Int[, f1, f2]) -> VecOrMat\n\nswap col i and col j of v inplace, with f1, f2 factors applied on i and j (before swap).\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.swaprows!",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.swaprows!",
    "category": "function",
    "text": "swaprows!(v::VecOrMat, i::Int, j::Int[, f1, f2]) -> VecOrMat\n\nswap row i and row j of v inplace, with f1, f2 factors applied on i and j (before swap).\n\n\n\n"
},

{
    "location": "man/luxurysparse/#Yao.LuxurySparse.u1rows!",
    "page": "LuxurySparse",
    "title": "Yao.LuxurySparse.u1rows!",
    "category": "function",
    "text": "u1rows!(state::VecOrMat, i::Int, j::Int, a, b, c, d) -> VecOrMat\n\napply u1 on row i and row j of state inplace.\n\n\n\n"
},

{
    "location": "man/luxurysparse/#LuxurySparse-1",
    "page": "LuxurySparse",
    "title": "LuxurySparse",
    "category": "section",
    "text": "We provide more detailed optimization through a self-defined sparse library which is more efficient for operations related to quantum gates.Modules = [Yao.LuxurySparse]\nOrder   = [:module, :constant, :type, :macro, :function]"
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
    "text": "controlled_U1(num_bit::Int, gate::AbstractMatrix, cbits::Vector{Int}, b2::Int) -> AbstractMatrix\n\nReturn general multi-controlled single qubit gate in hilbert space of num_bit qubits.\n\ncbits specify the controling positions.\nb2 is the controlled position.\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.cxgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Any,Any,Union{Array{Int64,1}, Int64, UnitRange{Int64}}}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.cxgate",
    "category": "method",
    "text": "cxgate(::Type{MT}, num_bit::Int, b1::Ints, b2::Ints) -> PermMatrix\n\nSingle (Multiple) Controlled-X Gate on single (multiple) bits.\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.cygate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Any,Any,Int64}} where MT<:Complex",
    "page": "Boost",
    "title": "Yao.Boost.cygate",
    "category": "method",
    "text": "cygate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) -> PermMatrix\n\nSingle Controlled-Y Gate on single bit.\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.czgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Any,Any,Int64}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.czgate",
    "category": "method",
    "text": "czgate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) -> Diagonal\n\nSingle Controlled-Z Gate on single bit.\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.xgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Union{Array{Int64,1}, Int64, UnitRange{Int64}}}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.xgate",
    "category": "method",
    "text": "xgate(::Type{MT}, num_bit::Int, bits::Ints) -> PermMatrix\n\nX Gate on multiple bits.\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.ygate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Union{Array{Int64,1}, Int64, UnitRange{Int64}}}} where MT<:Complex",
    "page": "Boost",
    "title": "Yao.Boost.ygate",
    "category": "method",
    "text": "ygate(::Type{MT}, num_bit::Int, bits::Ints) -> PermMatrix\n\nY Gate on multiple bits.\n\n\n\n"
},

{
    "location": "man/boost/#Yao.Boost.zgate-Union{Tuple{MT}, Tuple{Type{MT},Int64,Union{Array{Int64,1}, Int64, UnitRange{Int64}}}} where MT<:Number",
    "page": "Boost",
    "title": "Yao.Boost.zgate",
    "category": "method",
    "text": "zgate(::Type{MT}, num_bit::Int, bits::Ints) -> Diagonal\n\nZ Gate on multiple bits.\n\n\n\n"
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
    "text": "First, define your own block type by subtyping PrimitiveBlock. And import methods you will need to overloadusing Yao, Yao.Blocks\nimport Yao.Blocks: mat, dispatch!, parameters # this is the mimimal methods you will need to overload\n\nmutable struct NewPrimitive{T} <: PrimitiveBlock{1, T}\n   theta::T\nendSecond define its matrix form.mat(g::NewPrimitive{T}) where T = Complex{T}[sin(g.theta) 0; cos(g.theta) 0]Yao will use this matrix to do the simulation by default. However, if you know how to directly apply your block to a quantum register, you can also overload apply! to make your simulation become more efficient. But this is not required.import Yao.Blocks: apply!\napply!(r::AbstractRegister, x::NewPrimitive) = # some efficient way to simulate this blockThird If your block contains parameters, declare which member it is with dispatch! and how to get them by parametersdispatch!(g::NewPrimitive, theta) = (g.theta = theta; g)\nparameters(x::NewPrimitive) = x.thetaThe prototype of dispatch! is simple, just directly write the parameters as your function argument. e.gmutable struct MultiParam{N, T} <: PrimitiveBlock{N, Complex{T}}\n  theta::T\n  phi::T\nendjust write:dispatch!(x::MultiParam, theta, phi) = (x.theta = theta; x.phi = phi; x)or maybe your block contains a vector of parameters:mutable struct VecParam{N, T} <: PrimitiveBlock{N, T}\n  params::Vector{T}\nendjust write:dispatch!(x::VecParam, params) = (x.params .= params; x)be careful, the assignment should be in-placed with .= rather than =.If the number of parameters in your new block is fixed, we recommend you to declare this with a type trait nparameters:import Yao.Blocks: nparameters\nnparameters(::Type{<:NewPrimitive}) = 1But it is OK if you do not define this trait, Yao will find out how many parameters you have dynamically.Fourth If you want to enable cache of this new block, you have to define your own cache_key. usually just use your parameters as the key if you want to cache the matrix form of different parameters, which will accelerate your simulation with a cost of larger memory allocation. You can simply define it with cache_keyimport Yao.Blocks: cache_key\ncache_key(x::NewPrimitive) = x.theta"
},

{
    "location": "dev/extending-blocks/#Extending-Composite-Blocks-1",
    "page": "Extending Blocks",
    "title": "Extending Composite Blocks",
    "category": "section",
    "text": "Composite blocks are blocks that are able to contain other blocks. To define a new composite block you only need to define your new type as a subtype of CompositeBlock, and define a new method called blocks which will provide an iterator that iterates the blocks contained by this composite block."
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
    "text": "ProjectQ is an open source software framework for quantum computing. Here we present the single process benchmark result(Image: xyz) (Image: repeatedxyz) (Image: cxyz) (Image: crot) (Image: hgate) (Image: rot)Here, we see the reason why we need Block system and multiple dispatch to do structure specific optimization."
},

{
    "location": "dev/benchmark/#ProjectQ-Refs-1",
    "page": "Benchmark with ProjectQ",
    "title": "ProjectQ Refs",
    "category": "section",
    "text": "Github Repo\nDamian S. Steiger, Thomas Häner, and Matthias Troyer \"ProjectQ: An Open Source Software Framework for Quantum Computing\" [arxiv:1612.08091]\nThomas Häner, Damian S. Steiger, Krysta M. Svore, and Matthias Troyer \"A Software Methodology for Compiling Quantum Programs\" [arxiv:1604.01401]"
},

{
    "location": "dev/benchmark/#CPU-Information-1",
    "page": "Benchmark with ProjectQ",
    "title": "CPU Information",
    "category": "section",
    "text": "Architecture:          x86_64\nCPU op-mode(s):        32-bit, 64-bit\nByte Order:            Little Endian\nCPU(s):                48\nOn-line CPU(s) list:   0-47\nThread(s) per core:    2\nCore(s) per socket:    12\nSocket(s):             2\nNUMA node(s):          2\nVendor ID:             GenuineIntel\nCPU family:            6\nModel:                 79\nStepping:              1\nCPU MHz:               2499.921\nBogoMIPS:              4401.40\nVirtualization:        VT-x\nL1d cache:             32K\nL1i cache:             32K\nL2 cache:              256K\nL3 cache:              30720K\nNUMA node0 CPU(s):     0-11,24-35\nNUMA node1 CPU(s):     12-23,36-47"
},

{
    "location": "dev/benchmark/#Julia-Version-1",
    "page": "Benchmark with ProjectQ",
    "title": "Julia Version",
    "category": "section",
    "text": "Julia Version 0.7.0-alpha.147\nCommit 5e3259e (2018-06-16 18:43 UTC)\nPlatform Info:\n  OS: Linux (x86_64-linux-gnu)\n  CPU: Intel(R) Xeon(R) CPU E5-2650 v4 @ 2.20GHz\n  WORD_SIZE: 64\n  LIBM: libopenlibm\n  LLVM: libLLVM-6.0.0 (ORCJIT, broadwell)"
},

]}
