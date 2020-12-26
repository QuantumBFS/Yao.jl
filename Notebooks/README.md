Install [Pluto](https://github.com/fonsp/Pluto.jl) by running the following command in julia
```
]add Pluto
```
To run Pluto
```
import Pluto
Pluto.run()
```

You also need to install the below packages,

	]add Gaston, BitBasis, StatsBase, Yao, YaoPlots 

Also, note that for plots to show up, you need Gaston, which is a front-end of [gnuplot](http://www.gnuplot.info/). So, you've to install gnuplot externally.

###### Instructions to install gnuplot

Mac Users -` brew install gnuplot `

Windows users -
Downnload and install it from [here](https://sourceforge.net/projects/gnuplot/files/gnuplot/5.2.8/gp528-win64-mingw.exe/download)

Linux users:-

Fedora/Red-hat-based :- ` sudo dnf install gnuplot `

Ubuntu/Debian-based :- ` sudo apt install gnuplot `

Now you can either clone or download the repository and open the notebooks from the Notebooks folder in Pluto, or you can paste the link from the table of contents.

## Table of contents

#### Basics
[1 - Introduction](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/p1.jl)
- Who should read this tutorial
- Quantum 
- Bits
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/p1.pdf)

[2 - Working with Qubits](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/p2.jl)
- Qubits
- Quantum Gates and Circuits
- Single Qubit Gates
- Multiqubit Gates
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/p2.pdf)

[3 - Using Yao](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/p3.jl)
- Basics of building a circuit in Julia using Yao- 
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/p3.pdf)

[4 - Applications](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/p4.jl)
- Bell Circuit, Reverse Bell Circuit and Bell State
- Superdense Coding
- Quantum Teleportation
- References - [Quantum Computing for Everyone](https://mitpress.mit.edu/books/quantum-computing-everyone)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/p4.pdf)

[Assignment 1](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/a1.jl)

#### Intermediate

[5 - More Quantum Gates](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/p5.jl)
- More Single Qubit gates
- More Multi Qubit gates
- Some Blocks
- References - [Yao Documentation](https://docs.yaoquantum.org/)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/p5.pdf)

[6 - Arithmetic using qubits](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/p6.jl)
- Quantum Addition
- Use of CX gate in Arithmetic
- Quantum Subtraction
- References - [Dancing with Qubits](https://www.oreilly.com/library/view/dancing-with-qubits/9781838827366/), [Quantum full adder and subtractor](https://ieeexplore.ieee.org/document/1047086)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/p7.pdf)

[7 - Grover's Algorithm](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/p7.jl)
- Sign flipping
- Amplitude Amplification
- Inversion about the mean
- Implementation
- References - [Dancing with Qubits](https://www.oreilly.com/library/view/dancing-with-qubits/9781838827366/)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/p8.pdf)

[8 - Deutsch and Deutsch-Josza Algorithm](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/p8.jl)
- Deutsch Algorithm
- Deutsch Josza Algorithm
- References - [Quantum Computing for Everyone](https://mitpress.mit.edu/books/quantum-computing-everyone)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/p8.pdf)

[9 - Simon's Algorithm](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/p9.jl)
- Kronecker Product of Hadamard Gates
- Dot Products
- Implementation
- References - [Simon's Algorithm](https://qiskit.org/textbook/ch-algorithms/simon.html), [Quantum Computing for Everyone](https://mitpress.mit.edu/books/quantum-computing-everyone)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/p9.pdf)

[10 - qRAM and Uncomputation](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/p10.jl)
- qRAM
- Uncomputation
- References - [Quantum Random Access Memory](https://arxiv.org/abs/0708.1879)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/p10.pdf)

Note: Linear Algebra is a pre-requisite for upcoming tutorials.

