using Test, YaoBase

@test_throws ErrorException @assert_locs_inbounds 4 (1, 2, 3, 4, 5)
@test_throws ErrorException @assert_locs_inbounds 4 collect(1:5)

@test_throws LocationConflictError @assert_locs_safe 4 (1, 2, 2, 1)
@test_throws LocationConflictError @assert_locs_safe 4 [1, 3, 2, 2]
