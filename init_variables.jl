include("physical_substrate.jl")
include("slice_instantiation.jl")
include("recovery_resources.jl")


function init_variables(number_nodes, number_slices, number_VNFs)
    number_nodes, total_cpus_clocks, longitude, latitude, adjacency_matrix, total_throughput = physical_substrate(number_nodes)
    number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance, β = slice_instantiation(number_slices, number_VNFs)
    nodes_state, recovery_resources, node_recovery_requirements = recovery_resources(number_nodes)

    substraste = (longitude, latitude, adjacency_matrix)
    substrate_resources = (total_cpus_clocks, total_throughput)
    slices = (number_uRLLC, number_eMBB, number_mMTC)
    slices_requirements = (number_cycles, traffic, delay_tolerance, β)
    recovery_req = (nodes_state, recovery_resources, node_recovery_requirements)
    return substraste, substrate_resources, slices, slices_requirements, recovery_req
end

init_variables(4, 4, 4)

