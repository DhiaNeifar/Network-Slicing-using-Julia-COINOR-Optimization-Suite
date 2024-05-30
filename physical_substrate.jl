using Random

function physical_substrate(number_nodes)
    total_number_nodes = 15
    adjacency_matrix = zeros(Int, total_number_nodes, total_number_nodes)
    
    total_throughput = zeros(Float64, total_number_nodes, total_number_nodes)

    weak_links = [(1, 2), (1, 4), (1, 5), (1, 11), (2, 3), (2, 6), (2, 11), (3, 4), (3, 5), (3, 11), (3, 14), (3, 15), (4, 5), (4, 15), (6, 14)]
    sup_links = [(1, 9), (2, 8), (6, 7), (7, 8), (7, 9), (7, 10), (7, 13), (7, 14), (8, 9), (9, 10), (9, 12), (10, 12), (10, 13)]


    longitude = [0, 1, -4, -6, -4, 2, 7, 4, 3, 8, -1, 7, 10, -1, -7]
    latitude = [-5, 5, 5, -2, -4, 7, 6, 3, -3, -1, 1, -5, 3, 10, 3]

    for link in weak_links
        source, target = link
        adjacency_matrix[source, target], adjacency_matrix[target, source] = 1, 1
        total_throughput[source, target] = rand(20: 50)
        total_throughput[target, source] = total_throughput[source, target]
    end

    for link in sup_links
        source, target = link
        adjacency_matrix[source, target], adjacency_matrix[target, source] = 1, 1
        total_throughput[source, target] = rand(50: 200)
        total_throughput[target, source] = total_throughput[source, target]
    end
    edges_nodes = [1, 2, 3, 4, 5, 6, 11, 14, 15]
    total_cpus_clocks = zeros(total_number_nodes)
    for c in 1: total_number_nodes
        if c in edges_nodes
            total_cpus_clocks[c] = 1 .+ 0.5 * rand(Float64)
        else
            total_cpus_clocks[c] = 3 .+ 2 * rand(Float64)
        end
    end
    total_number_nodes = min(total_number_nodes, number_nodes)
    return (total_number_nodes, total_cpus_clocks, longitude[1: total_number_nodes],
            latitude[1: total_number_nodes], adjacency_matrix[1: total_number_nodes, 1: total_number_nodes],
            total_throughput[1: total_number_nodes, 1:total_number_nodes])
end
