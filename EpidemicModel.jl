using Random

function EpidemicModel(total_number_centers, edges_adjacency_matrix; spread=0.5)
    total_number_centers -= 1
    edges_adjacency_matrix = edges_adjacency_matrix[1: end - 1, 1: end - 1]
    initial_center = rand(0: total_number_centers - 1)
    failed_centers = zeros(Bool, total_number_centers)
    failed_centers[initial_center + 1] = true
    Rounds = Vector{Vector{Int}}()
    push!(Rounds, [])
    push!(Rounds, [initial_center])
    while sum(failed_centers) != length(failed_centers)
        Round = Int[]
        for (center, state) in enumerate(failed_centers)
            if state
                for neighbor in 0:total_number_centers-1
                    if neighbor != center - 1 && edges_adjacency_matrix[center, neighbor + 1] != 0 && !failed_centers[neighbor + 1] && rand() < spread
                        push!(Round, neighbor)
                        failed_centers[neighbor + 1] = true
                    end
                end
            end
        end
        push!(Rounds, Round)
    end
    return Rounds
end

