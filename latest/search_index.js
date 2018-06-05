var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
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
    "text": "Pages = [\n    \"tutorial/GHZ.md\",\n    \"tutorial/QCBM.md\",\n    \"tutorial/QFT.md\",\n]\nDepth = 1"
},

{
    "location": "#Manual-1",
    "page": "Home",
    "title": "Manual",
    "category": "section",
    "text": "Pages = [\n    \"man/block.md\",\n    \"man/cache.md\",\n]"
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
    "text": "First, you have to use this package in Julia.using YaoThen let\'s define the oracle, it is a function of the number of qubits. The whole oracle looks like this:n = 4\ncircuit = chain(\n    kron(n, 1=>X),\n    kron(n, i=>H for i in 2:n),\n    control(n, [2, ], X, 1),\n    control(n, [4, ], X, 3),\n    control(n, [3, ], X, 1),\n    control(n, [4, ], X, 3),\n    roll(n, H)\n);Let me explain what happens here. Firstly, we have a X gate which is applied to the first qubit. We need decide how we calculate this numerically, Yao offers serveral different approach to this. The simplest (but not the most efficient) one is to use kronecker product which will product X with I on other lines to gather an operator in the whole space and then apply it to the register. The first argument n means the number of qubits.kron(n, 1=>X)Similar with kron, we then need to apply some controled gates.control(n, [2, ], X, 1)This means there is a X gate on the first qubit that is controled by the second qubit. In fact, you can also create a controled gate with multiple control qubits, likecontrol(n, [2, 3], X, 1)In the end, we need to apply H gate to all lines, of course, you can do it by kron, but we offer something more efficient called roll, this applies a single gate each time on each qubit without calculating a new large operator, which will be extremely efficient for calculating small gates that tiles on almost every lines.The whole circuit is a chained structure of the above blocks. And we actually store a quantum circuit in a tree structure.circuitAfter we have an circuit, we can construct a quantum register, and input it into the oracle. You will then receive this register after processing it.r = circuit(register(bit\"0000\"))\nrLet\'s check the output:statevec(r)We have a GHZ state here, try to measure the first qubitr |> measure(1)\nstatevec(r)GHZ state will collapse to 0000rangle or 1111rangle due to entanglement!"
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
    "text": "function QFT(n::Int)\n    circuit = chain(n)\n    for i = 1:n - 1\n        push!(circuit, i=>H)\n        g = chain(\n            control([i, ], j=>shift(-2π/(1<< (j - i + 1))))\n            for j = i+1:n\n        )\n        push!(circuit, g)\n    end\n    push!(circuit, n=>H)\nend\n\nQFT(5)"
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

]}
