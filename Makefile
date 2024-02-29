JL = julia --project

default: init test

init:
	$(JL) -e 'using Pkg; Pkg.develop([Pkg.PackageSpec(path = joinpath("lib", pkg)) for pkg in ["YaoArrayRegister", "YaoBlocks", "YaoSym", "YaoPlots", "YaoAPI"]]); Pkg.precompile()'
init-docs:
	$(JL) -e 'using Pkg; Pkg.activate("docs"); Pkg.develop([Pkg.PackageSpec(path = joinpath("lib", pkg)) for pkg in ["YaoArrayRegister", "YaoBlocks", "YaoSym", "YaoPlots", "YaoAPI"]]); Pkg.precompile()'

update:
	$(JL) -e 'using Pkg; Pkg.update(); Pkg.precompile()'
update-docs:
	$(JL) -e 'using Pkg; Pkg.activate("docs"); Pkg.update(); Pkg.precompile()'

test-Yao:
	$(JL) -e 'using Pkg; Pkg.test("Yao")'
test-CuYao:
	$(JL) -e 'using Pkg; Pkg.activate("ext/CuYao/test"); Pkg.develop(path="."); Pkg.update()'
	$(JL) -e 'using Pkg; Pkg.activate("ext/CuYao/test"); include("ext/CuYao/test/runtests.jl")'

test-%:
	$(JL) -e 'using Pkg; Pkg.test("$*")'

test:
	$(JL) -e 'using Pkg; Pkg.test(["YaoAPI", "YaoArrayRegister", "YaoBlocks", "YaoSym", "YaoPlots", "Yao"])'

coverage:
	$(JL) -e 'using Pkg; Pkg.test(["YaoAPI", "YaoArrayRegister", "YaoBlocks", "YaoSym", "YaoPlots", "Yao"]; coverage=true)'

servedocs:
	$(JL) -e 'using Pkg; Pkg.activate("docs"); using LiveServer; servedocs(;skip_dirs=["docs/src/assets", "docs/src/generated"])'

clean:
	rm -rf docs/build
	find . -name "*.cov" -type f -print0 | xargs -0 /bin/rm -f

.PHONY: init test
