using Test
using YaoToEinsum, YaoToEinsum.YaoBlocks

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
        @test isfile(joinpath(folder, "label_to_qubit.json"))
        
        loaded = load_tensor_network(folder)
        @test length(loaded.tensors) == length(network.tensors)
        @test loaded.label_to_qubit == network.label_to_qubit
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
    
    @testset "Label to qubit mapping" begin
        # Test that label to qubit mapping is tracked during circuit mapping
        simple_circuit = chain(2, put(1=>X), put(2=>Y))
        simple_network = yao2einsum(simple_circuit)
        
        @test isa(simple_network.label_to_qubit, Dict{Int, Int})
        
        # Test that initial qubits are mapped correctly
        @test simple_network.label_to_qubit[1] == 1  # label 1 -> qubit 1
        @test simple_network.label_to_qubit[2] == 2  # label 2 -> qubit 2
        
        # Test density matrix mode with dual labels
        dm_network = yao2einsum(simple_circuit; mode=:density_matrix)
        @test haskey(dm_network.label_to_qubit, -1)  # dual label exists
        @test haskey(dm_network.label_to_qubit, -2)  # dual label exists
        @test dm_network.label_to_qubit[-1] == -1    # dual qubit 1
        @test dm_network.label_to_qubit[-2] == -2    # dual qubit 2
    end
    
    @testset "Error handling" begin
        @test_throws SystemError load_tensor_network("nonexistent_folder")
    end
end 