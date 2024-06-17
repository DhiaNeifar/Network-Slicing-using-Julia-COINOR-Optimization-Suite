include("find_v0.jl")
include("physical_substrate.jl")
include("slice_instantiation.jl")
include("utils.jl")
include("primal_problem.jl")
include("master_problem.jl")
include("utils.jl")


function GBD(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, distribution, β, recovery_resources, node_recovery_requirements)
    
    # Initialization
    epsilon = 1e-3
    objective_value, vnf_placement, virtual_link = find_v0(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, distribution, β)
    # display_solution(vnf_placement, virtual_link)
    num_iter = 100
    UBD = Inf
    LBD = -Inf
    VNFs_placements = []
    Virtual_Links = []
    Clocks = []
    Throughputs = []
    lambdas = []
    mus = []
    best_vnf_placement = NaN
    best_virtual_link = NaN
    best_clocks = NaN
    best_throughput = NaN
    best_objective_value = objective_value
    # println("Initial Guess")
    # display_solution(vnf_placement, virtual_link)
    for iter in 1: num_iter
        objective_value, clocks, throughput, λ = primal_problem(number_slices, number_nodes, nodes_state, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, vnf_placement, virtual_link, β)
        push!(Clocks, clocks)
        push!(Throughputs, throughput)
        push!(lambdas, λ)
        if objective_value < UBD
            UBD = objective_value
            best_vnf_placement = vnf_placement
            best_virtual_link = virtual_link
            best_clocks = clocks
            best_throughput = throughput
            best_objective_value = objective_value
        end
        if abs(UBD - LBD) < epsilon || UBD < LBD
            print_iteration(iter, UBD, LBD)
            return best_objective_value, best_vnf_placement, best_virtual_link, best_clocks, best_throughput
        end
        vnf_placement, virtual_link, mu = master_problem(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, Clocks, Throughputs, lambdas, distribution, β)
        best_vnf_placement, best_virtual_link = vnf_placement, virtual_link
        push!(VNFs_placements, vnf_placement)
        push!(Virtual_Links, virtual_link)
        push!(mus, mu)
        if mu > LBD
            LBD = mu
            best_objective_value = mu
        end
        if abs(UBD - LBD) < epsilon || UBD < LBD
            print_iteration(iter, UBD, LBD)
            return best_objective_value, best_vnf_placement, best_virtual_link, best_clocks, best_throughput
        end
        print_iteration(iter, UBD, LBD)
    end
    return best_objective_value, best_vnf_placement, best_virtual_link, best_clocks, best_throughput
end

# main()
