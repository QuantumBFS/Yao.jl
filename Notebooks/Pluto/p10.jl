### A Pluto.jl notebook ###
# v0.12.18

using Markdown
using InteractiveUtils

# ╔═╡ fe142e4e-46dd-11eb-3b8b-79a5e76789a5
using Yao, YaoPlots

# ╔═╡ fb8094ea-46da-11eb-3653-4b38fefb019c
md"# qRAM and Uncomputation"

# ╔═╡ 259b2164-46db-11eb-1969-19fbb8a1d18c
md"Consider encoding data in qubits. Assume the following array."

# ╔═╡ 99efc04a-46dd-11eb-1084-23f01b24d6e0
a = [0, 0, 1, 0, 0]

# ╔═╡ cdab262c-46dd-11eb-1d74-d579e68851ee
md"It'll take 5 qubits to encode this."

# ╔═╡ dc1b6eec-46dd-11eb-324e-5dc8a639b138
ArrayReg(bit"00100") |> r->measure(r)

# ╔═╡ 0e7ff754-46de-11eb-13d5-35b80cd84409
md"or"

# ╔═╡ 160c0030-46de-11eb-0970-593c919558e4
zero_state(5) |> put(5, 3=>X) |> r->measure(r)

# ╔═╡ 4eeb3288-46de-11eb-18d5-59ff9c23a0b0
md"Either way, lets assume we've to encode 4 such arrays, in qubits."

# ╔═╡ 67c39c3a-46de-11eb-009f-9396ff599539
b = [0, 1, 1, 0, 1]

# ╔═╡ 868c2a06-46de-11eb-1b0b-f15ec79de048
c = [1, 1, 0, 0, 0]

# ╔═╡ be7b3a6a-46de-11eb-1ecd-4b300e1c4735
d = [1, 0, 1, 1, 1]

# ╔═╡ 95399610-46de-11eb-3876-253ee5fea025
md"To encode these 4 arrays, it'd take 20 qubits, judging by the above approach. But using QRAMS, we can use 7 qubits, to encode all the 4 arrays."

# ╔═╡ f7efa09c-46de-11eb-293a-e18468e3854d
begin
	f(x) = chain(7, [control(1:2, (k+2)=>X) for k in findall(isone, x)])
	QRAM = chain(7, repeat(H, 1:2), repeat(X, 1:2), f(a), repeat(X, 1:2), put(1=>X), f(b), put(1=>X), put(2=>X), f(c), put(2=>X), f(d))
	plot(QRAM)
end

# ╔═╡ 1811259c-46e1-11eb-23f2-31d638eb73b3
md"The first two qubits, are called the address qubits.
 - When the address qubits give `` 00 `` or `` 0 `` in decimal, for the next 5 qubits, we get $ $a $.
 - When the address qubits give `` 01 `` or `` 1 `` in decimal, for the next 5 qubits, we get $ $b $.
 - When the address qubits give `` 10 `` or `` 2 `` in decimal, for the next 5 qubits, we get $ $c $.
 - When the address qubits give `` 11 `` or `` 3 `` in decimal, for the next 5 qubits, we get $ $d $."

# ╔═╡ e26bbe6a-46e1-11eb-2fdc-e94b3c7884ee
md"The input to the QRAM is `` |0000000〉 ``."

# ╔═╡ 123ffdb8-46e2-11eb-2c4f-031a675cd551
output = zero_state(7) |> QRAM |> r->measure(r, nshots = 1024)

# ╔═╡ d892e034-46e2-11eb-1e8b-83b6b547961e
begin
	using StatsBase: fit, Histogram
	hist = fit(Histogram, Int.(output), 0:2^7)
	o1 = hist.weights[findall(!iszero, hist.weights)]
	o2 = reverse.(string.(0:(2^7-1), base=2, pad=7)[findall(!iszero, hist.weights)])
end

# ╔═╡ 8d630ef4-46e2-11eb-3476-f7b2bad5da0e
md"The below code records the frequency of measurements."

# ╔═╡ 59c077c4-46e4-11eb-1335-75104c6b0d26
md"
- When address qubits were $ $(o2[1][1:2]) $, we got $ $(o2[1][3:end]) $, with the frequency $ $(o1[1]) $.
- When address qubits were $ $(o2[2][1:2]) $, we got $ $(o2[2][3:end]) $, with the frequency $ $(o1[2]) $.
- When address qubits were $ $(o2[3][1:2]) $, we got $ $(o2[3][3:end]) $, with the frequency $ $(o1[3]) $.
- When address qubits were $ $(o2[4][1:2]) $, we got $ $(o2[4][3:end]) $, with the frequency $ $(o1[4]) $."

# ╔═╡ a431f16a-46e5-11eb-0344-3de152d77226
md"We use Uncomputation to reverse the everything we do in a circuit to reverse it to its former state. It's often used with qRAMs.

An example would be "

# ╔═╡ 83972a30-4756-11eb-3dfa-4d1222bcf547
plot(chain(7, put(1:7 => label(QRAM,"qRAM")), put(1:7 => label(Daggered(QRAM),"qRAM†"))))

# ╔═╡ d8b3b16e-4756-11eb-0e23-37f97d9795c8
begin
	uncomputation = chain(7, put(1:7 => QRAM), put(1:7 => QRAM'))
	plot(uncomputation)
end

# ╔═╡ 35c5548e-4757-11eb-24b0-1d2ea7aa3eb9
zero_state(7) |> uncomputation |> r->measure(r, nshots=1024)

# ╔═╡ 52c7a73a-4757-11eb-3112-e321f2878da4
md"As you can see, we first apply the QRAM circuit, and then its dagger, which undoes the effect."

# ╔═╡ Cell order:
# ╟─fb8094ea-46da-11eb-3653-4b38fefb019c
# ╟─259b2164-46db-11eb-1969-19fbb8a1d18c
# ╠═99efc04a-46dd-11eb-1084-23f01b24d6e0
# ╟─cdab262c-46dd-11eb-1d74-d579e68851ee
# ╠═fe142e4e-46dd-11eb-3b8b-79a5e76789a5
# ╠═dc1b6eec-46dd-11eb-324e-5dc8a639b138
# ╟─0e7ff754-46de-11eb-13d5-35b80cd84409
# ╠═160c0030-46de-11eb-0970-593c919558e4
# ╟─4eeb3288-46de-11eb-18d5-59ff9c23a0b0
# ╠═67c39c3a-46de-11eb-009f-9396ff599539
# ╠═868c2a06-46de-11eb-1b0b-f15ec79de048
# ╠═be7b3a6a-46de-11eb-1ecd-4b300e1c4735
# ╟─95399610-46de-11eb-3876-253ee5fea025
# ╠═f7efa09c-46de-11eb-293a-e18468e3854d
# ╟─1811259c-46e1-11eb-23f2-31d638eb73b3
# ╟─e26bbe6a-46e1-11eb-2fdc-e94b3c7884ee
# ╠═123ffdb8-46e2-11eb-2c4f-031a675cd551
# ╟─8d630ef4-46e2-11eb-3476-f7b2bad5da0e
# ╠═d892e034-46e2-11eb-1e8b-83b6b547961e
# ╟─59c077c4-46e4-11eb-1335-75104c6b0d26
# ╟─a431f16a-46e5-11eb-0344-3de152d77226
# ╠═83972a30-4756-11eb-3dfa-4d1222bcf547
# ╠═d8b3b16e-4756-11eb-0e23-37f97d9795c8
# ╠═35c5548e-4757-11eb-24b0-1d2ea7aa3eb9
# ╟─52c7a73a-4757-11eb-3112-e321f2878da4
