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
Download and install it from [here](https://sourceforge.net/projects/gnuplot/files/gnuplot/5.2.8/g5-more_gates28-win64-mingw.exe/download)

Linux users:-

Fedora/Red-hat-based :- ` sudo dnf install gnuplot `

Ubuntu/Debian-based :- ` sudo apt install gnuplot `

Now you can either clone or download the repository and open the notebooks from the Notebooks folder in Pluto, or you can paste the link from the table of contents.

## Table of contents

**Note that the pdf and html versions are not available at the current moment**

#### Basics
[1 - Introduction](https://htmlpreview.github.io/?https://github.com/QuantumBFS/tutorials/blob/master/Notebooks/html/1-introduction.html)
- Who should read this tutorial
- Quantum 
- Bits
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/1-introduction.pdf), [Pluto Notebook](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/1-introduction.jl)

[2 - Working with Qubits](https://htmlpreview.github.io/?https://github.com/QuantumBFS/tutorials/blob/master/Notebooks/html/2-gates_and_qubits.html)
- Qubits
- Quantum Gates and Circuits
- Single Qubit Gates
- Multiqubit Gates
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/2-gates_and_qubits.pdf), [Pluto Notebook](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/2-gates_and_qubits.jl)

[3 - Using Yao](https://htmlpreview.github.io/?https://github.com/QuantumBFS/tutorials/blob/master/Notebooks/html/3-yao_code.html)
- Basics of building a circuit in Julia using Yao- 
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/3-yao_code.pdf), [Pluto Notebook](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/3-yao_code.jl)

[4 - Applications](https://htmlpreview.github.io/?https://github.com/QuantumBFS/tutorials/blob/master/Notebooks/html/4-applications.html)
- Bell Circuit, Reverse Bell Circuit and Bell State
- Superdense Coding
- Quantum Teleportation
- References - [Quantum Computing for Everyone](https://mitpress.mit.edu/books/quantum-computing-everyone)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/4-applications.pdf), [Pluto Notebook](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/4-applications.jl)

[Assignment 1](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/assignment1.jl)

#### Intermediate

[5 - More Quantum Gates](https://htmlpreview.github.io/?https://github.com/QuantumBFS/tutorials/blob/master/Notebooks/html/5-more_gates.html)
- More Single Qubit gates
- More Multi Qubit gates
- Some Blocks
- References - [Yao Documentation](https://docs.yaoquantum.org/)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/5-more_gates.pdf), [Pluto Notebook](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/5-more_gates.jl)

[6 - Arithmetic using qubits](https://htmlpreview.github.io/?https://github.com/QuantumBFS/tutorials/blob/master/Notebooks/html/6-quantum_arithmetic.html)
- Quantum Addition
- Use of CX gate in Arithmetic
- Quantum Subtraction
- References - [Dancing with Qubits](https://www.oreilly.com/library/view/dancing-with-qubits/9781838827366/), [Quantum full adder and subtractor](https://ieeexplore.ieee.org/document/1047086)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/6-quantum_arithmetic.pdf), [Pluto Notebook](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/6-quantum_arithmetic.jl)

[7 - Grover's Algorithm](https://htmlpreview.github.io/?https://github.com/QuantumBFS/tutorials/blob/master/Notebooks/html/7-grovers.html)
- Sign flipping
- Amplitude Amplification
- Inversion about the mean
- Implementation
- References - [Dancing with Qubits](https://www.oreilly.com/library/view/dancing-with-qubits/9781838827366/)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/7-grovers.pdf), [Pluto Notebook](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/7-grovers.jl)

[8 - Deutsch and Deutsch-Josza Algorithm](https://htmlpreview.github.io/?https://github.com/QuantumBFS/tutorials/blob/master/Notebooks/html/8-deutsch.html)
- Deutsch Algorithm
- Deutsch Josza Algorithm
- References - [Quantum Computing for Everyone](https://mitpress.mit.edu/books/quantum-computing-everyone)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/8-deutsch.pdf), [Pluto Notebook](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/8-deutsch.jl)

[9 - Simon's Algorithm](https://htmlpreview.github.io/?https://github.com/QuantumBFS/tutorials/blob/master/Notebooks/html/9-simon.html)
- Kronecker Product of Hadamard Gates
- Dot Products
- Implementation
- References - [Simon's Algorithm](https://qiskit.org/textbook/ch-algorithms/simon.html), [Quantum Computing for Everyone](https://mitpress.mit.edu/books/quantum-computing-everyone)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/9-simon.pdf), [Pluto Notebook](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/9-simon.jl)

[10 - qRAM and Uncomputation](https://htmlpreview.github.io/?https://github.com/QuantumBFS/tutorials/blob/master/Notebooks/html/1-introduction0.html)
- qRAM
- Uncomputation
- References - [Quantum Random Access Memory](https://arxiv.org/abs/0708.1879)
- [pdf](https://github.com/QuantumBFS/tutorials/raw/master/Notebooks/pdf/1-introduction0.pdf), [Pluto Notebook](https://raw.githubusercontent.com/QuantumBFS/tutorials/master/Notebooks/Pluto/1-introduction0.jl)

Note: Linear Algebra is a pre-requisite for upcoming tutorials.

