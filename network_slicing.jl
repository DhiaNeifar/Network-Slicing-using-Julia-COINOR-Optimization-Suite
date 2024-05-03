using JuMP, AmplNLWriter, MathOptInterface
const MOI = MathOptInterface


function VNF_mapping(number_slices, total_number_centers, total_available_cpus, number_VNFs, required_cpus, failed_centers)
    model = Model(() -> AmplNLWriter.Optimizer("/usr/bin/couenne"))

    # Decision Variables
    VNFs_placements = Array{VariableRef, 3}(undef, number_slices, number_VNFs, total_number_centers)
    for s in 1: number_slices
        for c in 1: total_number_centers
            for k in 1: number_VNFs
                VNFs_placements[s, k, c] = @variable(model, base_name = "slice_$(s)_center_$(c)_VNF_$(k)", binary = true)
            end
        end
    end

    @variable(model, 0 <= alpha <= 1, base_name = "alpha")


    # Objective Function
    @objective(model, Max, sum(alpha * VNFs_placements[s, k, c] * required_cpus[s, k] for s in 1:number_slices, k in 1:number_VNFs, c in 1:total_number_centers))


    # Constraints

    # Constraint 1: Each VNF is assigned only once to a center.
    for s in 1:number_slices
        for k in 1:number_VNFs
            @constraint(model, sum(VNFs_placements[s, k, c] for c in 1:total_number_centers) == 1)
        end
    end
    
    # Constraint 2: Each VNF is assigned to an exactly one center.
    for s in 1:number_slices
        for c in 1:total_number_centers
            @constraint(model, sum(VNFs_placements[s, k, c] for k in 1:number_VNFs) <= ceil(div(number_VNFs, max(1, (total_number_centers - 1 - length(failed_centers))))) + 1)
        end
    end

    # Constraint 3: Guarantee that allocated VNF resources do not exceed physical servers' processing capacity.
    for c in 1:total_number_centers
        @constraint(model, sum(alpha * VNFs_placements[s, k, c] * required_cpus[s, k] for s in 1:number_slices, k in 1:number_VNFs) <= total_available_cpus[c])
    end

    # Solve the problem
    optimize!(model)


    # Vectorize found values
    vnf_placement_values = Array{Int, 3}(undef, number_slices, number_VNFs, total_number_centers)

    for s in 1:number_slices
        for k in 1:number_VNFs
            for c in 1:total_number_centers
                if value(VNFs_placements[s, k, c]) > 0.5
                    vnf_placement_values[s, k, c] = 1
                else 
                    vnf_placement_values[s, k, c] = 0
                end
            end
        end
    end

    return value(alpha), vnf_placement_values
end

function paths_finding(number_slices, total_number_centers, edges_adjacency_matrix, total_available_bandwidth, number_VNFs, required_bandwidth, VNFs_placements)
    model = Model(() -> AmplNLWriter.Optimizer("/usr/bin/couenne"))

    # Decision Variables
    Virtual_links = Array{VariableRef, 4}(undef, number_slices, number_VNFs - 1, total_number_centers, total_number_centers)
    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            for i in 1: total_number_centers
                for j in 1: total_number_centers
                    Virtual_links[s, k, i, j] = @variable(model, base_name = "slice_$(s)_VL$(k)_to_VL$(k + 1)_PN$(i)_to_PN$(j)", binary = true)
                end
            end
        end
    end

    # Objective Function
    @objective(model, Min, sum(Virtual_links[s, k, i, j] * required_bandwidth[s, k] for s in 1:number_slices, k in 1:number_VNFs - 1 for i in 1: total_number_centers for j in 1: total_number_centers))
    
    
    # Constraints
    
    # Constraint 1: Flow Conservation Constraint
    for s in 1: number_slices
        for i in 1: total_number_centers
            for k in 1: number_VNFs - 1
                @constraint(model, sum(Virtual_links[s, k, i, j] * edges_adjacency_matrix[i, j] for j in 1: total_number_centers) - 
                sum(Virtual_links[s, k, j, i] * edges_adjacency_matrix[j, i] for j in 1: total_number_centers) == VNFs_placements[s, k, i] - VNFs_placements[s, k + 1, i])
            end
        end
    end

    # Constraint 2: Guarantee that allocated throughput resources do not exceed physical links' throughput capacity.
    for i in 1: total_number_centers
        for j in 1: total_number_centers
            @constraint(model, sum(Virtual_links[s, k, i, j] * required_bandwidth[s, k] for s in 1:number_slices, k in 1:number_VNFs - 1) <= total_available_bandwidth[i, j])
        end
    end

    # Solve the problem
    optimize!(model)


    # Vectorize found values
    virtual_link_values = Array{Int, 4}(undef, number_slices, number_VNFs - 1, total_number_centers, total_number_centers)

    for s in 1:number_slices
        for k in 1:(number_VNFs - 1)
            for i in 1:total_number_centers
                for j in 1:total_number_centers
                    if value(Virtual_links[s, k, i, j]) > 0.5
                        virtual_link_values[s, k, i, j] = 1
                    else 
                        virtual_link_values[s, k, i, j] = 0
                    end
                end
            end
        end
    end

    return virtual_link_values
end


function old_network_slicing(number_slices, total_number_centers, total_available_cpus, edges_adjacency_matrix, total_available_bandwidth, edges_delay, number_VNFs, required_cpus, required_bandwidth, delay_tolerance, failed_centers)

    alpha, VNFs_placements = VNF_mapping(number_slices, total_number_centers, total_available_cpus, number_VNFs, required_cpus, failed_centers)

    Virtual_links = paths_finding(number_slices, total_number_centers, edges_adjacency_matrix, total_available_bandwidth, number_VNFs, required_bandwidth, VNFs_placements)

    return alpha, VNFs_placements, Virtual_links


end



function network_slicing(number_slices, total_number_centers, total_available_cpus, edges_adjacency_matrix, total_available_bandwidth, edges_delay, number_VNFs, required_cpus, required_bandwidth, delay_tolerance, failed_centers)

    model = Model(() -> AmplNLWriter.Optimizer("/usr/bin/couenne"))

    # Decision Variables
    VNFs_placements = Array{VariableRef, 3}(undef, number_slices, number_VNFs, total_number_centers)

    for s in 1: number_slices
        for c in 1: total_number_centers
            for k in 1: number_VNFs
                VNFs_placements[s, k, c] = @variable(model, base_name = "slice_$(s)_center_$(c)_VNF_$(k)", binary = true)
            end
        end
    end

    Virtual_links = Array{VariableRef, 4}(undef, number_slices, number_VNFs - 1, total_number_centers, total_number_centers)

    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            for i in 1: total_number_centers
                for j in 1: total_number_centers
                    Virtual_links[s, k, i, j] = @variable(model, base_name = "slice_$(s)_VL$(k)_to_VL$(k + 1)_PN$(i)_to_PN$(j)", binary = true)
                end
            end
        end
    end

    @variable(model, 0 <= alpha <= 1, base_name = "alpha")

    # Objective Function
    @objective(model, Max, 100000 * alpha - sum(Virtual_links[s, k, i, j] * required_bandwidth[s, k] for s in 1:number_slices, k in 1:number_VNFs - 1 for i in 1: total_number_centers for j in 1: total_number_centers))
    

    # Constraints


    # Node Embedding Constraints

    # Constraint 1: Each VNF is assigned only once to a center.
    for s in 1:number_slices
        for k in 1:number_VNFs
            @constraint(model, sum(VNFs_placements[s, k, c] for c in 1:total_number_centers) == 1)
        end
    end
    
    # Constraint 2: Each VNF is assigned to an exactly one center.
    for s in 1:number_slices
        for c in 1:total_number_centers
            @constraint(model, sum(VNFs_placements[s, k, c] for k in 1:number_VNFs) <= ceil(div(number_VNFs, max(1, (total_number_centers - 1 - length(failed_centers))))) + 1)
        end
    end

    # Constraint 3: Guarantee that allocated VNF resources do not exceed physical servers' processing capacity.
    for c in 1:total_number_centers
        @constraint(model,  alpha * sum(VNFs_placements[s, k, c] * required_cpus[s, k] for s in 1:number_slices, k in 1:number_VNFs) <= total_available_cpus[c])
    end
    

    # Link Embedding Constraints

    # Constraint 1: Flow Conservation Constraint
    for s in 1: number_slices
        for i in 1: total_number_centers
            for k in 1: number_VNFs - 1
                @constraint(model, sum(Virtual_links[s, k, i, j] * edges_adjacency_matrix[i, j] for j in 1: total_number_centers) - 
                sum(Virtual_links[s, k, j, i] * edges_adjacency_matrix[j, i] for j in 1: total_number_centers) == VNFs_placements[s, k, i] - VNFs_placements[s, k + 1, i])
            end
        end
    end

    # Constraint 2: Guarantee that allocated throughput resources do not exceed physical links' throughput capacity.
    for i in 1: total_number_centers
        for j in 1: total_number_centers
            @constraint(model, sum(Virtual_links[s, k, i, j] * required_bandwidth[s, k] for s in 1:number_slices, k in 1:number_VNFs - 1) <= total_available_bandwidth[i, j])
        end
    end

    optimize!(model)

    vnf_placement_values = Array{Int, 3}(undef, number_slices, number_VNFs, total_number_centers)

    for s in 1:number_slices
        for k in 1:number_VNFs
            for c in 1:total_number_centers
                if value(VNFs_placements[s, k, c]) > 0.5
                vnf_placement_values[s, k, c] = 1
                else 
                    vnf_placement_values[s, k, c] = 0
                end
            end
        end
    end

    virtual_link_values = Array{Int, 4}(undef, number_slices, number_VNFs - 1, total_number_centers, total_number_centers)

    for s in 1:number_slices
        for k in 1:(number_VNFs - 1)
            for i in 1:total_number_centers
                for j in 1:total_number_centers
                    if value(Virtual_links[s, k, i, j]) > 0.5
                        virtual_link_values[s, k, i, j] = 1
                    else 
                        virtual_link_values[s, k, i, j] = 0
                    end
                end
            end
        end
    end

    return value(alpha), vnf_placement_values, virtual_link_values
end