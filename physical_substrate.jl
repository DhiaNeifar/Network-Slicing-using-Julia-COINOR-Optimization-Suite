using Random

function physical_substrate(number_node)
    total_number_centers = 10
    edges_adjacency_matrix = zeros(Int, total_number_centers, total_number_centers)
    edges_delay = zeros(Float64, total_number_centers, total_number_centers)
    total_available_bandwidth = zeros(Float64, total_number_centers, total_number_centers)

    links = [(0, 1), (0, 3), (0, 4), (0, 6), (0, 8), (1, 2), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (3, 4),
             (5, 6), (6, 7), (6, 8), (6, 9), (7, 8), (8, 9)]

    longitude = [0, 1, -4, -6, -4, 2, 7, 4, 3, 8]
    latitude = [-5, 5, 5, -2, -4, 7, 6, 3, -3, -1]

    for link in links
        source, target = link
        edges_adjacency_matrix[source + 1, target + 1], edges_adjacency_matrix[target + 1, source + 1] = 1, 1
        edges_delay[source + 1, target + 1] = rand()
        edges_delay[target + 1, source + 1] = edges_delay[source + 1, target + 1]
        total_available_bandwidth[source + 1, target + 1] = rand(60: 80)
        total_available_bandwidth[target + 1, source + 1] = total_available_bandwidth[source + 1, target + 1]
    end

    total_number_centers = min(total_number_centers, number_node)
    total_available_cpus = rand(30: 50, total_number_centers)

    return (total_number_centers, total_available_cpus, longitude[1: total_number_centers],
            latitude[1: total_number_centers], edges_adjacency_matrix[1: total_number_centers, 1: total_number_centers],
            total_available_bandwidth[1: total_number_centers, 1:total_number_centers],
            edges_delay[1: total_number_centers, 1: total_number_centers])
end
