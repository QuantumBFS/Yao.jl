### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ 37dc27ba-f78a-11ea-1d7d-2569658183fa
md"# _Introduction_

#### Who shoud read this tutorial? 
Anyone who is interested in knowing what Quantum Computing is about or is new to Quantum Computing.
  

#### Requirements:
##### What should I know?
Knowledge of high school Mathematics should be enough.
Also, this course is in Julia, so knowing basic syntax of Julia might 			  help... but knowing Julia syntax is not necessary. Even if you know the 				basics of Python, R or Ruby, and how to write programs in them, you 				  should be fine.
##### The required software :-
- [Julia] (https://julialang.org/downloads/)
- [Yao.jl] (https://yaoquantum.org/)
Install Julia, if you don't already have it. Installation instructions are there in the link."

# ╔═╡ b0a72718-f78e-11ea-1ef3-01bd13cfcd17
md"## _*Quantum*_

Now recently, if you're in any way affiliated to Science or Computer Science or even if you're just a tech lover, you must have stumbled across the word \"_quantum_\". 
You must have wondered, \" What does it mean?\" .

So, let's just say that historically, some experiments were conducted by some scientists in Physics, and their results happened to defy what laws of Physics stated, before then. Now this was around the year 1900. The scientists came up with theories that explained those results and the most widely accepted (and working) theory was quantum mechanics, or in Einstein's words, \"*Real Black Magic Calculus*\". On the basis of quantum mechanics, we now have Quantum Physics, Quantum Chemistry, Quantum Biology, Quantum Computers and lots of other new stuff. The quantum computers just exploit some weird phenomenons of quantum mechanics.

Quantum Mechanics will not be explained in detail, in this tutorial. Only the part required for computation. If you're interested in Quantum Mechanics, [Modern Quantum Mechanics by J. J. Sakurai] (https://doi.org/10.1017/9781108499996) might be a good read."

# ╔═╡ 8c5d75be-f794-11ea-2b14-d108a10dc9d9
md"## *Bits*
Okay, what makes quantum computers different than a present day or _classical_ one.
To understand that, we must understand a few things about classical computers. 

\"*A bit (short for binary digit) is the smallest unit of data in a computer*\". You must have read this in a book or article about computers. Computers use bits, represented by the digits 0 and 1, to store data. We organize these bits to store information and manipulate these bits and perform operations on them to get a variety of things done. 
Like storing numbers, or images or videos. Adding numbers, subtracting numbers.
How? Well... Consider storing a number. In this case, the collection of bits 1 0 1 1 can be considered as, $ 2^3 + 0 + 2^1 + 2^0 = 11 $. The genereal idea being, the summation of $ 2^{position of 1s(starting from 0) from right} $.  

Then just divide your computer screen into a matrix of 1000s of cells, and every cell containing a number, corresponding to the colour in that cell. Yeah, images are stored that way, those numbers are called pixels. Addition looks a bit more complicated than this. It's done using something called 'gates'. Gates take one or more bits and perform a logical operation on them to give a certain output. There's an \"AND gate\" which, takes in 2 bits and multiplies them to give an output. There're more gates like the OR gate, XOR gate etc. These gates are arranged in a certain manner to perform feats like addition, subtraction, etc."

# ╔═╡ Cell order:
# ╟─37dc27ba-f78a-11ea-1d7d-2569658183fa
# ╟─b0a72718-f78e-11ea-1ef3-01bd13cfcd17
# ╟─8c5d75be-f794-11ea-2b14-d108a10dc9d9
