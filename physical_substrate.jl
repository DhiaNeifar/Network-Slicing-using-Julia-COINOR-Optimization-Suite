using Random

function physical_substrate(number_nodes)
    total_number_nodes = 10
    adjacency_matrix = zeros(Int, total_number_nodes, total_number_nodes)
    
    total_throughput = zeros(Float64, total_number_nodes, total_number_nodes)

    links = [(1, 2), (1, 4), (1, 5), (1, 9), (2, 3), (2, 6), (2, 7), (3, 4), (3, 5), (4, 5), (6, 7), (7, 8), (7, 9), (7, 10), (8, 9), (9, 10)]

    longitude = [0, 1, -4, -6, -4, 2, 7, 4, 3, 8]
    latitude = [-5, 5, 5, -2, -4, 7, 6, 3, -3, -1]

    for link in links
        source, target = link
        adjacency_matrix[source, target], adjacency_matrix[target, source] = 1, 1
        total_throughput[source, target] = rand(150: 200)
        total_throughput[target, source] = total_throughput[source, target]
    end

    total_number_nodes = min(total_number_nodes, number_nodes)
    total_cpus_clocks = rand(100.0: 500.0, total_number_nodes)

    return (total_number_nodes, total_cpus_clocks, longitude[1: total_number_nodes],
            latitude[1: total_number_nodes], adjacency_matrix[1: total_number_nodes, 1: total_number_nodes],
            total_throughput[1: total_number_nodes, 1:total_number_nodes])
end
