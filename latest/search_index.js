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
    "location": "notes/#",
    "page": "Notes",
    "title": "Notes",
    "category": "page",
    "text": ""
},

{
    "location": "notes/#Design-Notes-1",
    "page": "Notes",
    "title": "Design Notes",
    "category": "section",
    "text": ""
},

{
    "location": "notes/#Block-1",
    "page": "Notes",
    "title": "Block",
    "category": "section",
    "text": "Blocks are the basic component of an quantum oracle in QuCircuit.jl."
},

{
    "location": "notes/#Memory-Contiguous-1",
    "page": "Notes",
    "title": "Memory Contiguous",
    "category": "section",
    "text": "Block should be contiguous on quantum registers, which means a block for N-qubits starts from location k, should be contiguous on this quantum memory which will be contiguous on its classical simulated quantum register too.-- [ ] -- [ ] --"
},

{
    "location": "notes/#Permutor-1",
    "page": "Notes",
    "title": "Permutor",
    "category": "section",
    "text": "A Permutor is an special block that will permute the order of quantum memory address. This will make in-contiguous memory address become contiguous. But in simulation, this will cause an extra memory allocation. *****         *****         ****\n *   * -- 1    *   * -- 1 -- ****\n *   * -- 2    *   * -- 3 -- ****\n *   * -- 3 => *   * -- 5 -- ****\n *   * -- 4    *   * -- 2    ****\n *   * -- 5    *   * -- 4\n *****         *****However, by default, the block tree will not help in organizing the order of memory address."
},

{
    "location": "notes/#Default-Behaviour-of-Block-Evaluation-1",
    "page": "Notes",
    "title": "Default Behaviour of Block Evaluation",
    "category": "section",
    "text": "The default behaviour of the evaluation of a block tree will use kronecker product to assemble different gates, e.g, the following circuit will be evaluated by\n-- [Z] ---------\n\n-- [X] -- [X] --\n\n---------- X ---\n           |\n--------- [ ] --\nBy default, its evaluation is equivalent toZ otimes X otimes CNOT cdot I otimes X otimes I otimes IThis is because the gates are stored by a tree inside a block with their memory address and the calculation order on each line, by default the order will be the insertion order.       gates address  order\n---------------------------\nBlock: Z     (1, )      1\n       X     (2, )      1\n       X     (2, )      2\n       CNOT  (3, 4)     1The apply! method will first run through the memory address 1:N (N = 4 here) to calculate gates with same order on each line (if there is no gate, then use an identity) until it meets the maximum depth of the block, the maximum depth will be the maximum order.User can specify the calculation order by input an integer, and when        gates address order\n----------------------------\nBlock:  Z     (1, )      1\n        X     (2, )      1\n        X     (2, )      2\n        CNOT  (3, 4)     2the calculation will be equivalent toZ otimes X otimes I otimes I cdot I otimes X otimes CNOT"
},

{
    "location": "notes/#More-efficient-controlled-gates-1",
    "page": "Notes",
    "title": "More efficient controlled gates",
    "category": "section",
    "text": "controlled gates can be an arbitrary gate with an identityCOP = beginpmatrix\n I  0\n 0  X\nendpmatrix beginaligned\nCOP cranglePsirangle = (alpha_10rangle + alpha_21rangle) XPsirangle\n                          = alpha_10ranglePsirangle + alpha_21rangle X Psirangle\nendalignedTherefore, the functionality of a controlled gate will looks likebeginaligned\n U_1(eta_1)cdot COP(c Psi) cdot U_2(eta_2) cdot U_3(eta_3)eta_1ranglecrangleeta_2ranglePsirangleeta_3rangle\n rightarrow U_1(eta_1)cdot COP(c Psi) cdot U_2(eta_2) cdot U_3(eta_3) eta_1rangle (alpha_10rangle + alpha_21rangle) eta_2rangle Psirangle eta_3rangle\n rightarrow alpha_1 U_1otimes I otimes U_2 otimes I otimes U_3eta_1rangle 0rangle eta_2rangle Psirangle eta_3rangle + alpha_2 U_1otimes I otimes U_2 otimes X otimes U_3 etarangle 1rangle eta_2rangle Psirangle eta_3rangle\n rightarrow U_1otimes I otimes U_2 otimes I otimes U_3 phirangle + alpha_2 U_1otimes Iotimes U_2 otimes (X - I) otimes U_3 eta_1rangle 1rangle eta_2rangle Psirangle eta_3rangle\nendaligned"
},

]}
