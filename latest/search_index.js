var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#Quantum-Circuit-Simulation-for-Julia-1",
    "page": "Home",
    "title": "Quantum Circuit Simulation for Julia",
    "category": "section",
    "text": "Welcome to QuCircuit"
},

{
    "location": "#Introduction-1",
    "page": "Home",
    "title": "Introduction",
    "category": "section",
    "text": "QuCircuit.jl is a quantum circuit simulator written in Julia."
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
    "text": "First, you have to use this package in Julia.using QuCircuitThen let\'s define the oracle, it is a function of the number of qubits. The whole oracle looks like this:circuit(n) = compose(\n    X(1),\n    H(2:n),\n    X(1) |> C(2),\n    X(3) |> C(4),\n    X(1) |> C(3),\n    X(3) |> C(4),\n    H(1:n),\n)After we have an circuit, we can construct a quantum register, and input it into the oracle. You will then receive this register after processing it.reg = register(bit\"0000\")\nreg |> circuit(4)\nregLet\'s check the output:state(reg)We have a GHZ state here, try to measure the first qubitreg |> measure(1)\nstate(reg)GHZ state will collapse to 0000rangle or 1111rangle due to entanglement!"
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
    "text": ""
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
    "text": ""
},

{
    "location": "man/blocks/#",
    "page": "Blocks as the basic component of a circuit",
    "title": "Blocks as the basic component of a circuit",
    "category": "page",
    "text": ""
},

{
    "location": "man/blocks/#Blocks-as-the-basic-component-of-a-circuit-1",
    "page": "Blocks as the basic component of a circuit",
    "title": "Blocks as the basic component of a circuit",
    "category": "section",
    "text": ""
},

{
    "location": "man/cache/#",
    "page": "Cache System",
    "title": "Cache System",
    "category": "page",
    "text": ""
},

{
    "location": "man/cache/#Cache-System-1",
    "page": "Cache System",
    "title": "Cache System",
    "category": "section",
    "text": ""
},

{
    "location": "man/functional/#",
    "page": "Functional Programming",
    "title": "Functional Programming",
    "category": "page",
    "text": ""
},

{
    "location": "man/functional/#Functional-Programming-1",
    "page": "Functional Programming",
    "title": "Functional Programming",
    "category": "section",
    "text": ""
},

{
    "location": "dev/block/#",
    "page": "Block System",
    "title": "Block System",
    "category": "page",
    "text": ""
},

{
    "location": "dev/block/#Block-System-1",
    "page": "Block System",
    "title": "Block System",
    "category": "section",
    "text": "The whole framework is consist of a block system. The whole system characterize a quantum circuit into serveral kinds of blocks. The uppermost abstract type for the whole system is AbstractBlock"
},

{
    "location": "dev/block/#QuCircuit.MatrixBlock",
    "page": "Block System",
    "title": "QuCircuit.MatrixBlock",
    "category": "type",
    "text": "MatrixBlock{N, T} <: AbstractBlock\n\nabstract type that all block with a matrix form will subtype from.\n\nextended APIs\n\nsparse full datatype\n\n\n\n"
},

{
    "location": "dev/block/#PureBlock-1",
    "page": "Block System",
    "title": "PureBlock",
    "category": "section",
    "text": "QuCircuit.MatrixBlock"
},

{
    "location": "dev/block/#QuCircuit.PrimitiveBlock",
    "page": "Block System",
    "title": "QuCircuit.PrimitiveBlock",
    "category": "type",
    "text": "PrimitiveBlock{N, T} <: MatrixBlock{N, T}\n\nabstract type that all primitive block will subtype from. A primitive block is a concrete block who can not be decomposed into other blocks. All composite block can be decomposed into several primitive blocks.\n\nNOTE: subtype for primitive block with parameter should implement hash and == method to enable key value cache.\n\n\n\n"
},

{
    "location": "dev/block/#Primitive-Block-1",
    "page": "Block System",
    "title": "Primitive Block",
    "category": "section",
    "text": "QuCircuit.PrimitiveBlock"
},

{
    "location": "dev/block/#QuCircuit.CompositeBlock",
    "page": "Block System",
    "title": "QuCircuit.CompositeBlock",
    "category": "type",
    "text": "CompositeBlock{N, T} <: MatrixBlock{N, T}\n\nabstract supertype which composite blocks will inherit from.\n\nextended APIs\n\nblocks: get an iteratable of all blocks contained by this CompositeBlock\n\n\n\n"
},

{
    "location": "dev/block/#Composite-Block-1",
    "page": "Block System",
    "title": "Composite Block",
    "category": "section",
    "text": "QuCircuit.CompositeBlock"
},

{
    "location": "dev/block/#QuCircuit.AbstractMeasure",
    "page": "Block System",
    "title": "QuCircuit.AbstractMeasure",
    "category": "type",
    "text": "AbstractMeasure{M} <: AbstractBlock\n\nAbstract block supertype which measurement block will inherit from.\n\n\n\n"
},

{
    "location": "dev/block/#MeasureBlock-1",
    "page": "Block System",
    "title": "MeasureBlock",
    "category": "section",
    "text": "QuCircuit.AbstractMeasure"
},

{
    "location": "dev/block/#Concentrator-1",
    "page": "Block System",
    "title": "Concentrator",
    "category": "section",
    "text": "QuCircuit.Concentrator(Image: concentrator)"
},

{
    "location": "dev/block/#Sequence-1",
    "page": "Block System",
    "title": "Sequence",
    "category": "section",
    "text": "QuCircuit.Sequence"
},

{
    "location": "dev/block/#User-Defined-Block-1",
    "page": "Block System",
    "title": "User Defined Block",
    "category": "section",
    "text": "You can extending the block system by overloading existing APIs."
},

{
    "location": "dev/block/#Extending-Constant-Gates-1",
    "page": "Block System",
    "title": "Extending Constant Gates",
    "category": "section",
    "text": "Extending constant gate is very simple:using QuCircuit\nimport QuCircuit: Gate, GateType, sparse, nqubits\n# define the number of qubits\nnqubits(::Type{GateType{:CNOT}}) = 2\n# define its matrix form\nsparse(::Gate{2, GateType{:CNOT}, T}) where T = T[1 0 0 0;0 1 0 0;0 0 0 1;0 0 1 0]Then you get a constant CNOT gateg = gate(:CNOT)\nsparse(g)"
},

{
    "location": "dev/block/#Extending-a-Primitive-Block-1",
    "page": "Block System",
    "title": "Extending a Primitive Block",
    "category": "section",
    "text": "Primitive blocks are very useful when you want to accelerate a specific oracle. For example, we can accelerate a Grover search oracle by define a custom subtype of PrimitiveBlock.using QuCircuit\nimport QuCircuit: PrimitiveBlock, apply!, Register\n\nstruct GroverSearch{N, T} <: PrimitiveBlock{N, T}\nend\n\n# define how you want to simulate this oracle\nfunction apply!(reg::Register, oracle::GroverSearch)\n    # a fast implementation of Grover search\nend\n\n# define its matrix form\nsparse(oracle::GroverSearch{N, T}) where {N, T} = grover_search_matrix_form(T, N)"
},

{
    "location": "dev/register/#",
    "page": "Quantum Register",
    "title": "Quantum Register",
    "category": "page",
    "text": ""
},

{
    "location": "dev/register/#Quantum-Register-1",
    "page": "Quantum Register",
    "title": "Quantum Register",
    "category": "section",
    "text": "Quantum Register is the abstraction of a quantum state being processed by a quantum circuit."
},

{
    "location": "dev/register/#The-Interface-of-Register-1",
    "page": "Quantum Register",
    "title": "The Interface of Register",
    "category": "section",
    "text": "You can always define your own quantum register by subtyping this abstract type.QuCircuit.AbstractRegisterThe interface of a AbstractRegister looks like:"
},

{
    "location": "dev/register/#Properties-1",
    "page": "Quantum Register",
    "title": "Properties",
    "category": "section",
    "text": "nqubit: number of qubits\nnbatch: number of batch\nnactive: number of active qubits\naddress: current list of line address\nstate: current state\neltype: eltype\ncopy: copy\nfocus!: pack several legs together"
},

{
    "location": "dev/register/#Factory-Methods-1",
    "page": "Quantum Register",
    "title": "Factory Methods",
    "category": "section",
    "text": "QuCircuit.Registerreshaped_state: state"
},

{
    "location": "dev/cache/#",
    "page": "Cache",
    "title": "Cache",
    "category": "page",
    "text": ""
},

{
    "location": "dev/cache/#Cache-1",
    "page": "Cache",
    "title": "Cache",
    "category": "section",
    "text": ""
},

{
    "location": "dev/cache/#Key-value-Storage-1",
    "page": "Cache",
    "title": "Key-value Storage",
    "category": "section",
    "text": "Like PyTorch, MXNet, we use a key value storage (a cache pool, like dmlc/ps-lite) to store cached blocks. Cached blocks are frequently used blocks with specific matrix form. You can choose which type of matrix storage to store in a cache pool.The benefit of this solution includes:more contiguous memory address (compare to previous plans, e.g CacheBlock, block with a cache dict)\nmore convenient for traversing cached parameters\nthis solution offer us flexibility for future implementation on GPUs and large clusters."
},

{
    "location": "dev/cache/#Julia\'s-Dict-1",
    "page": "Cache",
    "title": "Julia\'s Dict",
    "category": "section",
    "text": "Base.hashindex(key, sz)sz is the total length of the list of slots.TO BE DONE..."
},

{
    "location": "dev/cache/#Implementation-1",
    "page": "Cache",
    "title": "Implementation",
    "category": "section",
    "text": "Unlike parameter servers in deep learning frameworks. Our cache server contains not only the cached (sparse) matrix, but also its related cache level, which defines its update priority during the evluation of a quantum circuit. Or it can be viewed as a parameter server that stores a CacheElement)."
},

{
    "location": "dev/cache/#Solutions-1",
    "page": "Cache",
    "title": "Solutions",
    "category": "section",
    "text": "TO BE DONE..."
},

{
    "location": "dev/visualization/#",
    "page": "Visualization",
    "title": "Visualization",
    "category": "page",
    "text": ""
},

{
    "location": "dev/visualization/#Visualization-1",
    "page": "Visualization",
    "title": "Visualization",
    "category": "section",
    "text": ""
},

{
    "location": "dev/visualization/#Demo-1",
    "page": "Visualization",
    "title": "Demo",
    "category": "section",
    "text": "This is the circuit.yaml file,name: \"Circuit\"\nnline: 10\nblocks:\n    -\n        DISP: true\n        name: \"Rotation\"\n        nline: 7\n        blocks:\n            - \"/X(0)\"\n            - \"/C(1)--/NC(2) -- /G(3:4, $\\\\sqrt{2}$, 0.3 & 0.4)\"\n            - \"/NC(9)--/Measure(6);\"\n            - \"/NC(7)--/NOT(5);\"\n            - \"/C(2)--/Swap(4 & 7);\"\n            - \"/Focus(7 & 2 & 5 & 1);\"\n            -\n                DISP: false\n                name: \"R1\"\n                nline: 4\n                blocks:\n                    - \"/Rot(0, 0.2 & 0 & 0.5)\"\n                    - \"/G(1:3, Math,);\"\n                    - \"/Include(block-FFT)\"\n\n    -\n        DISP: true\n        name: \"R1\"\n        nline: 4\n        blocks:\n            - \"/Rx(1, 0.4)\"\n            - \"/G(2:2, U2,);\"\n    - \"/Measure(0:9);\"\n    - \"/End(0:9)\"\n\nblock-FFT:\n    DISP: true\n    name: \"FFT\"\n    nline: 4\n    blocks:\n        - \"/Rx(1, 0.4)\"\n        - \"/G(2:2, U2,);\"As a result, we can get (Image: )"
},

{
    "location": "dev/visualization/#Gate-Representation-1",
    "page": "Visualization",
    "title": "Gate Representation",
    "category": "section",
    "text": "A gate or an operation start with /.Non-Parametric Single-Qubit Gates like G(line), where line is an integer\nC, NC  # Control and N-Control\nX, Y, Z, H\nNOT\nNon-Parametric Multi-Qubit Gates like G(lines), where lines can be an integer, slice or list, e.g. 2, 1&2&3, 1:4 (which is equivalent to 1&2&3).\nSwap  # number of line must be 2.\nFocus\nMeasure\nEnd\nParametric Gates like G(line(s), floats), floats here can be e.g. 0.2&0.3, 0.2.\nRx, Ry, Rz\nRot\nGeneral Gates with Names like G(line(s), text, float(s)), if no parameter, it is G(line(s), text,).\nG"
},

{
    "location": "dev/visualization/#Block-Tree-1",
    "page": "Visualization",
    "title": "Block Tree",
    "category": "section",
    "text": "blocks contains a list of blocks, and for each block, it contains\nname: str\nnline: int\nblocks: list\nDISP_OFFSETX: float\nDISP: bool, whether this box is visible.Where DISP* variables are for display purpose, which is not related to circuit definition."
},

{
    "location": "dev/visualization/#Notes-1",
    "page": "Visualization",
    "title": "Notes",
    "category": "section",
    "text": ""
},

{
    "location": "dev/visualization/#Reserved-strings-for-naming-a-general-Gate-1",
    "page": "Visualization",
    "title": "Reserved strings for naming a general Gate",
    "category": "section",
    "text": "\"–\" used to split column wise connected gates.\n\";\" in the last line, used to change column."
},

{
    "location": "dev/unittest/#",
    "page": "Unit Test",
    "title": "Unit Test",
    "category": "page",
    "text": ""
},

{
    "location": "dev/unittest/#Unit-Test-1",
    "page": "Unit Test",
    "title": "Unit Test",
    "category": "section",
    "text": "We use Julia\'s stdlib Test for unit test. This document is about how to creat new test cases. And what should be test."
},

{
    "location": "dev/unittest/#Create-new-test-case-1",
    "page": "Unit Test",
    "title": "Create new test case",
    "category": "section",
    "text": ""
},

{
    "location": "dev/unittest/#How-to-check-test-coverage-1",
    "page": "Unit Test",
    "title": "How to check test coverage",
    "category": "section",
    "text": "Step 1:  Navigate to your test directory, and start julia like this:julia --code-coverage=userStep 2: Run your tests (e.g., include(\"runtests.jl\")) and quit Julia.Step 3: Navigate to the top-level directory of your package, restart Julia (with no special flags) and analyze your code coverage:using Coverage\n# defaults to src/; alternatively, supply the folder name as argument\ncoverage = process_folder()\n# Get total coverage for all Julia files\ncovered_lines, total_lines = get_summary(coverage)\n# Or process a single file\n@show get_summary(process_file(\"src/MyPkg.jl\"))check Coverage.jl for more information."
},

{
    "location": "dev/APIs/#",
    "page": "APIs",
    "title": "APIs",
    "category": "page",
    "text": ""
},

{
    "location": "dev/APIs/#QuCircuit.AbstractBlock",
    "page": "APIs",
    "title": "QuCircuit.AbstractBlock",
    "category": "type",
    "text": "AbstractBlock\n\nabstract type that all block will subtype from. N is the number of qubits.\n\nAPIs\n\nTraits\n\nnqubit ninput noutput isunitary ispure isreflexive ishermitian\n\nMethods\n\napply! copy dispatch!\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.AbstractRegister",
    "page": "APIs",
    "title": "QuCircuit.AbstractRegister",
    "category": "type",
    "text": "AbstractRegister{B, T}\n\nabstract type that registers will subtype from. B is the batch size, T is the data type.\n\nRequired Properties\n\nProperty Description default\nnqubit(reg) get the total number of qubits. \nnactive(reg) get the number of active qubits. \nnremain(reg) get the number of remained qubits. nqubit - nactive\nnbatch(reg) get the number of batch. B\naddress(reg) get the address of this register. \nstate(reg) get the state of this register. It always return the matrix stored inside. \neltype(reg) get the element type stored by this register on classical memory. (the type Julia should use to represent amplitude) T\ncopy(reg) copy this register. \nsimilar(reg) construct a new register with similar configuration. \n\nRequired Methods\n\nMultiply\n\n*(op, reg)\n\ndefine how operator op act on this register. This is quite useful when there is a special approach to apply an operator on this register. (e.g a register with no batch, or a register with a MPS state, etc.)\n\nnote: Note\nbe careful, generally, operators can only be applied to a register, thus we should only overload this operation and do not overload *(reg, op).\n\nPack Address\n\npack_address!(reg, addrs)\n\npack addrs together to the first k-dimensions.\n\nExample\n\nGiven a register with dimension [2, 3, 1, 5, 4], we pack [5, 4] to the first 2 dimensions. We will get [5, 4, 2, 3, 1].\n\nFocus Address\n\nfocus!(reg, range)\n\nmerge address in range together as one dimension (the active space).\n\nExample\n\nGiven a register with dimension (2^4)x3 and address [1, 2, 3, 4], we focus address [3, 4], will pack [3, 4] together and merge them as the active space. Then we will have a register with size 2^2x(2^2x3), and address [3, 4, 1, 2].\n\nInitializers\n\nInitializers are functions that provide specific quantum states, e.g zero states, random states, GHZ states and etc.\n\nregister(::Type{RT}, raw, nbatch)\n\nan general initializer for input raw state array.\n\nregister(::Type{InitMethod}, ::Type{RT}, ::Type{T}, n, nbatch)\n\ninit register type RT with InitMethod type (e.g InitMethod{:zero}) with element type T and total number qubits n with nbatch. This will be auto-binded to some shortcuts like zero_state, rand_state, randn_state.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.address",
    "page": "APIs",
    "title": "QuCircuit.address",
    "category": "function",
    "text": "address(reg)->Int\n\nget the address of this register.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.apply!",
    "page": "APIs",
    "title": "QuCircuit.apply!",
    "category": "function",
    "text": "apply!(reg, block, [signal])\n\napply a block to a register reg with or without a cache signal.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.batch_normalize",
    "page": "APIs",
    "title": "QuCircuit.batch_normalize",
    "category": "function",
    "text": "batch_normalize\n\nnormalize a batch of vector.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.batch_normalize!",
    "page": "APIs",
    "title": "QuCircuit.batch_normalize!",
    "category": "function",
    "text": "batch_normalize!(matrix)\n\nnormalize a batch of vector.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.blocks",
    "page": "APIs",
    "title": "QuCircuit.blocks",
    "category": "function",
    "text": "blocks(composite_block)\n\nget an iterator that iterate through all sub-blocks.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.dispatch!-Tuple{Function,QuCircuit.CompositeBlock,Array{T,1} where T}",
    "page": "APIs",
    "title": "QuCircuit.dispatch!",
    "category": "method",
    "text": "dispatch!(f, c, params) -> c\n\ndispatch parameters and tweak it according to callback function f(original, parameter)->new\n\ndispatch a vector of parameters to this composite block according to each sub-block\'s number of parameters.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.gate-Union{Tuple{GT}, Tuple{Type{Complex{T}},Type{GT}}, Tuple{T}} where GT<:QuCircuit.GateType where T",
    "page": "APIs",
    "title": "QuCircuit.gate",
    "category": "method",
    "text": "gate(type, gate_type)\ngate(gate_type)\n\nCreate an instance of gate_type.\n\nExample\n\ncreate a Pauli X gate: gate(X)\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.iscacheable-Tuple{QuCircuit.DefaultServer,QuCircuit.MatrixBlock,UInt64}",
    "page": "APIs",
    "title": "QuCircuit.iscacheable",
    "category": "method",
    "text": "iscaheable(server, block, level) -> Bool\n\nwhether this block is cacheable with current cache level.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.ispure-Tuple{QuCircuit.AbstractBlock}",
    "page": "APIs",
    "title": "QuCircuit.ispure",
    "category": "method",
    "text": "ispure(x) -> Bool\n\nTest whether this operator is pure.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.isreflexive-Tuple{QuCircuit.AbstractBlock}",
    "page": "APIs",
    "title": "QuCircuit.isreflexive",
    "category": "method",
    "text": "isreflexive(x) -> Bool\n\nTest whether this operator is reflexive.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.isunitary-Tuple{QuCircuit.AbstractBlock}",
    "page": "APIs",
    "title": "QuCircuit.isunitary",
    "category": "method",
    "text": "isunitary(x) -> Bool\n\nTest whether this operator is unitary.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.kronprod-Tuple{Any}",
    "page": "APIs",
    "title": "QuCircuit.kronprod",
    "category": "method",
    "text": "kronprod(itr)\n\nkronecker product all operators in the iterator.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.log2i-Union{Tuple{T}, Tuple{T}} where T",
    "page": "APIs",
    "title": "QuCircuit.log2i",
    "category": "method",
    "text": "log2i(x)\n\nlogrithm for integer pow of 2\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.nactive",
    "page": "APIs",
    "title": "QuCircuit.nactive",
    "category": "function",
    "text": "nactive(reg)->Int\n\nget the number of active qubits.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.nbatch",
    "page": "APIs",
    "title": "QuCircuit.nbatch",
    "category": "function",
    "text": "nbatch(reg)->Int\n\nget the number of batch.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.ninput",
    "page": "APIs",
    "title": "QuCircuit.ninput",
    "category": "function",
    "text": "ninput(x) -> Integer\n\nReturns the number of input qubits.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.noutput",
    "page": "APIs",
    "title": "QuCircuit.noutput",
    "category": "function",
    "text": "noutput(x) -> Integer\n\nReturns the number of output qubits.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.nparameters-Tuple{QuCircuit.AbstractBlock}",
    "page": "APIs",
    "title": "QuCircuit.nparameters",
    "category": "method",
    "text": "nparameters(x) -> Integer\n\nReturns the number of parameters of x.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.nqubit",
    "page": "APIs",
    "title": "QuCircuit.nqubit",
    "category": "function",
    "text": "nqubit(reg)->Int\n\nget the total number of qubits.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.nqubit-Tuple{QuCircuit.AbstractBlock}",
    "page": "APIs",
    "title": "QuCircuit.nqubit",
    "category": "method",
    "text": "nqubit(x) -> Integer\n\nReturns the number of qubits.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.nremain",
    "page": "APIs",
    "title": "QuCircuit.nremain",
    "category": "function",
    "text": "nremain(reg)->Int\n\nget the number of remained qubits.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.pull-Tuple{QuCircuit.DefaultServer,QuCircuit.MatrixBlock}",
    "page": "APIs",
    "title": "QuCircuit.pull",
    "category": "method",
    "text": "pull(server, block)\n\npull current block\'s cache from server\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.pull-Tuple{QuCircuit.DefaultServer,UInt64,QuCircuit.MatrixBlock}",
    "page": "APIs",
    "title": "QuCircuit.pull",
    "category": "method",
    "text": "pull(server, key, pkey) -> valtype\n\nget block\'s cache by (key, pkey)\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.rand_state",
    "page": "APIs",
    "title": "QuCircuit.rand_state",
    "category": "function",
    "text": "rand_state(n, nbatch)\n\nconstruct a normalized random state with uniform distributed theta and r with amplitude rcdot e^itheta.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.randn_state",
    "page": "APIs",
    "title": "QuCircuit.randn_state",
    "category": "function",
    "text": "randn_state(n, nbatch)\n\nconstruct normalized a random state with normal distributed theta and r with amplitude rcdot e^itheta.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.register",
    "page": "APIs",
    "title": "QuCircuit.register",
    "category": "function",
    "text": "register(::Type{RT}, raw, nbatch)\n\nan general initializer for input raw state array.\n\nregister(::Type{InitMethod}, ::Type{RT}, ::Type{T}, n, nbatch)\n\ninit register type RT with InitMethod type (e.g InitMethod{:zero}) with element type T and total number qubits n with nbatch. This will be auto-binded to some shortcuts like zero_state, rand_state, randn_state.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.state",
    "page": "APIs",
    "title": "QuCircuit.state",
    "category": "function",
    "text": "state(reg)\n\nget the state of this register. It always return the matrix stored inside.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.statevec",
    "page": "APIs",
    "title": "QuCircuit.statevec",
    "category": "function",
    "text": "statevec(reg)\n\nget the state vector of this register. It will always return the vector form (a matrix for batched register).\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.zero_state",
    "page": "APIs",
    "title": "QuCircuit.zero_state",
    "category": "function",
    "text": "zero_state(n, nbatch)\n\nconstruct a zero state 00cdots 00rangle.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.ChainBlock",
    "page": "APIs",
    "title": "QuCircuit.ChainBlock",
    "category": "type",
    "text": "ChainBlock{N, T} <: CompositeBlock{N, T}\n\nChainBlock is a basic construct tool to create user defined blocks horizontically. It is a Vector like composite type.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.Gate",
    "page": "APIs",
    "title": "QuCircuit.Gate",
    "category": "type",
    "text": "Gate{N, GT, T} <: PrimitiveBlock{N, T}\n\nN qubits gate whose matrix form is a constant.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.KronBlock",
    "page": "APIs",
    "title": "QuCircuit.KronBlock",
    "category": "type",
    "text": "KronBlock{N, T} <: CompositeBlock\n\ncomposite block that combine blocks by kronecker product.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.Roller",
    "page": "APIs",
    "title": "QuCircuit.Roller",
    "category": "type",
    "text": "Roller{N, M, T, BT} <: CompositeBlock{N, T}\n\nmap a block type to all lines and use a rolling method to evaluate them.\n\nTODO\n\nfill identity like KronBlock\n\n\n\n"
},

{
    "location": "dev/APIs/#Base.LinAlg.ishermitian-Tuple{QuCircuit.AbstractBlock}",
    "page": "APIs",
    "title": "Base.LinAlg.ishermitian",
    "category": "method",
    "text": "ishermitian(x) -> Bool\n\nTest whether this operator is hermitian.\n\n\n\n"
},

{
    "location": "dev/APIs/#Base.empty!",
    "page": "APIs",
    "title": "Base.empty!",
    "category": "function",
    "text": "empty!(::MatrixBlock, signal; recursive=false)\n\ndo nothing if this is a matrix block.\n\n\n\n"
},

{
    "location": "dev/APIs/#Base.empty!-Tuple{QuCircuit.Cached,Int64}",
    "page": "APIs",
    "title": "Base.empty!",
    "category": "method",
    "text": "empty!(object, signal; recursive=false)\n\nclear this object\'s cache with signal, if signal < level, then do nothing.\n\n\n\n"
},

{
    "location": "dev/APIs/#Base.empty!-Tuple{QuCircuit.Cached}",
    "page": "APIs",
    "title": "Base.empty!",
    "category": "method",
    "text": "empty!(object; recursive=false)\n\nforce clear this object\'s cache\n\n\n\n"
},

{
    "location": "dev/APIs/#Base.empty!-Tuple{QuCircuit.DefaultServer,UInt64}",
    "page": "APIs",
    "title": "Base.empty!",
    "category": "method",
    "text": "empty!(server, key)\n\nempty key\'s cache.\n\n\n\n"
},

{
    "location": "dev/APIs/#Base.empty!-Union{Tuple{CT}, Tuple{Type{CT}}} where CT",
    "page": "APIs",
    "title": "Base.empty!",
    "category": "method",
    "text": "empty!(type)\n\nclear all cache in this type.\n\n\n\n"
},

{
    "location": "dev/APIs/#Base.kron-Tuple{Int64,Vararg{Union{Pair, QuCircuit.MatrixBlock, Tuple},N} where N}",
    "page": "APIs",
    "title": "Base.kron",
    "category": "method",
    "text": "kron(blocks...) -> KronBlock\nkron(iterator) -> KronBlock\nkron(total, blocks...) -> KronBlock\nkron(total, iterator) -> KronBlock\n\ncreate a KronBlock with a list of blocks or tuple of heads and blocks.\n\nExample\n\nblock1 = Gate(X)\nblock2 = Gate(Z)\nblock3 = Gate(Y)\nKronBlock(block1, (3, block2), block3)\n\nThis will automatically generate a block list looks like\n\n1 -- [X] --\n2 ---------\n3 -- [Z] --\n4 -- [Y] --\n\n\n\n"
},

{
    "location": "dev/APIs/#Base.map-Tuple{QuCircuit.MatrixBlock}",
    "page": "APIs",
    "title": "Base.map",
    "category": "method",
    "text": "map(block)\n\nmap this block to all lines\n\n\n\n"
},

{
    "location": "dev/APIs/#Base.push!-Union{Tuple{QuCircuit.DefaultServer{TM},QuCircuit.MatrixBlock,TM,UInt64}, Tuple{TM}} where TM",
    "page": "APIs",
    "title": "Base.push!",
    "category": "method",
    "text": "push!(server, block, val, level) -> server\n\npush val to cache server, it will be cached if level is greater than stored level. Or it will do nothing.\n\n\n\n"
},

{
    "location": "dev/APIs/#Base.push!-Union{Tuple{QuCircuit.DefaultServer{TM},UInt64,QuCircuit.MatrixBlock,TM,UInt64}, Tuple{TM}} where TM",
    "page": "APIs",
    "title": "Base.push!",
    "category": "method",
    "text": "push!(server, key, pkey, val[, level]) -> server\n\npush (block, level) in hash key form to the server. update original cache with val. if input level is greater than stored level (input > stored).\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.cache!-Union{Tuple{QuCircuit.DefaultServer{TM},QuCircuit.MatrixBlock,UInt64}, Tuple{TM}} where TM",
    "page": "APIs",
    "title": "QuCircuit.cache!",
    "category": "method",
    "text": "cache!(server, block, level) -> server\n\nadd a new cacheable block with cache level level to the server.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.cache!-Union{Tuple{QuCircuit.DefaultServer{TM},UInt64,UInt64}, Tuple{TM}} where TM",
    "page": "APIs",
    "title": "QuCircuit.cache!",
    "category": "method",
    "text": "cache!(server, key, level) -> server\n\nadd a new cacheable block with cache level level by upload its key to the server.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.cache_matrix-Tuple{QuCircuit.MatrixBlock}",
    "page": "APIs",
    "title": "QuCircuit.cache_matrix",
    "category": "method",
    "text": "cache_matrix(block)\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.cache_type-Union{Tuple{N}, Tuple{QuCircuit.MatrixBlock{N,T}}, Tuple{T}} where T where N",
    "page": "APIs",
    "title": "QuCircuit.cache_type",
    "category": "method",
    "text": "cache_type(block) -> type\n\nget the type that this block will use for cache.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.parse_block",
    "page": "APIs",
    "title": "QuCircuit.parse_block",
    "category": "function",
    "text": "parse_block\n\nplugable argument transformer, overload this for different interface.\n\n\n\n"
},

{
    "location": "dev/APIs/#QuCircuit.setlevel!-Tuple{QuCircuit.DefaultServer,QuCircuit.MatrixBlock,UInt64}",
    "page": "APIs",
    "title": "QuCircuit.setlevel!",
    "category": "method",
    "text": "setlevel!(server, block, level)\n\nset block\'s cache level\n\n\n\n"
},

{
    "location": "dev/APIs/#APIs-1",
    "page": "APIs",
    "title": "APIs",
    "category": "section",
    "text": "Modules = [QuCircuit]\nOrder   = [:constant, :type, :function]"
},

{
    "location": "theo/register/#",
    "page": "Register",
    "title": "Register",
    "category": "page",
    "text": ""
},

{
    "location": "theo/register/#Register-1",
    "page": "Register",
    "title": "Register",
    "category": "section",
    "text": ""
},

{
    "location": "theo/register/#Storage-1",
    "page": "Register",
    "title": "Storage",
    "category": "section",
    "text": ""
},

{
    "location": "theo/register/#LDT-format-1",
    "page": "Register",
    "title": "LDT format",
    "category": "section",
    "text": "Concepturely, a wave function psirangle can be represented in a low dimentional tensor (LDT) format of order-3, L(f, r, b).f: focused (i.e. operational) dimensions\nr: remaining dimensions\nb: batch dimension.For simplicity, let\'s ignore batch dimension for the momentum, we havepsirangle = sumlimits_xy L(x y ) jrangleirangleGiven a configuration x (in operational space), we want get the i-th bit using (x<<i) & 0x1, which means putting the small end the qubit with smaller index. In this representation L(x) will get return langle xpsirangle.note: Note\nWhy not the other convension: Using the convention of putting 1st bit on the big end will need to know the total number of qubits n in order to know such positional information."
},

{
    "location": "theo/register/#HDT-format-1",
    "page": "Register",
    "title": "HDT format",
    "category": "section",
    "text": "Julia storage is column major, if we reshape the wave function to a shape of 2times2times  times2 and get the HDT (high dimensional tensor) format representation H, we can use H(x_1 x_2  x_3) to get langle xpsirangle."
},

{
    "location": "theo/register/#Operations-1",
    "page": "Register",
    "title": "Operations",
    "category": "section",
    "text": ""
},

{
    "location": "theo/register/#Kronecker-product-of-operators-1",
    "page": "Register",
    "title": "Kronecker product of operators",
    "category": "section",
    "text": "In order to put small bits on little end, the Kronecker product is O = o_n otimes ldots otimes o_2 otimes o_1 where the subscripts are qubit indices."
},

{
    "location": "theo/register/#Measurements-1",
    "page": "Register",
    "title": "Measurements",
    "category": "section",
    "text": "Measure means sample and projection."
},

{
    "location": "theo/register/#Sample-1",
    "page": "Register",
    "title": "Sample",
    "category": "section",
    "text": "Suppose we want to measure operational subspace, we can first getp(x) = langle xpsirangle^2 = sumlimits_y L(x y )^2Then we sample an asim p(x). If we just sample and don\'t really measure (change wave function), its over."
},

{
    "location": "theo/register/#Projection-1",
    "page": "Register",
    "title": "Projection",
    "category": "section",
    "text": "psirangle = sum_y L(a y )sqrtp(a) arangle yrangleGood! then we can just remove the operational qubit space since x and y spaces are totally decoupled and x is known as in state a, then we getpsirangle_r = sum_y l(0 y ) yranglewhere l = L(a:a, :, :)/sqrt(p(a))."
},

{
    "location": "theo/rotation/#",
    "page": "Rotation Block",
    "title": "Rotation Block",
    "category": "page",
    "text": ""
},

{
    "location": "theo/rotation/#Rotation-Block-1",
    "page": "Rotation Block",
    "title": "Rotation Block",
    "category": "section",
    "text": ""
},

{
    "location": "theo/grover/#",
    "page": "Grover Search",
    "title": "Grover Search",
    "category": "page",
    "text": ""
},

{
    "location": "theo/grover/#Grover-Search-1",
    "page": "Grover Search",
    "title": "Grover Search",
    "category": "section",
    "text": ""
},

{
    "location": "theo/blocks/#",
    "page": "Block Operations",
    "title": "Block Operations",
    "category": "page",
    "text": ""
},

{
    "location": "theo/blocks/#Block-Operations-1",
    "page": "Block Operations",
    "title": "Block Operations",
    "category": "section",
    "text": ""
},

{
    "location": "theo/blocks/#Direct-Construction-of-sparse-gates-1",
    "page": "Block Operations",
    "title": "Direct Construction of sparse gates",
    "category": "section",
    "text": "For example, constructing X(2, 4), we can change bases likeold basis (0, 1, ..., 15),\nold bitstring basis (0000, 0001, ..., 1111),\nnew bitstring basis (0100, 0101, ..., 1011),\nnew basis (4, 5, ..., 11).Progamming way in julia to obtain new basis isbasis = collect(0:1<<4-1)\nbasis $= 1 << 2  # for newer julia, $ will be deprecated, no-ascii \\xor can be used.Which is equivalent to a Permutation matrix or a more general PermutationMultiply matrix."
},

]}
