include("find_v0_recovery.jl")
include("physical_substrate.jl")
include("slice_instantiation.jl")
include("utils.jl")
include("primal_problem_recovery.jl")
include("master_problem_recovery.jl")
include("utils.jl")


function RECOVERY_GBD(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, β, nodes_recovery_resources, node_recovery_requirements)
    
    # Initialization
    epsilon = 1e-3
    # distribution = virtual_nodes_distribution(number_VNFs, number_nodes, 0)
    objective_value, vnf_placement, virtual_link, recovery_states = find_v0_recovery(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, β, nodes_recovery_resources, node_recovery_requirements)
    # display_solution(vnf_placement, virtual_link)
    num_iter = 100
    UBD = Inf
    LBD = -Inf
    VNFs_placements = []
    Virtual_Links = []
    Recovery_states = []
    Clocks = []
    Throughputs = []
    lambdas = []
    mus = []
    best_vnf_placement = NaN
    best_virtual_link = NaN
    best_recovery_states = NaN
    best_clocks = NaN
    best_throughput = NaN
    best_objective_value = objective_value
    # println("Initial Guess")
    # display_solution(vnf_placement, virtual_link)
    for iter in 1: num_iter
        objective_value, clocks, throughput, λ = primal_problem_recovery(number_slices, number_nodes, nodes_state, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, vnf_placement, virtual_link, recovery_states, β)
        push!(Clocks, clocks)
        push!(Throughputs, throughput)
        push!(lambdas, λ)
        if objective_value < UBD
            UBD = objective_value
            best_vnf_placement = vnf_placement
            best_virtual_link = virtual_link
            best_recovery_states = recovery_states
            best_clocks = clocks
            best_throughput = throughput
            best_objective_value = objective_value
        end
        if abs(UBD - LBD) < epsilon || UBD < LBD
            print_iteration(iter, UBD, LBD)
            return best_objective_value, best_vnf_placement, best_virtual_link, best_recovery_states, best_clocks, best_throughput
        end
        vnf_placement, virtual_link, recovery_states, mu = master_problem_recovery(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, Clocks, Throughputs, lambdas, β, nodes_recovery_resources, node_recovery_requirements)
        best_vnf_placement, best_virtual_link, best_recovery_states = vnf_placement, virtual_link, recovery_states
        push!(VNFs_placements, vnf_placement)
        push!(Virtual_Links, virtual_link)
        push!(Recovery_states, recovery_states)
        push!(mus, mu)
        if mu > LBD
            LBD = mu
            best_objective_value = mu
        end
        if abs(UBD - LBD) < epsilon || UBD < LBD
            print_iteration(iter, UBD, LBD)
            return best_objective_value, best_vnf_placement, best_virtual_link, best_recovery_states, best_clocks, best_throughput
        end
        print_iteration(iter, UBD, LBD)
    end
    return best_objective_value, best_vnf_placement, best_virtual_link, best_recovery_states, best_clocks, best_throughput
end

# main()
