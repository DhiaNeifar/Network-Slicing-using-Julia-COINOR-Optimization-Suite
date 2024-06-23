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
    path = recover_path()
    fig = 0
    # init_variables
    number_nodes, number_slices, number_VNFs = 5, 4, 3
    number_nodes, total_cpus_clocks, _, _, adjacency_matrix, total_throughput = physical_substrate(number_nodes)
    number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, _, β = slice_instantiation(number_slices, number_VNFs)
    nodes_state, nodes_recovery_resources, node_recovery_requirements = recovery_resources(number_nodes)

    # Main Program
    round = 0
    println("Initial total Clocks")
    println(total_cpus_clocks)
    objective_value, vnf_placement, virtual_link, clocks, throughput = GBD(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, β)
    consumed_recovery_resources = 0
    # system_visualization(total_cpus_clocks, nodes_state, clocks, vnf_placement, throughput, virtual_link, number_uRLLC, number_eMBB, number_mMTC, [], number_cycles, traffic, [objective_value], consumed_recovery_resources, nodes_recovery_resources, "Initial Embedding", path, fig)
    fig += 1
    while nodes_recovery_resources > 0
        round += 1
        println("Round $(round)")
        failed_nodes, failed_nodes_state = init_failed_nodes(number_nodes)
        for (index, failed_node) in enumerate(failed_nodes)
            if nodes_state[failed_node] - failed_nodes_state[index] < 0
                nodes_state[failed_node] = 0.01
                nodes_recovery_resources -= node_recovery_requirements[failed_node] * 0.01
            else
                nodes_state[failed_node] = nodes_state[failed_node] - failed_nodes_state[index]
            end
        end
        objective_value, clocks, throughput = elastic_resource_management(number_slices, number_nodes, nodes_state, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, vnf_placement, virtual_link, β)
        # system_visualization(total_cpus_clocks, nodes_state, clocks, vnf_placement, throughput, virtual_link, number_uRLLC, number_eMBB, number_mMTC, failed_nodes, number_cycles, traffic, [objective_value], consumed_recovery_resources, nodes_recovery_resources, "Updating to failure $(round)", path, fig)
        fig += 1
        objective_value, vnf_placement, virtual_link, recovery_states, clocks, throughput = RECOVERY_GBD(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, β, nodes_recovery_resources, node_recovery_requirements)
        nodes_state = nodes_state .+ recovery_states
        nodes_recovery_resources -= sum(node_recovery_requirements[c] * recovery_states[c] for c in 1: number_nodes)
        verify_recovery(total_cpus_clocks, vnf_placement, clocks, nodes_state, recovery_states, nodes_recovery_resources, node_recovery_requirements)
        # system_visualization(total_cpus_clocks, nodes_state, clocks, vnf_placement, throughput, virtual_link, number_uRLLC, number_eMBB, number_mMTC, failed_nodes, number_cycles, traffic, [objective_value], consumed_recovery_resources, nodes_recovery_resources, "Recovery", path, fig)
        fig += 1
    end



end
main()