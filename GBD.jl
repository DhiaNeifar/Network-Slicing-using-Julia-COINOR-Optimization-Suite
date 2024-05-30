include("find_v0.jl")
include("physical_substrate.jl")
include("slice_instantiation.jl")
include("utils.jl")
include("primal_problem.jl")
include("master_problem.jl")
include("utils.jl")

function compute_objective(number_slices, number_nodes, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, VNFs_placements, Virtual_links, clocks, throughput, slices_deployed, λ)
    objective_value = sum((sum(clocks[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
    sum(throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)) + slices_deployed[s] for s in 1: number_slices)
    println("Objective function master_problem: $(objective_value)")
    objective_value2 = sum(sum(clocks[s, k] + throughput[s, k] for k in 1: number_VNFs - 1) + slices_deployed[s]  for s in 1: number_slices)
    println("Objective function master_problem: $(objective_value2)")
end


function main()
    number_node = 15
    number_nodes, total_cpus_clocks, _, _, adjacency_matrix, total_throughput = physical_substrate(number_node)
    number_slices = 15
    number_VNFs = 5
    number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance = slice_instantiation(number_slices)
    println(number_uRLLC)
    println(number_eMBB)
    println(number_mMTC)
    vnf_placement, virtual_link, clocks, throughput, slices_deployed = GBD(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    # println(clocks)
    # println(throughput)
    println(slices_deployed)
    data = Dict(
    "total_cpus_clocks" => total_cpus_clocks,
    "number_cycles" => number_cycles, 
    "clocks" => clocks, 
    "vnf_placement" => vnf_placement,
    "traffic" => traffic,
    "total_throughput" => total_throughput,
    "throughput" => throughput,
    "virtual_link" => virtual_link,)
    save_results(data)
end

function GBD(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    
    # Initialization
    epsilon = 1e-3
    vnf_placement, virtual_link = find_v0(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance)
    println("Initial Guess")
    # display_solution(vnf_placement, virtual_link)
    num_iter = 2
    UBD = Inf
    LBD = -Inf
    VNFs_placements = []
    Virtual_Links = []
    Clocks = []
    Throughputs = []
    Slices_deployed = []
    lambdas = []
    mus = []
    best_vnf_placement = NaN
    best_virtual_link = NaN
    best_clocks = NaN
    best_slices_deployed = NaN
    best_throughput = NaN
    for iter in 1: num_iter
        objective_value, clocks, throughput, slices_deployed, λ = primal_problem(number_slices, number_nodes, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, vnf_placement, virtual_link)
        # println(λ)
        push!(Clocks, clocks)
        push!(Throughputs, throughput)
        push!(Slices_deployed, slices_deployed)
        push!(lambdas, λ)
        # println("Objective function primal_problem: $(objective_value)")
        if abs(objective_value) < abs(UBD)
            UBD = objective_value
            best_vnf_placement = vnf_placement
            best_virtual_link = virtual_link
            best_clocks = clocks
            best_slices_deployed = slices_deployed
            best_throughput = throughput
        end
        if abs(UBD - LBD) < epsilon
            println("Convergea 1")
            print_iteration(iter, UBD, LBD)
            return best_vnf_placement, best_virtual_link, best_clocks, best_throughput, best_slices_deployed
        end
        # compute_objective(number_slices, number_nodes, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, best_vnf_placement, best_virtual_link, best_clocks, best_throughput, best_slices_deployed, λ)
        vnf_placement, virtual_link, mu = master_problem(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, Clocks, Throughputs, Slices_deployed, lambdas)
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
            return best_vnf_placement, best_virtual_link, best_cycles, best_throughput, best_slices_deployed
        end
        print_iteration(iter, UBD, LBD)
    end
    return best_vnf_placement, best_virtual_link, best_clocks, best_throughput, best_slices_deployed
end

main()
