using JSON
import FilePathsBase: joinpath, mkdir
using Printf

function save_results(data_tosave)
    curr_path = pwd()  # Get the current working directory
    results_path = joinpath(curr_path, "results")

    # Ensure the directory is created if it doesn't exist
    if !isdir(results_path)
        mkdir(results_path)
    end

    # Calculate new result directory index
    result_index = length(readdir(results_path)) + 1
    result_path = joinpath(results_path, "Test $result_index")

    # Ensure the directory is created if it doesn't exist
    if !isdir(result_path)
        mkdir(result_path)
    end
    # Serialize and save each data item
    for (key, value) in data_tosave
        write(open(joinpath(result_path, "$key.json"), "w"), JSON.json(value))
    end
end


function load_data()
    data = Dict()
    results = joinpath(pwd(), "results")
    test_path = joinpath(results, "Test $(length(readdir(results)))")
    for filename in readdir(test_path)
        json_string = open(joinpath(test_path, filename), "r") do file
            read(file, String)
        end
        data[filename[1: end - 4]] = JSON.parse(json_string)
    end
    return data
end


function display_solution(VNFs_placements, Virtual_links)
    number_slices, number_VNFs, total_number_centers, total_number_centers = size(Virtual_links)
    println("\n")
    println("VNF Placements")
    for s in 1: number_slices
        println("\n")
        println("Slice $(s)")
        for k in 1: number_VNFs + 1
            println("VNF $(k)")
            println(VNFs_placements[s, k, :])
        end
    end
    println("\n")
    println("Virtual Links")
    for s in 1: number_slices
        println("\n")
        println("Slice $(s)")
        for k in 1: number_VNFs
            println("VNF $(k) -> VNF $(k + 1)")
            println(Virtual_links[s, k, :, :])
        end
    end
end

function display_cpu_usage(required_cpus, assigned_cpus)
    required_cpus = permutedims(required_cpus, (2, 1))
    assigned_cpus = permutedims(assigned_cpus, (2, 1))
    number_slices, _= size(assigned_cpus)
    for s in 1: number_slices
        println("\n")
        println("Slice $(s)")
        println("Required ", required_cpus[s, :])
        println("Assigned ", assigned_cpus[s, :])
    end
end

function display_bandwidth_usage(required_cpus, assigned_cpus)
    required_cpus = permutedims(required_cpus, (2, 1))
    assigned_cpus = permutedims(assigned_cpus, (2, 1))
    number_slices, _= size(assigned_cpus)
    for s in 1: number_slices
        println("\n")
        println("Slice $(s)")
        println("Required ", required_cpus[s, :])
        println("Assigned ", assigned_cpus[s, :])
    end
end

function bump(x, z0, z1)
    if x < z0
        return 1
    end
    if z0 <= x < z1
        return 1 / 2 * cos(pi * ((z0 - x)/(z0 - z1)))
    end
    return 0
end

function print_iteration(k, args...)
    f(x) = Printf.@sprintf("%12.4e", x)
    println(lpad(k, 9), " ", join(f.(args), " "))
    return
end

function compute_delay(number_cycles, traffic, VNFs_placements, Virtual_links, clocks, throughput, s)
    _, number_VNFs, number_nodes = size(VNFs_placements)
    delay = 10 ^ -6 * sum(number_cycles[s] / clocks[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
    10 ^ -3 * sum(traffic[s] / throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)
    return delay
end


function virtual_nodes_distribution(number_VNFs, number_nodes, number_failed_nodes)
    available_nodes = number_nodes - number_failed_nodes
    return number_VNFs <= available_nodes ? 1 : ceil(number_VNFs / available_nodes)
end



function Objective_function(s, number_nodes, number_VNFs, number_cycles, traffic, clocks, throughput, VNFs_placements, Virtual_links, β)
    resources_consumed = sum(clocks[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
    sum(throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)

    delay = 10 ^ -6 * sum(number_cycles[s, k] / clocks[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
    10 ^ -3 * sum(traffic[s, k] / throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes) 
return β[s, 1] * resources_consumed + β[s, 2] * delay
end


function master_objective_function(number_slices, number_nodes, nodes_state, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, clocks, throughput, VNFs_placements, Virtual_links, λ, β)
    nodes_resources_constraint = sum(λ[c] * (sum(VNFs_placements[s, k, c] * clocks[s, k] for s in 1: number_slices, k in 1: number_VNFs) - total_cpus_clocks[c] * nodes_state[c]) for c in 1: number_nodes)
    links_resources_constraint = sum(λ[number_nodes * i + j] * (sum(Virtual_links[s, k, i, j] * throughput[s, k] for s in 1: number_slices, k in 1: number_VNFs - 1) - total_throughput[i, j]) for i in 1: number_nodes for j in 1: number_nodes)

    return sum(Objective_function(s, number_nodes, number_VNFs, number_cycles, traffic, clocks, throughput, VNFs_placements, Virtual_links, β) for s in 1: number_slices) - (nodes_resources_constraint + links_resources_constraint) 
end

function recovery_master_objective_function(number_slices, number_nodes, nodes_state, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, clocks, throughput, VNFs_placements, Virtual_links, Recovery_states, λ, β)
    nodes_resources_constraint = sum(λ[c] * (sum(VNFs_placements[s, k, c] * clocks[s, k] for s in 1: number_slices, k in 1: number_VNFs) - total_cpus_clocks[c] * (nodes_state[c] + Recovery_states[c])) for c in 1: number_nodes)
    links_resources_constraint = sum(λ[number_nodes * i + j] * (sum(Virtual_links[s, k, i, j] * throughput[s, k] for s in 1: number_slices, k in 1: number_VNFs - 1) - total_throughput[i, j]) for i in 1: number_nodes for j in 1: number_nodes)

    return sum(Objective_function(s, number_nodes, number_VNFs, number_cycles, traffic, clocks, throughput, VNFs_placements, Virtual_links, β) for s in 1: number_slices) - (nodes_resources_constraint + links_resources_constraint) 
end