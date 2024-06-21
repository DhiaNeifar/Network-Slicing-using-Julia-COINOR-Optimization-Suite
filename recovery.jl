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
    number_nodes, number_slices, number_VNFs = 5, 3, 3
    number_nodes, total_cpus_clocks, longitude, latitude, adjacency_matrix, total_throughput = physical_substrate(number_nodes)
    number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance, β = slice_instantiation(number_slices, number_VNFs)
    nodes_state, nodes_recovery_resources, node_recovery_requirements = recovery_resources(number_nodes)

    # Main Program
    round = 0
    objective_value, vnf_placement, virtual_link, clocks, throughput = GBD(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, β)
    # compute_parameters(number_slices, number_nodes, number_VNFs, vnf_placement, virtual_link, clocks, throughput, number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance)
    system_visualization(total_cpus_clocks, nodes_state, clocks, vnf_placement, throughput, virtual_link, number_uRLLC, number_eMBB, number_mMTC, [], number_cycles, traffic, [objective_value])
    while nodes_recovery_resources > 0
        round += 1
        failed_nodes, failed_nodes_state = init_failed_nodes(number_nodes)

        for (index, failed_node) in enumerate(failed_nodes)
            nodes_state[failed_node]  = max(0, nodes_state[failed_node] - failed_nodes_state[index])
        end
        objective_value, clocks, throughput = elastic_resource_management(number_slices, number_nodes, nodes_state, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, vnf_placement, virtual_link, β)
        system_visualization(total_cpus_clocks, nodes_state, clocks, vnf_placement, throughput, virtual_link, number_uRLLC, number_eMBB, number_mMTC, failed_nodes, number_cycles, traffic, [objective_value])
        # compute_parameters(number_slices, number_nodes, number_VNFs, vnf_placement, virtual_link, clocks, throughput, number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance)
        objective_value, vnf_placement, virtual_link, recovery_states, clocks, throughput = RECOVERY_GBD(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, β, nodes_recovery_resources, node_recovery_requirements)
        println(size(virtual_link))
        for c in 1: number_nodes
            nodes_state[c] = nodes_state[c] + recovery_states[c]
            nodes_recovery_resources -= node_recovery_requirements[c] * recovery_states[c]
        end
        
        system_visualization(total_cpus_clocks, nodes_state, clocks, vnf_placement, throughput, virtual_link, number_uRLLC, number_eMBB, number_mMTC, failed_nodes, number_cycles, traffic, [objective_value])
    end



end
main()