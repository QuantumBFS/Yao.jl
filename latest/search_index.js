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
    "location": "dev/block/#QuCircuit.PureBlock",
    "page": "Block System",
    "title": "QuCircuit.PureBlock",
    "category": "type",
    "text": "PureBlock{N, T} <: AbstractBlock\n\nabstract type that all block with a matrix form will subtype from.\n\n\n\n"
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
    "text": "PrimitiveBlock{N, T} <: PureBlock{N, T}\n\nabstract type that all primitive block will subtype from. A primitive block is a concrete block who can not be decomposed into other blocks. All composite block can be decomposed into several primitive blocks.\n\nNOTE: subtype for primitive block with parameter should implement hash and == method to enable key value cache.\n\n\n\n"
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
    "text": "CompositeBlock{N, T} <: PureBlock{N, T}\n\nabstract supertype which composite blocks will inherit from.\n\n\n\n"
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
    "text": "AbstractMeasure{N, M} <: AbstractBlock\n\nAbstract block supertype which measurement block will inherit from.\n\n\n\n"
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
    "text": "QuCircuit.Concentrator"
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
    "text": "AbstractRegister{N, B, T}\n\nAbstract type for quantum registers, all quantum registers contains a subtype of AbstractArray as member state.\n\nParameters\n\nN is the number of qubits\nB is the batch size\nT eltype\n\n\n\n"
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
    "location": "dev/register/#QuCircuit.Register",
    "page": "Quantum Register",
    "title": "QuCircuit.Register",
    "category": "type",
    "text": "Register{N, B, T} <: AbstractRegister{N, B, T}\n\ndefault register type. This register use a builtin array to store the quantum state. The elements inside an instance of Register will be related to a certain memory address, but since it is not immutable (we need to change its shape), be careful not to change its state, though the behaviour is the same, but allocation should be avoided. Therefore, no shallow copy method is provided.\n\n\n\n"
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
    "text": "Like PyTorch, MXNet, we use a key value storage (a cache pool) to store cached blocks. Cached blocks are frequently used blocks with specific matrix form. You can choose which type of matrix storage to store in a cache pool.The benefit of this solution includes:more contiguous memory address (compare to previous plans, e.g CacheBlock, block with a cache dict)\nmore convenient for traversing cached parameters"
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

]}
