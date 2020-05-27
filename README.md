# YaoAPI

This package contains abstract APIs for Yao.

## Usage

Type `?` in a Julia REPL to show the docstring.

```julia help
help?> YaoAPI.mat
  mat([T=ComplexF64], blk)

  Returns the matrix form of given block.
```

The `mat` can be replace to any of the APIs bellow

#### Yao Register API

AbstractRegister, AdjointRegister, AllLocs, ComputationalBasis,
DensityMatrix, NoPostProcess, NotImplementedError,
PostProcess, RemoveMeasured, ResetTo, addbits!,
collapseto!, density_matrix, fidelity, focus!, insert_qubits!, instruct!,
invorder!, measure, measure!, nactive, nbatch, nqubits, nremain,
partial_tr, probs, purify, relax!, reorder!, select, select!, tracedist,
viewbatch, ρ

##### Yao Blocks API
AbstractBlock, AbstractContainer, CompositeBlock, LocationConflictError,
PrimitiveBlock, QubitMismatchError, TagBlock,
apply!, apply_back!, chcontent, chsubblocks, content, dispatch!, expect,
getiparams, iparams_eltype, iscommute, isreflexive,
isunitary, mat, mat_back!, niparams, nqubits, occupied_locs,
operator_fidelity, parameters, parameters_eltype, print_block,
render_params, setiparams!, subblocks, ishermitian, nparameters
