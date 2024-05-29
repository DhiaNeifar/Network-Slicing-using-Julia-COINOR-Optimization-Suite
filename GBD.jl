include("find_v0.jl")
include("physical_substrate.jl")
include("slice_instantiation.jl")
include("utils.jl")
include("primal_problem.jl")
include("master_problem.jl")
include("utils.jl")

function main()
    number_node = 4
    number_nodes, total_cpus_clocks, _, _, adjacency_matrix, total_throughput = physical_substrate(number_node)
    number_slices = 1
    number_VNFs = 3
    number_cycles, traffic, delay_tolerance = slice_instantiation(number_slices, number_VNFs)
    vnf_placements, virtual_links, Cycles, throughputs = [], [], [], []
    for index in 1: 10: 101
        println("index $(index)")
        vnf_placement, virtual_link, cycles, throughput = GBD(number_slices, number_nodes, total_cpus_clocks * index / 100, adjacency_matrix, total_throughput * index / 100, number_VNFs, number_cycles, traffic, delay_tolerance)
        push!(vnf_placements, vnf_placement)
        push!(virtual_links, virtual_link)
        push!(Cycles, cycles)
        push!(throughputs, throughput)
        display_solution(vnf_placement, virtual_link)
        println(cycles)
        println(throughput)
    end

    # vnf_placement, virtual_link, cycles, throughput = GBD(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    data = Dict(
    "total_cpus_clocks" => total_cpus_clocks,
    "number_cycles" => number_cycles, 
    "cycles" => Cycles, 
    "vnf_placement" => vnf_placements,
    "traffic" => traffic,
    "total_throughput" => total_throughput,
    "throughput" => throughputs,
    "virtual_link" => virtual_links,)
    save_results(data)
end

function GBD(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    
    # Initialization
    epsilon = 1e-3
    vnf_placement, virtual_link = find_v0(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    println("Initial Guess")
    # display_solution(vnf_placement, virtual_link)
    num_iter = 10
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
    for iter in 1: num_iter
        objective_value, cycles, throughput, λ = primal_problem(number_slices, number_nodes, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, vnf_placement, virtual_link)
        push!(Cycles, cycles)
        push!(Throughputs, throughput)
        push!(lambdas, λ)
        if abs(objective_value) < abs(UBD)
            UBD = objective_value
            best_vnf_placement = vnf_placement
            best_virtual_link = virtual_link
            best_cycles = cycles
            best_throughput = throughput
        end
        if abs(UBD - LBD) < epsilon
            println("Convergea 1")
            print_iteration(iter, UBD, LBD)
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
        if abs(UBD - LBD) < epsilon
            println("Convergea 2")
            print_iteration(iter, UBD, LBD)
            return best_vnf_placement, best_virtual_link, best_cycles, best_throughput
        end
        print_iteration(iter, UBD, LBD)
    end
    return best_vnf_placement, best_virtual_link, best_cycles, best_throughput
end

main()
