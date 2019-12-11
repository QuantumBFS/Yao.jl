using Documenter
using Yao
using Yao: YaoBlocks, YaoArrayRegister, YaoBase, YaoSym
using YaoBase: BitBasis
using YaoBlocks: AD
using YaoBlocks: Optimise
using Documenter.Writers.HTMLWriter
using Documenter.Utilities.DOM
using Documenter.Utilities.DOM: Tag, @tags
# Evil Prirate

const base_url = raw"https://yaoquantum.org"

const top_nav = """
<div id="top" class="navbar-wrapper">
<nav class="navbar fixed-top navbar-expand-lg navbar-dark">
    <a class="navbar-brand" href="$base_url">
        <img src="$base_url/assets/images/logo-light.png">
    </a>
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
  
    <div class="collapse navbar-collapse" id="navbarSupportedContent">
      <ul class="navbar-nav mr-auto">
        <li class="nav-item">
          <a class="nav-link" href="$base_url/tutorials/dev">Tutorial</a>
        </li>

        <li class="nav-item active">
            <a class="nav-link" href="#">Documentation<span class="sr-only">(current)</span></a>
        </li>

        <li class="nav-item">
            <a class="nav-link" href="$base_url/benchmark">Benchmark</a>
        </li>

        <li class="nav-item">
          <a class="nav-link" href="http://yaoquantum.org/soc">SoC</a>
        </li>

        <li class="nav-item">
          <a class="nav-link" href="http://yaoquantum.org/research">Research</a>
        </li>

        <li class="nav-item">
            <a class="nav-link" href="https://github.com/QuantumBFS/Yao.jl">GitHub</a>
        </li>
      </ul>
    </div>
</nav>
</div>
"""

function HTMLWriter.render_html(
    ctx,
    navnode,
    head,
    sidebar,
    navbar,
    article,
    footer,
    scripts::Vector{DOM.Node} = DOM.Node[],
)
    @tags html body div
    DOM.HTMLDocument(html[:lang=>"en"](
        head,
        body(
            Tag(Symbol("#RAW#"))(top_nav),
            div[".documenter-wrapper#documenter"](
                sidebar,
                div[".docs-main"](navbar, article, footer),
                HTMLWriter.render_settings(ctx),
            ),
        ),
        scripts...,
    ))
end


const PAGES = [
    "Home" => "index.md",
    "Manual" => Any[
        "man/array_registers.md",
        "man/symbolic.md",
        "man/blocks.md",
        "man/automatic_differentiation.md",
        "man/simplification.md",
        "man/base.md",
        "man/registers.md",
        "man/bitbasis.md",
        "man/extending_blocks.md",
    ],
    "Benchmark" => "benchmarks.md",
    "Developer Notes" => "dev/index.md",
]

makedocs(
    modules = [Yao, YaoBase, YaoArrayRegister, YaoBlocks, BitBasis, YaoSym, AD, Optimise],
    format = Documenter.HTML(
        prettyurls = ("deploy" in ARGS),
        canonical = ("deploy" in ARGS) ? "https://docs.yaoquantum.org/" : nothing,
        assets = [
            "assets/main.css",
            asset("https://yaoquantum.org/assets/main.css"),
            asset("http://yaoquantum.org/favicon.ico"),
            asset("https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css"),
        ],
    ),
    doctest = ("doctest=true" in ARGS),
    clean = false,
    sitename = "Documentation | Yao",
    linkcheck = !("skiplinks" in ARGS),
    pages = PAGES,
)

deploydocs(repo = "github.com/QuantumBFS/Yao.jl.git", target = "build")
