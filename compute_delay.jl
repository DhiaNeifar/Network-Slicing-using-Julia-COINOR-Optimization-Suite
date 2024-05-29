using Plots
using ColorSchemes

include("physical_substrate.jl")
include("utils.jl")

function compute_delay()
    data = load_data()
    total_cpus_clocks = data["total_cpus_clocks"]
    cycles = data["cycles"]
    number_cycles = data["number_cycles"]
    x = [i for i in 1: 10: 101]
    number_nodes, number_VNFs = size(number_cycles)
    delay = [sum(number_cycles[s, k] / cycle[s, k] for s in 1: number_nodes for k in 1: number_VNFs) for cycle in cycles]
    p = plot()
    plot!(p, x, x, label="Computation Percentage used")
    plot!(p, x, delay, label="Total Delay")
end

compute_delay()