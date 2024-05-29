using Plots
using ColorSchemes
using Printf

include("physical_substrate.jl")
include("utils.jl")


function system_visualization()
    data = load_data()
    total_cpus_clocks = data["total_cpus_clocks"]
    cycles = data["cycles"]
    VNFs_placements = data["vnf_placement"]
    Virtual_links = data["virtual_link"]
    failed_centers = []
    
    number_nodes = size(total_cpus_clocks)[1]

    number_nodes, _, longitude, latitude, adjacency_matrix, _ = physical_substrate(number_nodes)
    Rounds = [[]]
    for (round_index, Round) in enumerate(Rounds)
        println("Round ", round_index)
        if !isempty(Round)
            for center in Round
                total_available_cpus[center + 1] = 0
            end
        end

        # display_cpu_usage(required_cpus, assigned_cpus[round_index])
        append!(failed_centers, Round)
        p1 = substrate_visualization(longitude, latitude, adjacency_matrix, VNFs_placements, Virtual_links, failed_centers)
        p2 = system_performance(total_cpus_clocks, VNFs_placements, cycles)
        p = plot(p1, p2, layout=(1, 2), legend=false, size=(1200, 600))
        display(p)
    end
end

function substrate_visualization(longitude, latitude, adjacency_matrix, VNFs_placements, Virtual_links, failed_centers)
    number_slices, number_VNFs, number_nodes = size(VNFs_placements)
    jump = 3
    p = plot()  
    # Plotting nodes and text labels
    for c in 1: number_nodes
        scatter!(p, [longitude[c]], [latitude[c]], [0], color=get_color(1), markersize=4, label="")
    end
    # Highlighting failed centers
    for c in failed_centers
        scatter!(p, [longitude[c + 1]], [latitude[c + 1]], [0], color=:black, markersize=4, label="")
    end
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
    return plot(p, legend=false, xlabel="Longitude", ylabel="Latitude", zlabel="Slices", xticks=nothing, yticks=nothing, zticks=nothing)
end

function system_performance(total_cpus_clocks, VNFs_placements, cycles)
    p = plot()  
    number_slices, number_VNFs, number_nodes = size(VNFs_placements)
    nodes_x = [[x - 0.45, x + 0.45] for x in 1: number_nodes]
    curr_height = zeros(number_nodes)
    for s in 1: number_slices
        for k in 1: number_VNFs
            for c in 1: number_nodes
                if VNFs_placements[s, k, c] == 1
                    x = [nodes_x[c][1], nodes_x[c][2], nodes_x[c][2], nodes_x[c][1]]
                    added_height =  cycles[s, k] * 100 / total_cpus_clocks[c]
                    y = [curr_height[c], curr_height[c], curr_height[c] + added_height, curr_height[c] + added_height] 
                    plot!(p, x, y, seriestype=:shape, color=get_color(2 * s + 1))
                    curr_height[c] += added_height
                end                
            end
        end
    end
    for c in 1: number_nodes
        x = [nodes_x[c][1], nodes_x[c][2], nodes_x[c][2], nodes_x[c][1]]
        y = [curr_height[c], curr_height[c], 100, 100] 
        plot!(p, x, y, seriestype=:shape, color=:gray)
    end
    plot!(title="Consumed CPU cycles", xticks=[c for c in 1: number_nodes], xtick_labels=["Node $(c)" for c in 1: number_nodes], yticks=0:20:(120), size=((400, 400)))
    return p
end

system_visualization()
