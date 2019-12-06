using Weave
using Documenter
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
        <li class="nav-item active">
          <a class="nav-link" href="#">Tutorial<span class="sr-only">(current)</span></a>
        </li>

        <li class="nav-item">
            <a class="nav-link" href="https://docs.yaoquantum.org/dev">Documentation</a>
        </li>

        <li class="nav-item">
            <a class="nav-link" href="$base_url/benchmark">Benchmark</a>
        </li>

        <li class="nav-item">
            <a class="nav-link" href="https://github.com/QuantumBFS/Yao.jl">GitHub</a>
        </li>
      </ul>
    </div>
</nav>
</div>
"""

function HTMLWriter.render_html(ctx, navnode, head, sidebar, navbar, article, footer, scripts::Vector{DOM.Node}=DOM.Node[])
    @tags html body div
    DOM.HTMLDocument(
        html[:lang=>"en"](
            head,
            body(
                Tag(Symbol("#RAW#"))(top_nav),
                div[".documenter-wrapper#documenter"](
                    sidebar,
                    div[".docs-main"](navbar, article, footer),
                    HTMLWriter.render_settings(ctx),
                ),
            ),
            scripts...
        )
    )
end


const Examples = ["GHZ", "QFT", "QCBM"]
const fig_path = joinpath("src", "assets", "figures")

if "build" in ARGS || "deploy" in ARGS
    for each in Examples
        file_path = joinpath("examples", join([each, ".jmd"]))
        out_path = joinpath("src", "examples", join([each, ".md"]))
        @info "expanding $file_path to markdown"
        weave(file_path, doctype="github", out_path=out_path, fig_path=fig_path)
    end
end    

const PAGES = [
    "Home" => "index.md",
    "Examples" => map(x->joinpath("examples", x * ".md"), Examples),
]

@show pwd()

makedocs(
    format = Documenter.HTML(
        prettyurls = ("deploy" in ARGS),
        canonical = ("deploy" in ARGS) ? "https://tutorials.yaoquantum.org/" : nothing,
        assets = [
            "assets/main.css",
            asset("https://yaoquantum.org/assets/main.css"),
            asset("http://yaoquantum.org/favicon.ico"),
            asset("https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css"),
            ],
        ),
    clean = false,
    sitename = raw"Tutorial|Yao",
    linkcheck = !("skiplinks" in ARGS),
    pages = PAGES
)

deploydocs(
    repo = "github.com/QuantumBFS/tutorials.git",
    target = "build",
)
