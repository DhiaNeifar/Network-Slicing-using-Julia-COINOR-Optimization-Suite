include("physical_substrate.jl")
include("slice_instantiation.jl")
include("recovery_resources.jl")
include("GBD.jl")
include("system_visualization.jl")
include("init_failed_nodes.jl")
include("compute_parameters.jl")
include("elastic_resource_management.jl")
include("RECOVERY_GBD.jl")


function main()
    # init_variables
    number_nodes, number_slices, number_VNFs = 5, 4, 3
    number_nodes, total_cpus_clocks, _, _, adjacency_matrix, total_throughput = physical_substrate(number_nodes)
    number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, _, β = slice_instantiation(number_slices, number_VNFs)
    nodes_state, nodes_recovery_resources, node_recovery_requirements = recovery_resources(number_nodes)

    # Main Program
    round = 0
    objective_value, vnf_placement, virtual_link, clocks, throughput = GBD(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, β)
    # compute_parameters(number_slices, number_nodes, number_VNFs, vnf_placement, virtual_link, clocks, throughput, number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance)
    consumed_recovery_resources = 0
    system_visualization(total_cpus_clocks, nodes_state, clocks, vnf_placement, throughput, virtual_link, number_uRLLC, number_eMBB, number_mMTC, [], number_cycles, traffic, [objective_value], consumed_recovery_resources, nodes_recovery_resources, "Initial Embedding")
    nodes_recovery_resources_copy = nodes_recovery_resources
    println("Initial OV = $(objective_value)")
    while nodes_recovery_resources_copy > 0
        round += 1
        failed_nodes, failed_nodes_state = init_failed_nodes(number_nodes)
        println("Round = $(round)")
        println("Failed nodes = $(failed_nodes)")
        println("nodes_state = $(nodes_state)")
        println("failed_nodes_state = $(failed_nodes_state)")
        for (index, failed_node) in enumerate(failed_nodes)
            nodes_state[failed_node]  = max(0, nodes_state[failed_node] - failed_nodes_state[index])
        end
        println("New nodes state = $(nodes_state)")
        objective_value, clocks, throughput = elastic_resource_management(number_slices, number_nodes, nodes_state, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, vnf_placement, virtual_link, β)
        println("Updated OV = $(objective_value)")
        system_visualization(total_cpus_clocks, nodes_state, clocks, vnf_placement, throughput, virtual_link, number_uRLLC, number_eMBB, number_mMTC, failed_nodes, number_cycles, traffic, [objective_value], consumed_recovery_resources, nodes_recovery_resources, "Updating to failure $(round)")
        # # compute_parameters(number_slices, number_nodes, number_VNFs, vnf_placement, virtual_link, clocks, throughput, number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance)
        objective_value, vnf_placement, virtual_link, recovery_states, clocks, throughput = RECOVERY_GBD(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, β, nodes_recovery_resources_copy, node_recovery_requirements)
        println("Recovered OV = $(objective_value)")
        for c in 1: number_nodes
            nodes_state[c] = nodes_state[c] + recovery_states[c]
            consumed_recovery_resources += node_recovery_requirements[c] * recovery_states[c]
        end
        println("recovery_states = $(recovery_states)")
        println("consumed_recovery_resources = $(consumed_recovery_resources)")
        println("nodes_recovery_resources_copy BEFORE = $(nodes_recovery_resources_copy)")
        nodes_recovery_resources_copy -= consumed_recovery_resources
        println("nodes_recovery_resources_copy AFTER = $(nodes_recovery_resources_copy)")
        # println(nodes_recovery_resources_copy)
        system_visualization(total_cpus_clocks, nodes_state, clocks, vnf_placement, throughput, virtual_link, number_uRLLC, number_eMBB, number_mMTC, failed_nodes, number_cycles, traffic, [objective_value], consumed_recovery_resources, nodes_recovery_resources, "Recovery")
    end



end
main()