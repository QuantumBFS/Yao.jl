JL = julia --project

init:
	echo "Initializing YaoAPI"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoAPI\"); Pkg.instantiate()"; \
	echo "Initializing YaoArrayRegister"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoArrayRegister\"); Pkg.develop(path=\"lib/YaoAPI\"); Pkg.instantiate()"; \
	echo "Initializing YaoBlocks"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoBlocks\"); Pkg.develop([Pkg.PackageSpec(path=\"lib/YaoAPI\"), Pkg.PackageSpec(path=\"lib/YaoArrayRegister\")]); Pkg.instantiate()"; \
	echo "Initializing YaoSym"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoSym\"); Pkg.develop([Pkg.PackageSpec(path=\"lib/YaoArrayRegister\"), Pkg.PackageSpec(path=\"lib/YaoBlocks\")]); Pkg.instantiate()"; \
	echo "Initializing YaoPlots"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoPlots\"); Pkg.develop([Pkg.PackageSpec(path=\"lib/YaoBlocks\"), Pkg.PackageSpec(path=\"lib/YaoArrayRegister\")]); Pkg.instantiate()"; \
	echo "Initializing YaoToEinsum"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoToEinsum\"); Pkg.develop([Pkg.PackageSpec(path=\"lib/YaoBlocks\")]); Pkg.instantiate()"; \
	echo "Initializing Yao"; \
	$(JL) -e "using Pkg; Pkg.activate(\".\"); Pkg.develop([Pkg.PackageSpec(path=\"lib/YaoAPI\"), Pkg.PackageSpec(path=\"lib/YaoArrayRegister\"), Pkg.PackageSpec(path=\"lib/YaoBlocks\"), Pkg.PackageSpec(path=\"lib/YaoSym\"), Pkg.PackageSpec(path=\"lib/YaoPlots\"), Pkg.PackageSpec(path=\"lib/YaoToEinsum\")]); Pkg.instantiate()"; \
	echo "Initializing docs"; \
	$(JL) -e "using Pkg; Pkg.activate(\"docs\"); Pkg.develop([Pkg.PackageSpec(path = \"lib/YaoAPI\"), Pkg.PackageSpec(path = \"lib/YaoArrayRegister\"), Pkg.PackageSpec(path = \"lib/YaoBlocks\"), Pkg.PackageSpec(path = \"lib/YaoSym\"), Pkg.PackageSpec(path = \"lib/YaoPlots\"), Pkg.PackageSpec(path = \"lib/YaoToEinsum\"), Pkg.PackageSpec(path = \".\")]); Pkg.instantiate()"; \

update:
	echo "Updating YaoAPI"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoAPI\"); Pkg.update()"; \
	echo "Updating YaoArrayRegister"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoArrayRegister\"); Pkg.update()"; \
	echo "Updating YaoBlocks"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoBlocks\"); Pkg.update()"; \
	echo "Updating YaoSym"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoSym\"); Pkg.update()"; \
	echo "Updating YaoPlots"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoPlots\"); Pkg.update()"; \
	echo "Updating YaoToEinsum"; \
	$(JL) -e "using Pkg; Pkg.activate(\"lib/YaoToEinsum\"); Pkg.update()"; \
	echo "Updating Yao"; \
	$(JL) -e "using Pkg; Pkg.activate(\".\"); Pkg.update()"; \
	echo "Updating docs"; \
	$(JL) -e "using Pkg; Pkg.activate(\"docs\"); Pkg.update()"; \

test-CuYao:
	$(JL) -e 'using Pkg; Pkg.activate("ext/CuYao/test"); Pkg.develop(path="."); Pkg.update()'
	$(JL) -e 'using Pkg; Pkg.activate("ext/CuYao/test"); include("ext/CuYao/test/runtests.jl")'

test:
	$(JL) -e "using Pkg; Pkg.test([\"YaoAPI\", \"YaoArrayRegister\", \"YaoBlocks\", \"YaoSym\", \"YaoPlots\", \"Yao\", \"YaoToEinsum\"]; coverage=$${coverage:-false})"

servedocs:
	$(JL) -e 'using Pkg; Pkg.activate("docs"); using LiveServer; servedocs(;skip_dirs=["docs/src/assets", "docs/src/generated"])'

clean:
	rm -rf docs/build
	find . -name "*.cov" -type f -print0 | xargs -0 /bin/rm -f

.PHONY: init test update update-docs servedocs clean test-CuYao
