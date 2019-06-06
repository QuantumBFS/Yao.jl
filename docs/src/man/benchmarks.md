# Benchmarks

Each component package of Yao has a benchmark test based on [PkgBenchmark](https://github.com/JuliaCI/PkgBenchmark.jl)

To run the benchmarks, simply type

```julia
using PkgBenchmark

benchmarkpkg("YaoArrayRegister")
benchmarkpkg("YaoBlocks")
```

You can also compare the benchmark between different commits and pull requests. Check the [documentation](https://juliaci.github.io/PkgBenchmark.jl/stable/index.html) of **PkgBenchmark** for more details.

## Single Gate Benchmarks against ProjectQ

Click the image to check the interactive plot.

```@raw html
<div>
    <a href="https://plot.ly/~rogerluo.rl18/1/?share_key=nUtdrjZojW6kZEbO6JwnPW" target="_blank" title="Yao-ProjectQ-Benchmarks" style="display: block; text-align: center;"><img src="https://plot.ly/~rogerluo.rl18/1.png?share_key=nUtdrjZojW6kZEbO6JwnPW" alt="Yao-ProjectQ-Benchmarks" style="max-width: 100%;width: 1000px;"  width="1000" onerror="this.onerror=null;this.src='https://plot.ly/404.png';" /></a>
    <script data-plotly="rogerluo.rl18:1" sharekey-plotly="nUtdrjZojW6kZEbO6JwnPW" src="https://plot.ly/embed.js" async></script>
</div>
```

### Configuration Info:

```julia
Julia Version 1.1.0
Commit 80516ca202 (2019-01-21 21:24 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin18.5.0)
  CPU: Intel(R) Core(TM) i7-7700HQ CPU @ 2.80GHz
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-6.0.1 (ORCJIT, skylake)
```

### Package Info

**Yao**:

```julia
(v1.1) pkg> status Yao
    Status `~/.julia/environments/v1.1/Project.toml`
  [50ba71b6] BitBasis v0.5.1 [`../../dev/BitBasis`]
  [5872b779] Yao v0.5.0 [`~/.julia/dev/Yao`]
  [e600142f] YaoArrayRegister v0.3.8 [`~/.julia/dev/YaoArrayRegister`]
  [a8f54c17] YaoBase v0.9.1 [`~/.julia/dev/YaoBase`]
  [418bc28f] YaoBlocks v0.4.0 [`~/.julia/dev/YaoBlocks`]
```

**ProjectQ**:

```python
In [2]: projectq.__version__
Out[2]: '0.4.2'
```

```
# packages in environment:
#
# Name                    Version                   Build  Channel
appnope                   0.1.0                    py37_0
asn1crypto                0.24.0                   py37_0
atomicwrites              1.3.0                    py37_1
attrs                     19.1.0                   py37_1
backcall                  0.1.0                    py37_0
blas                      1.0                         mkl
bleach                    3.1.0                    py37_0
ca-certificates           2019.1.23                     0
certifi                   2019.3.9                 py37_0
cffi                      1.12.2           py37hb5b8e2f_1
chardet                   3.0.4                    py37_1
conda                     4.6.14                   py37_0
cryptography              2.6.1            py37ha12b0ac_0
cycler                    0.10.0                   py37_0
dbus                      1.13.6               h90a0687_0
decorator                 4.4.0                    py37_1
defusedxml                0.6.0                      py_0
entrypoints               0.3                      py37_0
expat                     2.2.6                h0a44026_0
fire                      0.1.3                    pypi_0    pypi
freetype                  2.9.1                hb4e5f40_0
future                    0.17.1                   pypi_0    pypi
gettext                   0.19.8.1             h15daf44_3
glib                      2.56.2               hd9629dc_0
icu                       58.2                 h4b95b61_1
idna                      2.8                      py37_0
intel-openmp              2019.0                   pypi_0    pypi
ipykernel                 5.1.0            py37h39e3cac_0
ipython                   7.5.0            py37h39e3cac_0
ipython_genutils          0.2.0                    py37_0
ipywidgets                7.4.2                    py37_0
jedi                      0.13.3                   py37_0
jinja2                    2.10.1                   py37_0
jpeg                      9b                   he5867d9_2
jsonschema                3.0.1                    py37_0
jupyter                   1.0.0                    py37_7
jupyter_client            5.2.4                    py37_0
jupyter_console           6.0.0                    py37_0
jupyter_core              4.4.0                    py37_0
kiwisolver                1.1.0            py37h0a44026_0
libcxx                    4.0.1                hcfea43d_1
libcxxabi                 4.0.1                hcfea43d_1
libedit                   3.1.20181209         hb402a30_0
libffi                    3.2.1                h475c297_4
libgfortran               3.0.1                h93005f0_2
libiconv                  1.15                 hdd342a3_7
libpng                    1.6.37               ha441bb4_0
libsodium                 1.0.16               h3efe00b_0
markupsafe                1.1.1            py37h1de35cc_0
matplotlib                3.0.3            py37h54f8f79_0
mistune                   0.8.4            py37h1de35cc_0
mkl                       2019.3                      199
mkl-service               1.1.2            py37hfbe908c_5
mkl_fft                   1.0.12           py37h5e564d8_0
mkl_random                1.0.2            py37h27c97d8_0
more-itertools            7.0.0                    py37_0
nbconvert                 5.5.0                      py_0
nbformat                  4.4.0                    py37_0
ncurses                   6.1                  h0a44026_1
networkx                  2.3                      pypi_0    pypi
notebook                  5.7.8                    py37_0
numpy                     1.16.3           py37hacdab7b_0
numpy-base                1.16.3           py37h6575580_0
openssl                   1.1.1b               h1de35cc_1
pandoc                    2.2.3.2                       0
pandocfilters             1.4.2                    py37_1
parso                     0.4.0                      py_0
pcre                      8.43                 h0a44026_0
pexpect                   4.7.0                    py37_0
pickleshare               0.7.5                    py37_0
pip                       19.0.3                   py37_0
pluggy                    0.11.0                     py_0
projectq                  0.4.2                    pypi_0    pypi
prometheus_client         0.6.0                    py37_0
prompt_toolkit            2.0.9                    py37_0
ptyprocess                0.6.0                    py37_0
py                        1.8.0                    py37_0
py-cpuinfo                5.0.0                      py_0
pybind11                  2.2.4            py37h04f5b5a_0
pycosat                   0.6.3            py37h1de35cc_0
pycparser                 2.19                     py37_0
pygal                     2.4.0                    pypi_0    pypi
pygaljs                   1.0.1                    pypi_0    pypi
pygments                  2.4.0                      py_0
pyopenssl                 19.0.0                   py37_0
pyparsing                 2.4.0                      py_0
pyqt                      5.9.2            py37h655552a_2
pyrsistent                0.14.11          py37h1de35cc_0
pysocks                   1.6.8                    py37_0
pytest                    4.5.0                    py37_0
pytest-benchmark          3.2.2                    py37_0
python                    3.7.3                h359304d_0
python-dateutil           2.8.0                    py37_0
python.app                2                        py37_9
pytz                      2019.1                     py_0
pyzmq                     18.0.0           py37h0a44026_0
qt                        5.9.7                h468cd18_1
qtconsole                 4.4.4                      py_0
readline                  7.0                  h1de35cc_5
requests                  2.21.0                   py37_0
ruamel_yaml               0.15.46          py37h1de35cc_0
scipy                     1.3.0                    pypi_0    pypi
send2trash                1.5.0                    py37_0
setuptools                41.0.0                   py37_0
sip                       4.19.8           py37h0a44026_0
six                       1.12.0                   py37_0
sqlite                    3.27.2               ha441bb4_0
terminado                 0.8.2                    py37_0
testpath                  0.4.2                    py37_0
tk                        8.6.8                ha441bb4_0
tornado                   6.0.2            py37h1de35cc_0
traitlets                 4.3.2                    py37_0
urllib3                   1.24.1                   py37_0
wcwidth                   0.1.7                    py37_0
webencodings              0.5.1                    py37_1
wheel                     0.33.1                   py37_0
widgetsnbextension        3.4.2                    py37_0
xz                        5.2.4                h1de35cc_4
yaml                      0.1.7                hc338f04_2
zeromq                    4.3.1                h0a44026_3
zlib                      1.2.11               h1de35cc_3
```

## QCBM Benchmark against ProjectQ

The ProjectQ based implementation can be found at: [github:QuantumCircuitBornMachine#benchmarkq](https://github.com/GiggleLiu/QuantumCircuitBornMachine/tree/benchmarkq)

![qcbm benchmark](../assets/benchmarks/qcbm.svg)

