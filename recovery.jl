using Random

function recovery(number_nodes)
    nodes_state = ones(number_nodes)
    node_recovery_requirements = rand(10: 20, number_nodes)
    recovery_resources = 100000
    return nodes_state, recovery_resources, node_recovery_requirements
end
