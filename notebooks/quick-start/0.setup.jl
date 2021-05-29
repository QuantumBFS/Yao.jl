### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ c788534a-ee16-4972-91ce-b0b3ed2799fa
md"""
# Quick Start Guide

This guide is for people who:

- doesn't know much Julia but knows Python (or other programming languages)
- knows quantum computing basics
- want to try out programming quantum circuits quickly with Julia

the contents are organized as following

1. Julia Basics
2. Basic Concepts of Yao
3. How to write a Quantum Circuit Born Machine using Yao
"""

# ╔═╡ 01ebf798-c068-4115-9cb9-381f5d8e8b35
md"""
## Julia Basics

You can jump to next section if you already know how to use Julia. We will only be introduce some basic concepts of Julia and differences comparing to Python in this section, if you wish to learn this language more seriously please refer to the learning materials on the official website: [julialang.org/learning/](https://julialang.org/learning/). This short Julia tutorial is based on [MIT computational thinking course](https://computationalthinking.mit.edu/).

If you haven't installed Julia, please refer to the front page of Julia: [julialang.org](https://julialang.org/)

If you wish to run this notebook locally, you will need to install [Pluto](https://github.com/fonsp/Pluto.jl):

1. open your [Julia interactive session (known as REPL)](https://docs.julialang.org/en/v1/manual/getting-started/)
2. press `]` key in the REPL to use the package mode, then type the following command

```julia
pkg> add Pluto
```

you will now see Julia's package manager start downloading this package. After the download is finished, press `backspace` and run the following command.

```julia
julia> import Pluto

julia> Pluto.run()
```

now it should open a web page for you in the browser, choose the downloaded notebook file `quick-start.jl`, you are good to go!
"""

# ╔═╡ Cell order:
# ╟─c788534a-ee16-4972-91ce-b0b3ed2799fa
# ╟─01ebf798-c068-4115-9cb9-381f5d8e8b35
