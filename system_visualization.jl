using Plots
using ColorSchemes


plotlyjs()  # Set the PlotlyJS backend for interactivity

include("physical_substrate.jl")
include("utils.jl")


# Function to get color from palette
function get_color(index)
    return ColorSchemes.tab20.colors[index]  # Use modulo to wrap around
end

function substrate_visualization(longitude, latitude, edges_adjacency_matrix, VNFs_placements, Virtual_links, failed_centers)
    number_slices, number_VNFs, total_number_centers = size(VNFs_placements)
    jump = 3
    p = plot()
    
    # Plotting nodes and text labels
    for c in 1: total_number_centers
        scatter!(p, [longitude[c]], [latitude[c]], [0], color=get_color(1), markersize=4, label="")
    end
    
    # Highlighting failed centers
    for c in failed_centers
        scatter!(p, [longitude[c + 1]], [latitude[c + 1]], [0], color=:black, markersize=4, label="")
    end

    # Plotting edges
    for i in 1: total_number_centers
        for j in i: total_number_centers
            if edges_adjacency_matrix[i, j] == 1
                plot!(p, [longitude[i], longitude[j]], [latitude[i], latitude[j]], [0, 0], lw=2, color=get_color(1), label="")
            end
        end
    end

    # Plotting 3D points for VNFs_placements

    for s in 1:number_slices
        for k in 1:number_VNFs
            for c in 1:total_number_centers
                if VNFs_placements[s, k, c] == 1
                    jump_ = jump * s
                    scatter!(p, [longitude[c]], [latitude[c]], [jump_], color=get_color(2 * s + 1), markersize=4, label="")
                end
            end
        end
    end

    
    # Define virtual_links
    virtual_links = zeros(Int, number_slices, total_number_centers, total_number_centers)

    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            for i in 1: total_number_centers
                for j in 1: total_number_centers
                    if Virtual_links[s, k, i, j] == 1
                        virtual_links[s, i, j] = 1
                    end
                end
            end
        end
    end

    # Additional plotting for virtual links
    for s in 1: number_slices
        for i in 1: total_number_centers
            for j in 1: total_number_centers
                if virtual_links[s, i, j] == 1
                    jump_ = jump * s
                    plot!(p, [longitude[i], longitude[j]], [latitude[i], latitude[j]], [jump_, jump_], color=get_color(2 * s + 1), label="")
                end
            end
        end
    end

    return plot(p, legend=false, xlabel="Longitude", ylabel="Latitude", zlabel="Slices", xticks=nothing, yticks=nothing, zticks=nothing)
end

function system_performance(total_number_centers, total_available_cpus, required_cpus, VNFs_placements, alpha)
    # Assuming some use of input parameters here for actual data
    x = 1:10
    y = rand(10)
    return plot(x, y, title="Static 2D Line Plot")
end

function system_visualization()
    data = load_data()

    total_available_cpus = data["total_available_cpus"]
    required_cpus = data["required_cpus"]
    assigned_cpus = data["assigned_cpus"]
    VNFs_placements = data["VNFs_placements"]
    required_bandwidth = data["required_bandwidth"]
    assigned_bandwidth = data["assigned_bandwidth"]
    Virtual_links = data["Virtual_links"]
    Rounds = data["Rounds"]
    failed_centers = []
    println(Rounds)
    

    number_node = size(total_available_cpus)[1]

    total_number_centers, _, longitude, latitude, edges_adjacency_matrix, 
    _, _ = physical_substrate(number_node)

    for (round_index, Round) in enumerate(Rounds)
        println("Round ", round_index)
        if !isempty(Round)
            for center in Round
                total_available_cpus[center + 1] = 0  # Ensure 'center + 1' is correct
            end
        end
        
        display_solution(VNFs_placements[round_index])
        display_cpu_usage(required_cpus, assigned_cpus[round_index])
        println(required_bandwidth)
        println(assigned_bandwidth[round_index])
        append!(failed_centers, Round)
        # p1 = substrate_visualization(longitude, latitude, edges_adjacency_matrix, VNFs_placements[round_index], Virtual_links[round_index], failed_centers)
        # p2 = system_performance(total_number_centers, total_available_cpus, required_cpus, VNFs_placements, alpha)
        # p = plot(p1, layout=(1, 2), legend=false)
        # display(p)
    end
end

system_visualization()
