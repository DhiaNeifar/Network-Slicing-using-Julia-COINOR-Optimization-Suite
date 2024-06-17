include("find_v0.jl")
include("physical_substrate.jl")
include("slice_instantiation.jl")
include("utils.jl")
include("primal_problem.jl")
include("master_problem.jl")
include("utils.jl")

function main()
    number_node = 15
    number_nodes, total_cpus_clocks, _, _, adjacency_matrix, total_throughput = physical_substrate(number_node)
    number_slices = 15
    number_VNFs = 7
    number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance = slice_instantiation(number_slices)
    # vnf_placement, virtual_link, clocks, throughput = GBD(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    # data = Dict(
    # "total_cpus_clocks" => total_cpus_clocks,
    # "number_cycles" => number_cycles, 
    # "cycles" => cycles, 
    # "vnf_placement" => vnf_placement,
    # "traffic" => traffic,
    # "total_throughput" => total_throughput,
    # "throughput" => throughput,
    # "virtual_link" => virtual_link,)
    # save_results(data)
end

function GBD(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, number_failed_nodes, β)
    
    # Initialization
    epsilon = 1e-3
    objective_value, vnf_placement, virtual_link = find_v0(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, number_failed_nodes, β)
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
        objective_value, clocks, throughput, λ = primal_problem(number_slices, number_nodes, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, vnf_placement, virtual_link, β)
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
        vnf_placement, virtual_link, mu = master_problem(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, Clocks, Throughputs, lambdas, number_failed_nodes, β)
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
