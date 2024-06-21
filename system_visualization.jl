using Plots
using ColorSchemes
using DataFrames
using Printf


include("physical_substrate.jl")
include("utils.jl")


function system_visualization(total_cpus_clocks, nodes_state, Clocks, VNFs_placements, Throughput, Virtual_links, number_uRLLC, number_eMBB, number_mMTC, failed_nodes, number_cycles, traffic, objective_values, consumed_recovery_resources, nodes_recovery_resources, title)
    number_nodes = size(total_cpus_clocks)[1]
    number_nodes, _, longitude, latitude, adjacency_matrix, _ = physical_substrate(number_nodes)

    for node in failed_nodes
        total_cpus_clocks[node] *= nodes_state[node]
    end
    p1 = substrate_visualization(longitude, latitude, adjacency_matrix, VNFs_placements, Virtual_links, failed_nodes)
    p2 = resources_used(total_cpus_clocks, VNFs_placements, Clocks, consumed_recovery_resources, nodes_recovery_resources)
    p = plot(p1, p2, layout=(1, 2), legend=false, size=(1500, 700), title=title)
    display(p)
    # p3 = plotting_objective_value(objective_values)
    # p4 = slices_deployed(number_nodes, number_cycles, traffic, VNFs_placements, Virtual_links, Clocks, Throughput, Rounds, number_uRLLC, number_eMBB, number_mMTC)
    # display(p3)
    # display(p4)
end

function slices_deployed(number_nodes, number_cycles, traffic, VNFs_placements, Virtual_links, Clocks, Throughput, Rounds, number_uRLLC, number_eMBB, number_mMTC)
    p = plot()
    deployed_uRLLC, deployed_eMBB, deployed_mMTC = [0 for _ in 1: number_nodes], [0 for _ in 1: number_nodes], [0 for _ in 1: number_nodes]
    for (round_index, _) in enumerate(Rounds)
        clocks = Clocks[round_index]
        throughput = Throughput[round_index]
        vnf_placement = VNFs_placements[round_index]
        virtual_link = Virtual_links[round_index]
        for s in 1: number_uRLLC + number_eMBB + number_mMTC
            delay = compute_delay(number_cycles, traffic, vnf_placement, virtual_link, clocks, throughput, s)
            if 1 <= s < number_uRLLC + 1 && delay < 1
                deployed_uRLLC[round_index] += 1
            end
            if number_uRLLC + 1 <= s < number_uRLLC + number_eMBB + 1 && delay < 10
                deployed_eMBB[round_index] += 1
            end
            if number_uRLLC + number_eMBB + 1 <= s <= number_uRLLC + number_eMBB + number_mMTC && delay < 10
                deployed_mMTC[round_index] += 1
            end
        end
    end
    x = range(1, number_nodes)
    plot!(p, x, deployed_uRLLC, label="uRLLC", xlabel="Number of Failed Nodes")
    plot!(p, x, deployed_eMBB, label="eMBB")
    plot!(p, x, deployed_mMTC, label="uRLLC")
    return p
end

function plotting_objective_value(objective_values)
    p = plot()  
    for (index, value) in enumerate(objective_values[1:end-1])
        horizontal_x = [index - 1, index]
        horizontal_y = [value, value]
        plot!(p, horizontal_x, horizontal_y, seriestype=:shape, color=:blue, linecolor=:blue)
        vertical_x = [index, index]
        vertical_y = [value, objective_values[index + 1]]
        plot!(p, vertical_x, vertical_y, seriestype=:shape, color=:blue, linecolor=:blue)
    end
    return plot!(p, title="System Performance", xticks=[c for c in 1: length(objective_values)], xlabel="Number of failed Nodes", ylabel="Objective function", yticks=0:20:(120), size=((400, 400)), legend = false)
end

function get_color(index)
    return ColorSchemes.tab20.colors[index]
end

function substrate_visualization(longitude, latitude, adjacency_matrix, VNFs_placements, Virtual_links, failed_nodes)
    number_slices, number_VNFs, number_nodes = size(VNFs_placements)
    jump = 3
    p = plot()  
    # Plotting edges
    for i in 1: number_nodes
        for j in i: number_nodes
            if adjacency_matrix[i, j] == 1
                plot!(p, [longitude[i], longitude[j]], [latitude[i], latitude[j]], [0, 0], lw=2, color=get_color(1), label="")
            end
        end
    end
    # Plotting 3D points for VNFs_placements
    for s in 1:number_slices
        for k in 1:number_VNFs
            for c in 1:number_nodes
                if VNFs_placements[s, k, c] == 1
                    jump_ = jump * s
                    scatter!(p, [longitude[c]], [latitude[c]], [jump_], color=get_color(2 * s + 1), markersize=4, label="")
                end
            end
        end
    end
    # Define virtual_links
    virtual_links = zeros(Int, number_slices, number_nodes, number_nodes)

    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            for i in 1: number_nodes
                for j in 1: number_nodes
                    if Virtual_links[s, k, i, j] == 1
                        virtual_links[s, i, j] = 1
                    end
                end
            end
        end
    end
    # Additional plotting for virtual links
    for s in 1: number_slices
        for i in 1: number_nodes
            for j in 1: number_nodes
                if virtual_links[s, i, j] == 1
                    jump_ = jump * s
                    plot!(p, [longitude[i], longitude[j]], [latitude[i], latitude[j]], [jump_, jump_], color=get_color(2 * s + 1), label="")
                end
            end
        end
    end
    # Plotting nodes and text labels
    for c in 1: number_nodes
        scatter!(p, [longitude[c]], [latitude[c]], [0], color=get_color(1), markersize=4, label="")
    end
    # Highlighting failed centers
    for c in failed_nodes
        scatter!(p, [longitude[c]], [latitude[c]], [0], color=:black, markersize=4, label="")
    end
    return plot!(p, legend=false, title="Physical Substrate", xlabel="Longitude", ylabel="Latitude", zlabel="Slices", xticks=nothing, yticks=nothing, zticks=nothing)
end

function resources_used(total_cpus_clocks, VNFs_placements, clocks, consumed_recovery_resources, nodes_recovery_resources)
    p = plot()  
    number_slices, number_VNFs, number_nodes = size(VNFs_placements)
    nodes_x = [[x - 0.45, x + 0.45] for x in 1: number_nodes + 1]
    curr_height = zeros(number_nodes)
    for s in 1: number_slices
        for k in 1: number_VNFs
            for c in 1: number_nodes
                if VNFs_placements[s, k, c] == 1 && total_cpus_clocks[c] != 0
                    x = [nodes_x[c][1], nodes_x[c][2], nodes_x[c][2], nodes_x[c][1]]
                    added_height =  clocks[s, k]
                    y = [curr_height[c], curr_height[c], curr_height[c] + added_height, curr_height[c] + added_height] 
                    plot!(p, x, y, seriestype=:shape, color=get_color(2 * s + 1))
                    curr_height[c] += added_height
                end                
            end
        end
    end
    # Left resources
    for c in 1: number_nodes
        x = [nodes_x[c][1], nodes_x[c][2], nodes_x[c][2], nodes_x[c][1]]
        y = [curr_height[c], curr_height[c], total_cpus_clocks[c], total_cpus_clocks[c]] 
        plot!(p, x, y, seriestype=:shape, color=:black)
    end
    # Consumed Resources
    recovery_index = number_nodes + 1
    height = 0.5 * consumed_recovery_resources / nodes_recovery_resources
    x = [nodes_x[recovery_index][1], nodes_x[recovery_index][2], nodes_x[recovery_index][2], nodes_x[recovery_index][1]]
    y = [0, 0, height, height] 
    plot!(p, x, y, seriestype=:shape, color=:white)
    # Left recovery resources
    recovery_index = number_nodes + 1
    x = [nodes_x[recovery_index][1], nodes_x[recovery_index][2], nodes_x[recovery_index][2], nodes_x[recovery_index][1]]
    y = [height, height, 0.5, 0.5] 
    plot!(p, x, y, seriestype=:shape, color=:black)

    return plot!(p, title="Consumed CPU/Recovery resources", xticks=[c for c in 1: number_nodes + 1], ylim=(0, 0.5), xtick_labels=vcat(["Node $(c)" for c in 1: number_nodes], ["Recovery"]), yticks=0:20:(120), size=((400, 400)))
end

function plotting_recovery_resources()


end