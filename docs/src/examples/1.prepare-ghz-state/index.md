```@meta
EditURL = "<unknown>/docs/src/quick-start/1.prepare-ghz-state/main.jl"
```

[![](https://mybinder.org/badge_logo.svg)](<unknown>/generated//home/roger/code/julia/Yao/docs/src/quick-start/1.prepare-ghz-state/main.ipynb)
[![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](<unknown>/generated//home/roger/code/julia/Yao/docs/src/quick-start/1.prepare-ghz-state/main.ipynb)
[![](https://img.shields.io/badge/download-project-orange)](https://minhaskamal.github.io/DownGit/#/home?url=https://github.com/QuantumBFS/tutorials/tree/gh-pages/dev/generated//home/roger/code/julia/Yao/docs/src/quick-start/1.prepare-ghz-state)

# [Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit](@id tutorial-ghz)

First, you have to use this package in Julia.

````julia
using Yao
````

Now, we just define the circuit according to the circuit image below:
![ghz](assets/ghz4.png)

````julia
circuit = chain(
    4,
    put(1=>X),
    repeat(H, 2:4),
    control(2, 1=>X),
    control(4, 3=>X),
    control(3, 1=>X),
    control(4, 3=>X),
    repeat(H, 1:4),
)
````

````
nqubits: 4
chain
├─ put on (1)
│  └─ X
├─ repeat on (2, 3, 4)
│  └─ H
├─ control(2)
│  └─ (1,) X
├─ control(4)
│  └─ (3,) X
├─ control(3)
│  └─ (1,) X
├─ control(4)
│  └─ (3,) X
└─ repeat on (1, 2, 3, 4)
   └─ H

````

Let me explain what happens here.

## Put single qubit gate X to location 1
we have an `X` gate applied to the first qubit.
We need to tell `Yao` to put this gate on the first qubit by

````julia
put(4, 1=>X)
````

````
nqubits: 4
put on (1)
└─ X
````

We use Julia's `Pair` to denote the gate and its location in the circuit,
for two-qubit gate, you could also use a tuple of locations:

````julia
put(4, (1, 2)=>swap(2, 1, 2))
````

````
nqubits: 4
put on (1, 2)
└─ put on (1, 2)
   └─ SWAP

````

But, wait, why there's no `4` in the definition above? This is because
all the functions in `Yao` that requires to input the number of qubits as its
first argument could be lazy (curried), and let other constructors to infer the total
number of qubits later, e.g

````julia
put(1=>X)
````

````
(n -> put(n, 1 => X))
````

which will return a lambda that ask for a single argument `n`.

````julia
put(1=>X)(4)
````

````
nqubits: 4
put on (1)
└─ X
````

## Apply the same gate on different locations

next we should put Hadmard gates on all locations except the 1st qubits.

We provide `repeat` to apply the same block repeatly, repeat can take an
iterator of desired locations, and like `put`, we can also leave the total number
of qubits there.

````julia
repeat(H, 2:4)
````

````
(n -> repeat(n, H, 2:4...))
````

## Define control gates

In Yao, we could define controlled gates by feeding a gate to `control`

````julia
control(4, 2, 1=>X)
````

````
nqubits: 4
control(2)
└─ (1,) X
````

Like many others, you could leave the number of total qubits there, and infer it
later.

````julia
control(2, 1=>X)
````

````
(n -> control(n, 2, 1 => X))
````

## Composite each part together

This will create a `ControlBlock`, the concept of block in Yao basically
just means quantum operators, since the quantum circuit itself is a quantum operator,
we could create a quantum circuit by composite each part of.

Here, we use `chain` to chain each part together, a chain of quantum operators
means to apply each operators one by one in the chain. This will create a `ChainBlock`.

````julia
circuit = chain(
    4,
    put(1=>X),
    repeat(H, 2:4),
    control(2, 1=>X),
    control(4, 3=>X),
    control(3, 1=>X),
    control(4, 3=>X),
    repeat(H, 1:4),
)
````

````
nqubits: 4
chain
├─ put on (1)
│  └─ X
├─ repeat on (2, 3, 4)
│  └─ H
├─ control(2)
│  └─ (1,) X
├─ control(4)
│  └─ (3,) X
├─ control(3)
│  └─ (1,) X
├─ control(4)
│  └─ (3,) X
└─ repeat on (1, 2, 3, 4)
   └─ H

````

You can check the type of it with `typeof`

````julia
typeof(circuit)
````

````
ChainBlock{4}
````

## Construct GHZ state from 00...00

For simulation, we provide a builtin register type called `ArrayReg`,
we will use the simulated register in this example.

First, let's create ``|00⋯00⟩``, you can create it with `zero_state`

````julia
zero_state(4)
````

````
ArrayReg{1, ComplexF64, Array...}
    active qubits: 4/4
````

Or we also provide bit string literals to create arbitrary eigen state

````julia
ArrayReg(bit"0000")
````

````
ArrayReg{1, ComplexF64, Array...}
    active qubits: 4/4
````

They will both create a register with Julia's builtin `Array` as storage.

## Feed Registers to Circuits

Circuits can be applied to registers with `apply!`

````julia
apply!(zero_state(4), circuit)
````

````
ArrayReg{1, ComplexF64, Array...}
    active qubits: 4/4
````

or you can use pipe operator `|>`, when you want to chain several operations
together, here we measure the state right after the circuit for `1000` times

````julia
results = zero_state(4) |> circuit |> r->measure(r, nshots=1000)

using StatsBase, Plots

hist = fit(Histogram, Int.(results), 0:16)
bar(hist.edges[1] .- 0.5, hist.weights, legend=:none)
````

```@raw html
<?xml version="1.0" encoding="utf-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="600" height="400" viewBox="0 0 2400 1600">
<defs>
  <clipPath id="clip750">
    <rect x="0" y="0" width="2400" height="1600"/>
  </clipPath>
</defs>
<path clip-path="url(#clip750)" d="
M0 1600 L2400 1600 L2400 0 L0 0  Z
  " fill="#ffffff" fill-rule="evenodd" fill-opacity="1"/>
<defs>
  <clipPath id="clip751">
    <rect x="480" y="0" width="1681" height="1600"/>
  </clipPath>
</defs>
<path clip-path="url(#clip750)" d="
M172.015 1486.45 L2352.76 1486.45 L2352.76 47.2441 L172.015 47.2441  Z
  " fill="#ffffff" fill-rule="evenodd" fill-opacity="1"/>
<defs>
  <clipPath id="clip752">
    <rect x="172" y="47" width="2182" height="1440"/>
  </clipPath>
</defs>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:2; stroke-opacity:0.1; fill:none" points="
  341.095,1486.45 341.095,47.2441 
  "/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:2; stroke-opacity:0.1; fill:none" points="
  955.289,1486.45 955.289,47.2441 
  "/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:2; stroke-opacity:0.1; fill:none" points="
  1569.48,1486.45 1569.48,47.2441 
  "/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:2; stroke-opacity:0.1; fill:none" points="
  2183.68,1486.45 2183.68,47.2441 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  172.015,1486.45 2352.76,1486.45 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  341.095,1486.45 341.095,1467.55 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  955.289,1486.45 955.289,1467.55 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  1569.48,1486.45 1569.48,1467.55 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  2183.68,1486.45 2183.68,1467.55 
  "/>
<path clip-path="url(#clip750)" d="M341.095 1517.37 Q337.484 1517.37 335.655 1520.93 Q333.85 1524.47 333.85 1531.6 Q333.85 1538.71 335.655 1542.27 Q337.484 1545.82 341.095 1545.82 Q344.729 1545.82 346.535 1542.27 Q348.363 1538.71 348.363 1531.6 Q348.363 1524.47 346.535 1520.93 Q344.729 1517.37 341.095 1517.37 M341.095 1513.66 Q346.905 1513.66 349.961 1518.27 Q353.039 1522.85 353.039 1531.6 Q353.039 1540.33 349.961 1544.94 Q346.905 1549.52 341.095 1549.52 Q335.285 1549.52 332.206 1544.94 Q329.151 1540.33 329.151 1531.6 Q329.151 1522.85 332.206 1518.27 Q335.285 1513.66 341.095 1513.66 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M945.566 1514.29 L963.923 1514.29 L963.923 1518.22 L949.849 1518.22 L949.849 1526.7 Q950.867 1526.35 951.886 1526.19 Q952.904 1526 953.923 1526 Q959.71 1526 963.089 1529.17 Q966.469 1532.34 966.469 1537.76 Q966.469 1543.34 962.997 1546.44 Q959.525 1549.52 953.205 1549.52 Q951.029 1549.52 948.761 1549.15 Q946.515 1548.78 944.108 1548.04 L944.108 1543.34 Q946.191 1544.47 948.414 1545.03 Q950.636 1545.58 953.113 1545.58 Q957.117 1545.58 959.455 1543.48 Q961.793 1541.37 961.793 1537.76 Q961.793 1534.15 959.455 1532.04 Q957.117 1529.94 953.113 1529.94 Q951.238 1529.94 949.363 1530.35 Q947.511 1530.77 945.566 1531.65 L945.566 1514.29 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M1544.17 1544.91 L1551.81 1544.91 L1551.81 1518.55 L1543.5 1520.21 L1543.5 1515.95 L1551.76 1514.29 L1556.44 1514.29 L1556.44 1544.91 L1564.08 1544.91 L1564.08 1548.85 L1544.17 1548.85 L1544.17 1544.91 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M1583.52 1517.37 Q1579.91 1517.37 1578.08 1520.93 Q1576.28 1524.47 1576.28 1531.6 Q1576.28 1538.71 1578.08 1542.27 Q1579.91 1545.82 1583.52 1545.82 Q1587.16 1545.82 1588.96 1542.27 Q1590.79 1538.71 1590.79 1531.6 Q1590.79 1524.47 1588.96 1520.93 Q1587.16 1517.37 1583.52 1517.37 M1583.52 1513.66 Q1589.33 1513.66 1592.39 1518.27 Q1595.47 1522.85 1595.47 1531.6 Q1595.47 1540.33 1592.39 1544.94 Q1589.33 1549.52 1583.52 1549.52 Q1577.71 1549.52 1574.63 1544.94 Q1571.58 1540.33 1571.58 1531.6 Q1571.58 1522.85 1574.63 1518.27 Q1577.71 1513.66 1583.52 1513.66 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M2158.86 1544.91 L2166.5 1544.91 L2166.5 1518.55 L2158.19 1520.21 L2158.19 1515.95 L2166.45 1514.29 L2171.13 1514.29 L2171.13 1544.91 L2178.77 1544.91 L2178.77 1548.85 L2158.86 1548.85 L2158.86 1544.91 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M2188.26 1514.29 L2206.62 1514.29 L2206.62 1518.22 L2192.54 1518.22 L2192.54 1526.7 Q2193.56 1526.35 2194.58 1526.19 Q2195.6 1526 2196.62 1526 Q2202.4 1526 2205.78 1529.17 Q2209.16 1532.34 2209.16 1537.76 Q2209.16 1543.34 2205.69 1546.44 Q2202.22 1549.52 2195.9 1549.52 Q2193.72 1549.52 2191.45 1549.15 Q2189.21 1548.78 2186.8 1548.04 L2186.8 1543.34 Q2188.88 1544.47 2191.11 1545.03 Q2193.33 1545.58 2195.81 1545.58 Q2199.81 1545.58 2202.15 1543.48 Q2204.49 1541.37 2204.49 1537.76 Q2204.49 1534.15 2202.15 1532.04 Q2199.81 1529.94 2195.81 1529.94 Q2193.93 1529.94 2192.06 1530.35 Q2190.2 1530.77 2188.26 1531.65 L2188.26 1514.29 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:2; stroke-opacity:0.1; fill:none" points="
  172.015,1445.72 2352.76,1445.72 
  "/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:2; stroke-opacity:0.1; fill:none" points="
  172.015,1176.32 2352.76,1176.32 
  "/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:2; stroke-opacity:0.1; fill:none" points="
  172.015,906.93 2352.76,906.93 
  "/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:2; stroke-opacity:0.1; fill:none" points="
  172.015,637.537 2352.76,637.537 
  "/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:2; stroke-opacity:0.1; fill:none" points="
  172.015,368.145 2352.76,368.145 
  "/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:2; stroke-opacity:0.1; fill:none" points="
  172.015,98.752 2352.76,98.752 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  172.015,1486.45 172.015,47.2441 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  172.015,1445.72 190.912,1445.72 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  172.015,1176.32 190.912,1176.32 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  172.015,906.93 190.912,906.93 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  172.015,637.537 190.912,637.537 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  172.015,368.145 190.912,368.145 
  "/>
<polyline clip-path="url(#clip750)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  172.015,98.752 190.912,98.752 
  "/>
<path clip-path="url(#clip750)" d="M124.07 1431.51 Q120.459 1431.51 118.631 1435.08 Q116.825 1438.62 116.825 1445.75 Q116.825 1452.86 118.631 1456.42 Q120.459 1459.96 124.07 1459.96 Q127.705 1459.96 129.51 1456.42 Q131.339 1452.86 131.339 1445.75 Q131.339 1438.62 129.51 1435.08 Q127.705 1431.51 124.07 1431.51 M124.07 1427.81 Q129.881 1427.81 132.936 1432.42 Q136.015 1437 136.015 1445.75 Q136.015 1454.48 132.936 1459.08 Q129.881 1463.67 124.07 1463.67 Q118.26 1463.67 115.182 1459.08 Q112.126 1454.48 112.126 1445.75 Q112.126 1437 115.182 1432.42 Q118.26 1427.81 124.07 1427.81 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M54.5569 1189.67 L62.1958 1189.67 L62.1958 1163.3 L53.8856 1164.97 L53.8856 1160.71 L62.1495 1159.04 L66.8254 1159.04 L66.8254 1189.67 L74.4642 1189.67 L74.4642 1193.6 L54.5569 1193.6 L54.5569 1189.67 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M93.9086 1162.12 Q90.2975 1162.12 88.4688 1165.69 Q86.6632 1169.23 86.6632 1176.36 Q86.6632 1183.46 88.4688 1187.03 Q90.2975 1190.57 93.9086 1190.57 Q97.5428 1190.57 99.3483 1187.03 Q101.177 1183.46 101.177 1176.36 Q101.177 1169.23 99.3483 1165.69 Q97.5428 1162.12 93.9086 1162.12 M93.9086 1158.42 Q99.7187 1158.42 102.774 1163.02 Q105.853 1167.61 105.853 1176.36 Q105.853 1185.08 102.774 1189.69 Q99.7187 1194.27 93.9086 1194.27 Q88.0984 1194.27 85.0197 1189.69 Q81.9642 1185.08 81.9642 1176.36 Q81.9642 1167.61 85.0197 1163.02 Q88.0984 1158.42 93.9086 1158.42 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M124.07 1162.12 Q120.459 1162.12 118.631 1165.69 Q116.825 1169.23 116.825 1176.36 Q116.825 1183.46 118.631 1187.03 Q120.459 1190.57 124.07 1190.57 Q127.705 1190.57 129.51 1187.03 Q131.339 1183.46 131.339 1176.36 Q131.339 1169.23 129.51 1165.69 Q127.705 1162.12 124.07 1162.12 M124.07 1158.42 Q129.881 1158.42 132.936 1163.02 Q136.015 1167.61 136.015 1176.36 Q136.015 1185.08 132.936 1189.69 Q129.881 1194.27 124.07 1194.27 Q118.26 1194.27 115.182 1189.69 Q112.126 1185.08 112.126 1176.36 Q112.126 1167.61 115.182 1163.02 Q118.26 1158.42 124.07 1158.42 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M57.7745 920.275 L74.0939 920.275 L74.0939 924.21 L52.1495 924.21 L52.1495 920.275 Q54.8115 917.52 59.3949 912.891 Q64.0013 908.238 65.1819 906.895 Q67.4272 904.372 68.3068 902.636 Q69.2096 900.877 69.2096 899.187 Q69.2096 896.433 67.2652 894.696 Q65.3439 892.96 62.2421 892.96 Q60.043 892.96 57.5893 893.724 Q55.1588 894.488 52.381 896.039 L52.381 891.317 Q55.2051 890.183 57.6588 889.604 Q60.1124 889.025 62.1495 889.025 Q67.5198 889.025 70.7142 891.71 Q73.9087 894.396 73.9087 898.886 Q73.9087 901.016 73.0985 902.937 Q72.3115 904.835 70.205 907.428 Q69.6263 908.099 66.5245 911.317 Q63.4226 914.511 57.7745 920.275 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M93.9086 892.729 Q90.2975 892.729 88.4688 896.294 Q86.6632 899.835 86.6632 906.965 Q86.6632 914.071 88.4688 917.636 Q90.2975 921.178 93.9086 921.178 Q97.5428 921.178 99.3483 917.636 Q101.177 914.071 101.177 906.965 Q101.177 899.835 99.3483 896.294 Q97.5428 892.729 93.9086 892.729 M93.9086 889.025 Q99.7187 889.025 102.774 893.632 Q105.853 898.215 105.853 906.965 Q105.853 915.692 102.774 920.298 Q99.7187 924.882 93.9086 924.882 Q88.0984 924.882 85.0197 920.298 Q81.9642 915.692 81.9642 906.965 Q81.9642 898.215 85.0197 893.632 Q88.0984 889.025 93.9086 889.025 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M124.07 892.729 Q120.459 892.729 118.631 896.294 Q116.825 899.835 116.825 906.965 Q116.825 914.071 118.631 917.636 Q120.459 921.178 124.07 921.178 Q127.705 921.178 129.51 917.636 Q131.339 914.071 131.339 906.965 Q131.339 899.835 129.51 896.294 Q127.705 892.729 124.07 892.729 M124.07 889.025 Q129.881 889.025 132.936 893.632 Q136.015 898.215 136.015 906.965 Q136.015 915.692 132.936 920.298 Q129.881 924.882 124.07 924.882 Q118.26 924.882 115.182 920.298 Q112.126 915.692 112.126 906.965 Q112.126 898.215 115.182 893.632 Q118.26 889.025 124.07 889.025 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M67.9133 636.183 Q71.2698 636.901 73.1448 639.169 Q75.0429 641.438 75.0429 644.771 Q75.0429 649.887 71.5244 652.688 Q68.0059 655.489 61.5245 655.489 Q59.3486 655.489 57.0338 655.049 Q54.7421 654.632 52.2884 653.776 L52.2884 649.262 Q54.2328 650.396 56.5477 650.975 Q58.8625 651.554 61.3856 651.554 Q65.7837 651.554 68.0754 649.817 Q70.3902 648.081 70.3902 644.771 Q70.3902 641.716 68.2374 640.003 Q66.1078 638.267 62.2884 638.267 L58.2606 638.267 L58.2606 634.424 L62.4735 634.424 Q65.9226 634.424 67.7513 633.058 Q69.58 631.669 69.58 629.077 Q69.58 626.415 67.6819 625.003 Q65.8069 623.568 62.2884 623.568 Q60.3671 623.568 58.168 623.984 Q55.969 624.401 53.3301 625.281 L53.3301 621.114 Q55.9921 620.373 58.3069 620.003 Q60.6449 619.632 62.705 619.632 Q68.0291 619.632 71.1309 622.063 Q74.2327 624.47 74.2327 628.591 Q74.2327 631.461 72.5892 633.452 Q70.9457 635.419 67.9133 636.183 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M93.9086 623.336 Q90.2975 623.336 88.4688 626.901 Q86.6632 630.443 86.6632 637.572 Q86.6632 644.679 88.4688 648.243 Q90.2975 651.785 93.9086 651.785 Q97.5428 651.785 99.3483 648.243 Q101.177 644.679 101.177 637.572 Q101.177 630.443 99.3483 626.901 Q97.5428 623.336 93.9086 623.336 M93.9086 619.632 Q99.7187 619.632 102.774 624.239 Q105.853 628.822 105.853 637.572 Q105.853 646.299 102.774 650.905 Q99.7187 655.489 93.9086 655.489 Q88.0984 655.489 85.0197 650.905 Q81.9642 646.299 81.9642 637.572 Q81.9642 628.822 85.0197 624.239 Q88.0984 619.632 93.9086 619.632 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M124.07 623.336 Q120.459 623.336 118.631 626.901 Q116.825 630.443 116.825 637.572 Q116.825 644.679 118.631 648.243 Q120.459 651.785 124.07 651.785 Q127.705 651.785 129.51 648.243 Q131.339 644.679 131.339 637.572 Q131.339 630.443 129.51 626.901 Q127.705 623.336 124.07 623.336 M124.07 619.632 Q129.881 619.632 132.936 624.239 Q136.015 628.822 136.015 637.572 Q136.015 646.299 132.936 650.905 Q129.881 655.489 124.07 655.489 Q118.26 655.489 115.182 650.905 Q112.126 646.299 112.126 637.572 Q112.126 628.822 115.182 624.239 Q118.26 619.632 124.07 619.632 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M66.5939 354.939 L54.7884 373.388 L66.5939 373.388 L66.5939 354.939 M65.367 350.865 L71.2466 350.865 L71.2466 373.388 L76.1772 373.388 L76.1772 377.277 L71.2466 377.277 L71.2466 385.425 L66.5939 385.425 L66.5939 377.277 L50.9921 377.277 L50.9921 372.763 L65.367 350.865 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M93.9086 353.943 Q90.2975 353.943 88.4688 357.508 Q86.6632 361.05 86.6632 368.179 Q86.6632 375.286 88.4688 378.851 Q90.2975 382.392 93.9086 382.392 Q97.5428 382.392 99.3483 378.851 Q101.177 375.286 101.177 368.179 Q101.177 361.05 99.3483 357.508 Q97.5428 353.943 93.9086 353.943 M93.9086 350.24 Q99.7187 350.24 102.774 354.846 Q105.853 359.429 105.853 368.179 Q105.853 376.906 102.774 381.513 Q99.7187 386.096 93.9086 386.096 Q88.0984 386.096 85.0197 381.513 Q81.9642 376.906 81.9642 368.179 Q81.9642 359.429 85.0197 354.846 Q88.0984 350.24 93.9086 350.24 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M124.07 353.943 Q120.459 353.943 118.631 357.508 Q116.825 361.05 116.825 368.179 Q116.825 375.286 118.631 378.851 Q120.459 382.392 124.07 382.392 Q127.705 382.392 129.51 378.851 Q131.339 375.286 131.339 368.179 Q131.339 361.05 129.51 357.508 Q127.705 353.943 124.07 353.943 M124.07 350.24 Q129.881 350.24 132.936 354.846 Q136.015 359.429 136.015 368.179 Q136.015 376.906 132.936 381.513 Q129.881 386.096 124.07 386.096 Q118.26 386.096 115.182 381.513 Q112.126 376.906 112.126 368.179 Q112.126 359.429 115.182 354.846 Q118.26 350.24 124.07 350.24 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M53.793 81.472 L72.1494 81.472 L72.1494 85.4072 L58.0754 85.4072 L58.0754 93.8793 Q59.0939 93.5321 60.1124 93.3701 Q61.131 93.1849 62.1495 93.1849 Q67.9365 93.1849 71.3161 96.3562 Q74.6957 99.5274 74.6957 104.944 Q74.6957 110.523 71.2235 113.625 Q67.7513 116.703 61.4319 116.703 Q59.256 116.703 56.9875 116.333 Q54.7421 115.963 52.3347 115.222 L52.3347 110.523 Q54.418 111.657 56.6402 112.213 Q58.8625 112.768 61.3393 112.768 Q65.3439 112.768 67.6819 110.662 Q70.0198 108.555 70.0198 104.944 Q70.0198 101.333 67.6819 99.2265 Q65.3439 97.1201 61.3393 97.1201 Q59.4643 97.1201 57.5893 97.5367 Q55.7375 97.9534 53.793 98.833 L53.793 81.472 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M93.9086 84.5507 Q90.2975 84.5507 88.4688 88.1155 Q86.6632 91.6571 86.6632 98.7867 Q86.6632 105.893 88.4688 109.458 Q90.2975 113 93.9086 113 Q97.5428 113 99.3483 109.458 Q101.177 105.893 101.177 98.7867 Q101.177 91.6571 99.3483 88.1155 Q97.5428 84.5507 93.9086 84.5507 M93.9086 80.847 Q99.7187 80.847 102.774 85.4534 Q105.853 90.0368 105.853 98.7867 Q105.853 107.514 102.774 112.12 Q99.7187 116.703 93.9086 116.703 Q88.0984 116.703 85.0197 112.12 Q81.9642 107.514 81.9642 98.7867 Q81.9642 90.0368 85.0197 85.4534 Q88.0984 80.847 93.9086 80.847 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip750)" d="M124.07 84.5507 Q120.459 84.5507 118.631 88.1155 Q116.825 91.6571 116.825 98.7867 Q116.825 105.893 118.631 109.458 Q120.459 113 124.07 113 Q127.705 113 129.51 109.458 Q131.339 105.893 131.339 98.7867 Q131.339 91.6571 129.51 88.1155 Q127.705 84.5507 124.07 84.5507 M124.07 80.847 Q129.881 80.847 132.936 85.4534 Q136.015 90.0368 136.015 98.7867 Q136.015 107.514 132.936 112.12 Q129.881 116.703 124.07 116.703 Q118.26 116.703 115.182 112.12 Q112.126 107.514 112.126 98.7867 Q112.126 90.0368 115.182 85.4534 Q118.26 80.847 124.07 80.847 Z" fill="#000000" fill-rule="evenodd" fill-opacity="1" /><path clip-path="url(#clip752)" d="
M291.959 109.528 L291.959 1445.72 L390.23 1445.72 L390.23 109.528 L291.959 109.528 L291.959 109.528  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  291.959,109.528 291.959,1445.72 390.23,1445.72 390.23,109.528 291.959,109.528 
  "/>
<path clip-path="url(#clip752)" d="
M414.798 1445.72 L414.798 1445.72 L513.069 1445.72 L513.069 1445.72 L414.798 1445.72 L414.798 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  414.798,1445.72 414.798,1445.72 513.069,1445.72 414.798,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M537.637 1445.72 L537.637 1445.72 L635.908 1445.72 L635.908 1445.72 L537.637 1445.72 L537.637 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  537.637,1445.72 537.637,1445.72 635.908,1445.72 537.637,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M660.476 1445.72 L660.476 1445.72 L758.747 1445.72 L758.747 1445.72 L660.476 1445.72 L660.476 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  660.476,1445.72 660.476,1445.72 758.747,1445.72 660.476,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M783.314 1445.72 L783.314 1445.72 L881.585 1445.72 L881.585 1445.72 L783.314 1445.72 L783.314 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  783.314,1445.72 783.314,1445.72 881.585,1445.72 783.314,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M906.153 1445.72 L906.153 1445.72 L1004.42 1445.72 L1004.42 1445.72 L906.153 1445.72 L906.153 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  906.153,1445.72 906.153,1445.72 1004.42,1445.72 906.153,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M1028.99 1445.72 L1028.99 1445.72 L1127.26 1445.72 L1127.26 1445.72 L1028.99 1445.72 L1028.99 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  1028.99,1445.72 1028.99,1445.72 1127.26,1445.72 1028.99,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M1151.83 1445.72 L1151.83 1445.72 L1250.1 1445.72 L1250.1 1445.72 L1151.83 1445.72 L1151.83 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  1151.83,1445.72 1151.83,1445.72 1250.1,1445.72 1151.83,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M1274.67 1445.72 L1274.67 1445.72 L1372.94 1445.72 L1372.94 1445.72 L1274.67 1445.72 L1274.67 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  1274.67,1445.72 1274.67,1445.72 1372.94,1445.72 1274.67,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M1397.51 1445.72 L1397.51 1445.72 L1495.78 1445.72 L1495.78 1445.72 L1397.51 1445.72 L1397.51 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  1397.51,1445.72 1397.51,1445.72 1495.78,1445.72 1397.51,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M1520.35 1445.72 L1520.35 1445.72 L1618.62 1445.72 L1618.62 1445.72 L1520.35 1445.72 L1520.35 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  1520.35,1445.72 1520.35,1445.72 1618.62,1445.72 1520.35,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M1643.19 1445.72 L1643.19 1445.72 L1741.46 1445.72 L1741.46 1445.72 L1643.19 1445.72 L1643.19 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  1643.19,1445.72 1643.19,1445.72 1741.46,1445.72 1643.19,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M1766.02 1445.72 L1766.02 1445.72 L1864.3 1445.72 L1864.3 1445.72 L1766.02 1445.72 L1766.02 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  1766.02,1445.72 1766.02,1445.72 1864.3,1445.72 1766.02,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M1888.86 1445.72 L1888.86 1445.72 L1987.13 1445.72 L1987.13 1445.72 L1888.86 1445.72 L1888.86 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  1888.86,1445.72 1888.86,1445.72 1987.13,1445.72 1888.86,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M2011.7 1445.72 L2011.7 1445.72 L2109.97 1445.72 L2109.97 1445.72 L2011.7 1445.72 L2011.7 1445.72  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  2011.7,1445.72 2011.7,1445.72 2109.97,1445.72 2011.7,1445.72 
  "/>
<path clip-path="url(#clip752)" d="
M2134.54 87.9763 L2134.54 1445.72 L2232.81 1445.72 L2232.81 87.9763 L2134.54 87.9763 L2134.54 87.9763  Z
  " fill="#009af9" fill-rule="evenodd" fill-opacity="1"/>
<polyline clip-path="url(#clip752)" style="stroke:#000000; stroke-linecap:butt; stroke-linejoin:round; stroke-width:4; stroke-opacity:1; fill:none" points="
  2134.54,87.9763 2134.54,1445.72 2232.81,1445.72 2232.81,87.9763 2134.54,87.9763 
  "/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="279.676" cy="109.528" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="402.514" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="525.353" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="648.192" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="771.03" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="893.869" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="1016.71" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="1139.55" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="1262.39" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="1385.22" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="1508.06" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="1630.9" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="1753.74" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="1876.58" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="1999.42" cy="1445.72" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="2122.26" cy="87.9763" r="2"/>
<circle clip-path="url(#clip752)" style="fill:#009af9; stroke:none; fill-opacity:0" cx="2245.1" cy="109.528" r="2"/>
</svg>

```

GHZ state will collapse to ``|0000⟩`` or ``|1111⟩``.

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

