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

## License

Apache License 2.0
