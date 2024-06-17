include("GBD.jl")
include("utils.jl")
include("system_visualization.jl")
include("recovery.jl")

function main()
    number_nodes = 4
    number_nodes, total_cpus_clocks, _, _, adjacency_matrix, total_throughput = physical_substrate(number_nodes)
    number_slices = 8
    number_VNFs = 6
    number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, _, β = slice_instantiation(number_slices, number_VNFs)
    nodes_state, recovery_resources, node_recovery_requirements = recovery(number_nodes)
    VNFs_placements = []
    Virtual_links = []
    Clocks = []
    Throughput = []
    Failed_nodes = []
    Objective_values = []
    for number_failed_nodes in 0: number_nodes - 1
        println("Number of Failed Nodes $(number_failed_nodes)")
        failed_nodes = []
        nodes_state_copy = copy(nodes_state)
        if number_failed_nodes != 0
            failed_nodes = shuffle(1: number_nodes)[1: number_failed_nodes]    
            for failed_node in failed_nodes
                nodes_state_copy[failed_node] = 0
            end
        end
        distribution = virtual_nodes_distribution(number_VNFs, number_nodes, number_failed_nodes)
        objective_value, vnf_placement, virtual_link, clocks, throughput = GBD(number_slices, number_nodes, nodes_state_copy, total_cpus_clocks, adjacency_matrix, total_throughput, 
        number_VNFs, number_cycles, traffic, distribution, β, number_failed_nodes, recovery_resources, node_recovery_requirements)
        push!(VNFs_placements, vnf_placement)
        push!(Virtual_links, virtual_link)
        push!(Clocks, clocks)
        push!(Throughput, throughput)
        push!(Failed_nodes, failed_nodes)
        push!(Objective_values, objective_value)
        # println(total_cpus_clocks_copy)
        # display_solution(vnf_placement, virtual_link)
        # println("slices deployed: $(slices_deployed)")
    end
    system_visualization(total_cpus_clocks, Clocks, VNFs_placements, Throughput, Virtual_links, number_uRLLC, number_eMBB, number_mMTC, Failed_nodes, number_cycles, traffic, Objective_values)
    # data = Dict(
    # "total_cpus_clocks" => total_cpus_clocks,
    # "number_cycles" => number_cycles, 
    # "clocks" => Clocks, 
    # "vnf_placement" => VNFs_placements,
    # "number_uRLLC" => number_uRLLC,
    # "number_eMBB" => number_eMBB,
    # "number_mMTC" => number_mMTC,
    # "delay_tolerance" => delay_tolerance, 
    # "total_throughput" => total_throughput,
    # "throughput" => Throughput,
    # "virtual_link" => Virtual_links,
    # "failed_nodes" => Failed_nodes,
    # "objective_value" => objective_value,
    # )
    # save_results(data)
end

main()