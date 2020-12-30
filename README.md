# Tutorials For Yao

This repo hosts the tutorials for Yao.

## Build Locally

To build it locally, you can clone this repo by

```
git clone https://github.com/QuantumBFS/tutorials.git
```

then build it with the following command

```sh
# enter tutorial folder
cd tutorials
# instanitiate
julia --project -e 'using Pkg; Pkg.instantiate()'
# build this tutorial into html format locally
julia --project make.jl build
# open build/index.html
```

## Using LiveServer

You can host this tutorial locally for convenience in writing new tutorials, after you
instanitiate the project using `Pkg.instantiate()`, type the following command

```sh
julia --project make.jl serve
```

## Using Notebooks

You can use the Pluto Notebooks to learn the basics of Quantum Computing and Yao too. The prefered way to open the notebooks is by opening them in Pluto in your system. Furthur information in [Notebooks](https://github.com/QuantumBFS/tutorials/tree/master/Notebooks) folder.
For any question or discussion, or if you spot an error, consider writing in the [Julia slack](https://julialang.org/slack/) quantum-computing channel.

## License

Apache License 2.0
