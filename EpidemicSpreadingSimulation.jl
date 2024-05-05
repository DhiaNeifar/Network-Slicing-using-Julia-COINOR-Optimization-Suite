include("physical_substrate.jl")
include("EpidemicModel.jl")
include("slice_instantiation.jl")
include("network_slicing.jl")
include("utils.jl")

number_node = 4
total_number_centers, total_available_cpus, longitude, latitude, edges_adjacency_matrix, total_available_bandwidth, edges_delay = physical_substrate(number_node)

total_available_cpus_ = copy(total_available_cpus)

Spread = 0.5
Rounds = EpidemicModel(total_number_centers, edges_adjacency_matrix, spread=Spread)
number_slices = 3
number_VNFs = 2

required_cpus, required_bandwidth, delay_tolerance = slice_instantiation(number_slices, number_VNFs)

println("Starting Epidemic Slicing")
println("Rounds = ", Rounds)
failed_centers = Int[]

assigned_cpus_results = Vector{Array{Float32, 2}}()
VNFs_placements_results = Vector{Array{Int, 3}}()
assigned_bandwidth_results = Vector{Array{Float32, 2}}()
Virtual_links_results = Vector{Array{Int, 4}}()

for (round_index, Round) in enumerate(Rounds)
    println("Round ", round_index)
    if !isempty(Round)
        for center in Round
            total_available_cpus[center + 1] = 0
        end
    end
    append!(failed_centers, Round)

    # Embedding
    parameters = (number_slices, total_number_centers, total_available_cpus, edges_adjacency_matrix,
                  total_available_bandwidth, edges_delay, number_VNFs, required_cpus, required_bandwidth,
                  delay_tolerance, failed_centers)

    VNFs_placements, assigned_cpus, Virtual_links, assigned_bandwidth = network_slicing(parameters...)
    push!(assigned_cpus_results, assigned_cpus)
    push!(VNFs_placements_results, VNFs_placements)
    push!(assigned_bandwidth_results, assigned_bandwidth)
    push!(Virtual_links_results, Virtual_links)

end
data = Dict("Rounds" => Rounds, 
"total_available_cpus" => total_available_cpus_,
"required_cpus" => required_cpus, 
"assigned_cpus" => assigned_cpus_results, 
"VNFs_placements" => VNFs_placements_results,
"required_bandwidth" => required_bandwidth,
"assigned_bandwidth" => assigned_bandwidth_results,
"Virtual_links" => Virtual_links_results,)
save_results(data)

