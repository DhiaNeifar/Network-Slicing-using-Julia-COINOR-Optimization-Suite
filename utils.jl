using Serialization
import FilePathsBase: joinpath, mkdir


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
        serialize(open(joinpath(result_path, "$key.jls"), "w"), value)
    end
end


function load_data()
    data = Dict()
    results = joinpath(pwd(), "results")
    test_path = joinpath(results, "Test $(length(readdir(results)))")
    for filename in readdir(test_path)
        data[filename[1: end - 4]] = deserialize(open(joinpath(test_path, filename), "r"))
    end
    return data
end


function display_solution(VNFs_placements)
    number_slices, number_VNFs, _ = size(VNFs_placements)
    for s in 1: number_slices
        println("\n")
        println("Slice $(s)")
        for k in 1: number_VNFs
            println("VNF $(k)")
            println(VNFs_placements[s, k, :])
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
