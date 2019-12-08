# # Using External Libraries

# It is straightforward to make use of external libraries
# written in other language. For example, the following
# codes import modules from the [OpenFermion](https://github.com/quantumlib/OpenFermion)
# and construct a qubit Hamiltonian for molecules as quantum blocks in Yao.

using Yao
using LinearAlgebra
using PyCall

# Install OpenFermion and PySCF if you don't have them
pip = pyimport("pip._internal.main")
pip.main(["install", "pyscf", "openfermion"])


# First we import hamiltonians from OpenFermion and PySCF

of_hamil = pyimport("openfermion.hamiltonians")
of_trsfm = pyimport("openfermion.transforms")
of_pyscf = pyimport("openfermionpyscf")

# following the OpenFermion and PySCF tutorial, we define molecules from data.

diatomic_bond_length = 1.0
geometry = [("H", (0., 0., 0.)), ("H", (0., 0., diatomic_bond_length))]
basis = "sto-3g"
multiplicity = 1
charge = 0
description = string(diatomic_bond_length)

molecule = of_hamil.MolecularData(geometry, basis, multiplicity, charge, description)
molecule = of_pyscf.run_pyscf(molecule,run_scf=1,run_fci=1)

# Then obtain its Hamiltonian

m_h = molecule.get_molecular_hamiltonian()
nbits = m_h.n_qubits

jw_h = of_trsfm.jordan_wigner(of_trsfm.get_fermion_operator(m_h))

# now, let's construct the corresponding Hamiltonian in Yao

function yao_hamiltonian(nbits, jw_h)
    gates = Dict("X"=>X, "Y"=>Y, "Z"=>Z)
    h = Add{nbits}()
    for (k, v) in jw_h.terms
        op = v*put(nbits, 1=>I2)
        for t in k
            site, opname = t
            op = op*put(nbits, site+1=>gates[opname])
        end
        push!(h, op)
    end
    h
end

# Yah!
yao_h = yao_hamiltonian(nbits, jw_h)

# now let's try to calculate its eigen values
w, v = eigen(Matrix(yao_h))
