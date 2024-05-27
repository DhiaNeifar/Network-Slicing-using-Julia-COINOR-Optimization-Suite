include("find_v0.jl")
include("physical_substrate.jl")
include("slice_instantiation.jl")
include("utils.jl")
include("primal.jl")
include("master_problem.jl")
include("utils.jl")

function GBD(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    
    # Initialization
    epsilon = 1e-3
    vnf_placement, virtual_link = find_v0(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    # display_solution(vnf_placement, virtual_link)
    num_iter = 2
    UBD = Inf
    LBD = -Inf
    VNFs_placements = []
    Virtual_Links = []
    Cycles = []
    Throughputs = []
    lambdas = []
    mus = []
    best_vnf_placement = NaN
    best_virtual_link = NaN
    best_cycles = NaN
    best_throughput = NaN
    println("Initial Guess")
    # display_solution(vnf_placement, virtual_link)
    for iter in 1: num_iter
        objective_value, cycles, throughput, λ = primal_problem(number_slices, number_nodes, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, vnf_placement, virtual_link)
        push!(Cycles, cycles)
        push!(Throughputs, throughput)
        push!(lambdas, λ)
        if objective_value < UBD
            UBD = objective_value
            best_vnf_placement = vnf_placement
            best_virtual_link = virtual_link
            best_cycles = cycles
            best_throughput = throughput
        end
        if UBD - LBD < epsilon
            println("Convergea 1")
            return best_vnf_placement, best_virtual_link, best_cycles, best_throughput
        end
        vnf_placement, virtual_link, mu = master_problem(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, Cycles, Throughputs, lambdas)
        best_vnf_placement, best_virtual_link = vnf_placement, virtual_link
        push!(VNFs_placements, vnf_placement)
        push!(Virtual_Links, virtual_link)
        push!(mus, mu)
        if mu > LBD
            LBD = mu
        end
        if UBD - LBD < epsilon
            println("Convergea 2")
            return best_vnf_placement, best_virtual_link, best_cycles, best_throughput
        end
        print_iteration(iter, UBD, LBD)
    end
    return best_vnf_placement, best_virtual_link, best_cycles, best_throughput
end

function main()
    number_node = 4
    number_nodes, total_cpus_clocks, _, _, adjacency_matrix, total_throughput = physical_substrate(number_node)
    number_slices = 2
    number_VNFs = 3
    number_cycles, traffic, delay_tolerance = slice_instantiation(number_slices, number_VNFs)
    vnf_placement, virtual_link, cycles, throughput = GBD(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    data = Dict(
    "total_cpus_clocks" => total_cpus_clocks,
    "number_cycles" => number_cycles, 
    "cycles" => cycles, 
    "vnf_placement" => vnf_placement,
    "traffic" => traffic,
    "total_throughput" => total_throughput,
    "throughput" => throughput,
    "virtual_link" => virtual_link,)
    save_results(data)
end

main()
