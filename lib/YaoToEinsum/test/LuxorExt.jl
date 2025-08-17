using YaoToEinsum, Test, YaoToEinsum.OMEinsum, LuxorGraphPlot, YaoToEinsum.YaoBlocks

@testset "Special Tensor Detection" begin
    ext = Base.get_extension(YaoToEinsum, :LuxorExt)

    # Test isdelta function
    @test ext.isdelta([1 0; 0 1]) == true
    @test ext.isdelta([1 0; 1 0]) == false
    @test ext.isdelta(reshape([1, 0, 0, 1], 2, 2)) == true
    @test ext.isdelta(reshape([1, 0, 0, 0, 0, 0, 0, 1], 2, 2, 2)) == true
    @test ext.isdelta(reshape([1, 1, 0, 0, 0, 1, 0, 0], 2, 2, 2)) == false
    @test ext.isdelta([2, 3]) == false  # not square
    
    # Test isxor function
    xor_2d = zeros(2, 2)
    xor_2d[1, 1] = 1   # even number of 2's
    xor_2d[2, 2] = 1   # even number of 2's
    xor_2d[1, 2] = 0  # odd number of 2's
    xor_2d[2, 1] = 0  # odd number of 2's
    @test ext.isxor(xor_2d) == true
    
    @test ext.isxor([0 1; 1 0]) == false
    @test ext.isxor([0, 1]) == false  # not 2x2x...x2
    @test ext.isxor(ones(3, 3)) == false  # not 2x2x...x2
    
    # Test state vectors
    @test ext.special_tensor_detection([1, 0]) == "0"
    @test ext.special_tensor_detection([0, 1]) == "1"
    @test ext.special_tensor_detection([1, 1]) == "Σ"
    @test ext.special_tensor_detection([1, 1]/sqrt(2)) == "+"
    @test ext.special_tensor_detection([1, -1]/sqrt(2)) == "-"
    
    # Test 2x2 matrices
    @test ext.special_tensor_detection([1 1; 1 -1]/sqrt(2)) == "H"
    @test ext.special_tensor_detection([1 0; 0 1]) == "I"
    @test ext.special_tensor_detection([0 1; 1 0]) == "X"
    @test ext.special_tensor_detection([0 -1im; 1im 0]) == "Y"
    @test ext.special_tensor_detection([1 0; 0 -1]) == "Z"
    @test ext.special_tensor_detection([1 1; 1 1]) == "Σ"
    @test ext.special_tensor_detection([1 0; 0 0]) == "P₀"
    @test ext.special_tensor_detection([0 0; 0 1]) == "P₁"
    @test ext.special_tensor_detection([0 1; 0 0]) == "P₊"
    @test ext.special_tensor_detection([0 0; 1 0]) == "P₋"
    
    # Test constant tensors
    @test ext.special_tensor_detection(fill(2.5, 3, 3)) == "2.5"
    @test ext.special_tensor_detection(fill(0.33, 2, 2, 2)) == "0.33"
    
    # Test diagonal tensors
    @test ext.special_tensor_detection([1 0; 0 1]) == "I"  # Identity is detected as "I", not "δ"
    @test ext.special_tensor_detection(reshape([1, 0, 0, 1], 2, 2)) == "I"
    
    # Test XOR tensors (2x2x...x2 tensors with XOR pattern)
    xor_tensor = zeros(2, 2, 2)
    xor_tensor[1, 1, 1] = xor_tensor[1,2,2] = xor_tensor[2,1,2] = xor_tensor[2,2,1] = 1   # even number of 2's (0)
    @test ext.special_tensor_detection(xor_tensor) == "⊻"
    
    # Test unrecognized tensors
    @test ext.special_tensor_detection([1, 2, 3]) == ""
    @test ext.special_tensor_detection([1 2; 3 4]) == ""
    @test ext.special_tensor_detection(reshape([1, 2, 3, 4, 5, 6, 7, 8], 2, 2, 2)) == ""
end

@testset "Vector Mode" begin
    c = chain(3, put(3, 1=>X), put(3, 2=>Y), put(3, (2, 3)=>SWAP), control(3, 1, 2=>Z))
    initial_state = final_state = Dict(1=>0, 2=>0, 3=>0)
    ext = Base.get_extension(YaoToEinsum, :LuxorExt)
    tn = yao2einsum(c; initial_state, final_state)
    coos, label2coos = ext.assign_coordinates(tn)
    @test coos == [[-0.15, 2.85], [-0.15, 0.85], [-0.15, 1.85], [1.0, 1.0], [1.0, 2.0], [1.0, 2.5], [1.85, 1.85], [1.85, 0.85], [-0.15, 2.85]]
    @test viznet(tn) isa LuxorGraphPlot.Drawing
end

@testset "DensityMatrix Mode and PauliBasisMode" begin
    c = chain(3, put(3, 1=>X), put(3, 2=>Y), control(3, 1, 3=>Z))
    initial_state = final_state = Dict(1=>0, 2=>0, 3=>0)
    ext = Base.get_extension(YaoToEinsum, :LuxorExt)

    tn = yao2einsum(c; initial_state, final_state, mode=DensityMatrixMode())
    @test viznet(tn) isa LuxorGraphPlot.Drawing

    tn = yao2einsum(c; initial_state, observable=put(3, 2=>X), mode=DensityMatrixMode())
    @test viznet(tn) isa LuxorGraphPlot.Drawing

    tn = yao2einsum(c; initial_state, observable=put(3, 2=>X), mode=PauliBasisMode())
    @test viznet(tn) isa LuxorGraphPlot.Drawing
end