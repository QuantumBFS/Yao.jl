using Test
using Yao
using YaoToEinsum

@testset "File I/O" begin
    # Create test tensor network
    circuit = chain(2, put(1=>X), put(2=>Y), cnot(2, 1))
    network = yao2einsum(circuit; optimizer=TreeSA())
   
    @testset "File operations" begin
        folder = tempdir()
        # Test save/load
        save_tensor_network(network; folder)
        @test isdir(folder)
        @test isfile(joinpath(folder, "code.json"))
        @test isfile(joinpath(folder, "tensors.json"))
        
        loaded = load_tensor_network(folder)
        @test length(loaded.tensors) == length(network.tensors)
    end
    
    @testset "Tensor serialization" begin
        # Test tensor_to_dict and tensor_from_dict
        tensor = rand(ComplexF64, 2, 2)
        dict = YaoToEinsum.tensor_to_dict(tensor)
        @test dict["size"] == (2, 2)
        @test dict["complex"] == true
        
        reconstructed = YaoToEinsum.tensor_from_dict(dict)
        @test size(reconstructed) == size(tensor)
        @test eltype(reconstructed) == eltype(tensor)
        @test reconstructed ≈ tensor
    end
    
    @testset "Error handling" begin
        @test_throws SystemError load_tensor_network("nonexistent_folder")
    end
end 