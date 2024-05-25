include("find_v0.jl")
include("physical_substrate.jl")
include("slice_instantiation.jl")
include("utils.jl")
include("primal.jl")
include("master_problem.jl")

function main()
    number_node = 8
    number_nodes, total_cpus_clocks, longitude, latitude, adjacency_matrix, total_throughput = physical_substrate(number_node)
    number_slices = 5
    number_VNFs = 6
    number_cycles, traffic, delay_tolerance = slice_instantiation(number_slices, number_VNFs)
    # println("total_cpus_clocks", total_cpus_clocks)
    # println("total_throughput", total_throughput)
    # println("number_cycles", number_cycles)
    # println("traffic", traffic)
    # println("delay_tolerance", delay_tolerance)
    vnf_placement, virtual_link, cycles, throughput = GBD(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    
    
    # display_solution(VNFs_placements, Virtual_Links)
    # println(Cycles)
    # println(Throughputs)
end
function compute_objective(VNFs_placements, Virtual_links, cycles, throughput, number_cycles, traffic, alpha=0.5)
    number_slices, number_VNFs, number_nodes = size(VNFs_placements)
    println(sum(alpha * (sum(cycles[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
    sum(throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)) + 
    (1 - alpha) * (sum(number_cycles[s, k] / cycles[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
    sum(traffic[s, k] / throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes))
    for s in 1: number_slices))
end
function GBD(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    
    # Initialization
    epsilon = 1e-6
    vnf_placement, virtual_link = find_v0(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    # display_solution(vnf_placement, virtual_link)
    num_iter = 100
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
end

main()
