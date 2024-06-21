using Random


function init_failed_nodes(number_nodes)
    number_failed_nodes = rand(1: number_nodes)
    return shuffle(1: number_nodes)[1: number_failed_nodes], rand(number_failed_nodes)
end
