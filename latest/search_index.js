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
    "text": "First, you have to use this package in Julia.using QuCircuitThen let\'s define the oracle, it is a function of the number of qubits. The whole oracle looks like this:circuit(num_bits) = sequence(\n    X(num_bits, 1),\n    H(num_bits, 2:num_bits),\n    X(1) |> C(num_bits, 2),\n    X(3) |> C(num_bits, 4),\n    X(1) |> C(num_bits, 3),\n    X(3) |> C(num_bits, 4),\n    H(num_bits, 1:num_bits),\n)After we have an circuit, we can construct a quantum register, and input it into the oracle. You will then receive this register after processing it.reg = zero_state(4)\n\nreg |> circuit(4)\nregLet\'s check the output:state(reg)We have a GHZ state here, try to measure the first qubitreg |> measure(1)\nstate(reg)GHZ state will collapse to 0000rangle or 1111rangle due to entanglement!"
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
    "location": "dev/block/#PureBlock-1",
    "page": "Block System",
    "title": "PureBlock",
    "category": "section",
    "text": "QuCircuit.PureBlock"
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
    "location": "dev/register/#QuCircuit.AbstractRegister",
    "page": "Quantum Register",
    "title": "QuCircuit.AbstractRegister",
    "category": "type",
    "text": "AbstractRegister{B, T}\n\nabstract type that registers will subtype from. B is the batch size, T is the data type.\n\nRequired Properties\n\nProperty Description default\nnqubit(reg) get the total number of qubits. \nnactive(reg) get the number of active qubits. \nnremain(reg) get the number of remained qubits. nqubit - nactive\nnbatch(reg) get the number of batch. B\naddress(reg) get the address of this register. \nstate(reg) get the state of this register. It always return the matrix stored inside. \neltype(reg) get the element type stored by this register on classical memory. (the type Julia should use to represent amplitude) T\ncopy(reg) copy this register. \nsimilar(reg) construct a new register with similar configuration. \n\nRequired Methods\n\nMultiply\n\n*(op, reg)\n\ndefine how operator op act on this register. This is quite useful when there is a special approach to apply an operator on this register. (e.g a register with no batch, or a register with a MPS state, etc.)\n\nnote: Note\nbe careful, generally, operators can only be applied to a register, thus we should only overload this operation and do not overload *(reg, op).\n\nPack Address\n\npack_address!(reg, addrs)\n\npack addrs together to the first k-dimensions.\n\nExample\n\nGiven a register with dimension [2, 3, 1, 5, 4], we pack [5, 4] to the first 2 dimensions. We will get [5, 4, 2, 3, 1].\n\nFocus Address\n\nfocus!(reg, range)\n\nmerge address in range together as one dimension (the active space).\n\nExample\n\nGiven a register with dimension (2^4)x3 and address [1, 2, 3, 4], we focus address [3, 4], will pack [3, 4] together and merge them as the active space. Then we will have a register with size 2^2x(2^2x3), and address [3, 4, 1, 2].\n\nInitializers\n\nInitializers are functions that provide specific quantum states, e.g zero states, random states, GHZ states and etc.\n\nregister(::Type{RT}, raw, nbatch)\n\nan general initializer for input raw state array.\n\nregister(::Type{InitMethod}, ::Type{RT}, ::Type{T}, n, nbatch)\n\ninit register type RT with InitMethod type (e.g InitMethod{:zero}) with element type T and total number qubits n with nbatch. This will be auto-binded to some shortcuts like zero_state, rand_state, randn_state.\n\n\n\n"
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
    "text": "Base.hashindex(key, sz)sz is the total length of the list of slots. This function is actually equivalent to "
},

{
    "location": "dev/cache/#Implementation-1",
    "page": "Cache",
    "title": "Implementation",
    "category": "section",
    "text": "Unlike parameter servers in deep learning frameworks. Our cache server contains not only the cached (sparse) matrix, but also its related cache level, which defines its update priority during the evluation of a quantum circuit."
},

{
    "location": "dev/cache/#Possible-Solutions-1",
    "page": "Cache",
    "title": "Possible Solutions",
    "category": "section",
    "text": ""
},

{
    "location": "dev/cache/#Solution-1-1",
    "page": "Cache",
    "title": "Solution 1",
    "category": "section",
    "text": "mutable struct CacheElement{TM <: AbstractMatrix}\n    level::UInt\n    data::Dict{Any, TM}\nend\n\nstruct CacheServer{TM} <: AbstractCacheServer\n    kvstore::Dict{Any, CacheElement{TM}}\nendThis cannot characterize parameters with "
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
