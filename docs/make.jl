using Documenter
using Yao
using Yao: YaoBlocks, YaoArrayRegister, YaoBase, YaoSym
using YaoBase: BitBasis
using YaoBlocks: AD
using YaoBlocks: Optimise
using Documenter.Writers.HTMLWriter
using Documenter.Utilities.DOM
using Documenter.Utilities.DOM: Tag, @tags
#Venerable Inventor :)

download("yaoquantum.org/assets/logo-light.png", "docs/src/assets/logo.png")

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
            "assets/themes/indigo.css",
            asset("https://yaoquantum.org/assets/favicon-light.ico", class = :ico),
        ],
    ),
    doctest = ("doctest=true" in ARGS),
    clean = false,
    sitename = "Documentation | Yao",
    linkcheck = !("skiplinks" in ARGS),
    pages = PAGES,
)

x = []
for (root, dirs, files) in walkdir("docs/build")
    global x = [x; joinpath.(root, files)] # files is a Vector{String}, can be empty
end

for i in x
    if (endswith(i, ".html"))
        y = read(i, String)
        y = replace(
            y,
            """<body><div id="documenter">""" =>
                """<body><div id="documenter"><div class="js-toc" style="right: 0;height: 0px;min-width: 25rem;z-index: 10;display: block;position: fixed; top: 0"></div>""",
        )
        y = replace(
            y,
            """</head>""" =>
                """<link href="https://cdnjs.cloudflare.com/ajax/libs/tocbot/4.11.1/tocbot.css" rel="stylesheet" type="text/css"/><style> .toc-list { padding-left: 20px; } @media only screen and (min-width: 1841px) { .docs-main { margin-left: 40rem !important } } @media only screen and (max-width: 1589px) { .js-toc { display: none !important; } } </style></head>""",
        )
        y = replace(
            y,
            """</body>""" =>
                """<script src="https://cdnjs.cloudflare.com/ajax/libs/tocbot/4.11.1/tocbot.min.js"></script><script>
                       tocbot.init({
                         // Where to render the table of contents.
                         tocSelector: '.js-toc',
                         // Where to grab the headings to build the table of contents.
                         contentSelector: '.js-toc-content',
                         // Which headings to grab inside of the contentSelector element.
                         headingSelector: 'h1, h2, h3, h4',
                         // For headings inside relative or absolute positioned containers within content.
                         hasInnerContainers: false,
                  orderedList: false,
                       });
                       </script></body>""",
        )

        y = replace(
            y,
            """<div class="docs-main">""" =>
                """<div class="js-toc-content docs-main">""",
        )
        f = open(i, "w")
        write(f, y)
        close(f)
    end
end

deploydocs(repo = "github.com/VarLad/Yao.jl.git", target = "build")
