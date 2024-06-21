using Random

function recovery_resources(number_nodes)
    nodes_state = ones(number_nodes)
    node_recovery_requirements = rand(10: 20, number_nodes)
    node_recovery_resources = 5000
    return nodes_state, node_recovery_resources, node_recovery_requirements
end
