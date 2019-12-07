using Literate
import LiveServer
using Documenter
using Documenter.Writers.HTMLWriter
using Documenter.Utilities.DOM
using Documenter.Utilities.DOM: Tag, @tags
using LiveServer: SimpleWatcher, WatchedFile, set_callback!, file_changed_callback
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

## Literate build
attach_notebook_badge(root, name) = str->attach_notebook_badge(root, name, str)

function attach_notebook_badge(root, name, str)
    mybinder_badge_url = "https://mybinder.org/badge_logo.svg"
    nbviewer_badge_url = "https://img.shields.io/badge/show-nbviewer-579ACA.svg"
    mybinder = "[![]($mybinder_badge_url)](@__BINDER_ROOT_URL__/generated/$root/$name/main.ipynb)"
    nbviewer = "[![]($nbviewer_badge_url)](@__NBVIEWER_ROOT_URL__/generated/$root/$name/main.ipynb)"

    markdown_only(x) = "#md # " * x
    return join(map(markdown_only, (mybinder, nbviewer)), "\n") * "\n\n" * str
end

function build_tutorial(root, name)
    generated_path = joinpath("generated", root, name)
    generated_abspath = joinpath(@__DIR__, "src", generated_path)
    source_dir = joinpath(root, name)
    source_path = joinpath(source_dir, "main.jl")
    Literate.markdown(source_path, generated_abspath; execute=true, name="index", preprocess = attach_notebook_badge(root, name))
    Literate.notebook(source_path, generated_abspath; execute=false, name="main")
    Literate.script(source_path, generated_abspath; execute=false, name="main")
    # copy other things
    for each in readdir(source_dir)
        if each != "main.jl"
            cp(joinpath(source_dir, each), joinpath(generated_abspath, each), force=true)
        end
    end
    return joinpath(generated_path, "index.md")
end

function build(root)
    tutorials = readdir(root)
    pages = String[]
    for each in tutorials
        push!(pages, build_tutorial(root, each))
    end
    return pages
end

#######################################

const PAGES = [
    "Home" => "index.md",
    "Examples" => build("examples"),
]

function make(;depoly=("deploy" in ARGS), skiplinks=!depoly)
    makedocs(
        format = Documenter.HTML(
            prettyurls = depoly,
            canonical = depoly ? "https://tutorials.yaoquantum.org/" : nothing,
            assets = [
                "assets/main.css",
                asset("https://yaoquantum.org/assets/main.css"),
                asset("http://yaoquantum.org/favicon.ico"),
                asset("https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css"),
                ],
            ),
        clean = false,
        sitename = raw"Tutorial|Yao",
        linkcheck = skiplinks,
        pages = PAGES
    )

    if depoly
        deploydocs(
            repo = "github.com/QuantumBFS/tutorials.git",
            target = "build",
        )
    end
end

function scan_files!(dw::SimpleWatcher)
    for (root, _, files) in walkdir("examples"), file in files
        push!(dw.watchedfiles, WatchedFile(joinpath(root, file)))
    end

    for (root, _, files) in walkdir("src"), file in files
        if occursin("generated", root)
            continue
        else
            push!(dw.watchedfiles, WatchedFile(joinpath(root, file)))
        end
    end
end

function update_callback(fp::AbstractString)
    if splitext(fp)[2] == ".md"
        make()
    elseif splitext(fp)[2] == ".jl"
        build_tutorial("examples", splitpath(fp)[2])
        make()
    end
    file_changed_callback(fp)
    return nothing
end

function serve(verbose=false)
    watcher = SimpleWatcher()
    scan_files!(watcher)
    set_callback!(watcher, update_callback)
    make()
    LiveServer.serve(watcher, dir="build", verbose=verbose)
    return nothing
end

if "serve" in ARGS || "s" in ARGS
    serve()
else
    make()
end
