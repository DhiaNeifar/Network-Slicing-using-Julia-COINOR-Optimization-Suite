using Random

function physical_substrate(number_node)
    total_number_centers = 10
    edges_adjacency_matrix = zeros(Int, total_number_centers, total_number_centers)
    edges_delay = zeros(Float64, total_number_centers, total_number_centers)
    total_available_bandwidth = zeros(Float64, total_number_centers, total_number_centers)

    links = [(1, 2), (1, 4), (1, 5), (1, 9), (2, 3), (2, 6), (2, 7), (3, 4), (3, 5), (4, 5), (6, 7), (7, 8), (7, 9), (7, 10), (8, 9), (9, 10)]

    longitude = [0, 1, -4, -6, -4, 2, 7, 4, 3, 8]
    latitude = [-5, 5, 5, -2, -4, 7, 6, 3, -3, -1]

    for link in links
        source, target = link
        edges_adjacency_matrix[source, target], edges_adjacency_matrix[target, source] = 1, 1
        edges_delay[source, target] = rand()
        edges_delay[target, source] = edges_delay[source, target]
        total_available_bandwidth[source, target] = rand(60: 80)
        total_available_bandwidth[target, source] = total_available_bandwidth[source, target]
    end

    total_number_centers = min(total_number_centers, number_node)
    total_available_cpus = rand(70: 90, total_number_centers)

    return (total_number_centers, total_available_cpus, longitude[1: total_number_centers],
            latitude[1: total_number_centers], edges_adjacency_matrix[1: total_number_centers, 1: total_number_centers],
            total_available_bandwidth[1: total_number_centers, 1:total_number_centers],
            edges_delay[1: total_number_centers, 1: total_number_centers])
end
