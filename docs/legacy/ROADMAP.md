## ROADMAP
### v0.1
* State manipulations.
* Basic gates in Ref [1] Sec. I, Table I.
* Blocks

    * arbituray rotation
    * random basis rotation
    * Grover operator (Householder reflection)
    * controled-unitary entangler gates
    * exp(i theta/2 Controlled(S)), S = X, Y, Z.
* Parameter dispatch
* Caching


##### Final Task:
* Out perform ProjectQ when 10 < num_qubit < 25.
* Random basis QCBM training of wave functions.

### v0.2
* MPS/MPO format support
* Advanced Gates
    * `TimeEvolution` gates on bonds.
    * `Toffoli` gate
    * other gates that have names/icons.
* Operations
    * Measure, MeasureAndRemove
    * Focus
* Advanced Blocks
    * FFT
* C/Fortran speed up.
* Other Selected Quantum Algorithms in Ref. [1]

##### Final Task:
* Out perform all other libs.

## References
[1] Coles, P. J. Quantum Algorithm Implementations for Beginners. arXiv: 1804.03719
