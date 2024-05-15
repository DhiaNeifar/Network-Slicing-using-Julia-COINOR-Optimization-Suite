using JuMP, AmplNLWriter, Couenne_jll, MathOptInterface
const MOI = MathOptInterface

function bump(x::Float64, z0::Float64, z1::Float64)
    if x < z0
        return 1.0
    elseif x < z1
        return 0.5 * cos(pi * (x - z0) / (z0 - z1))
    else
        return 0.0
    end
end

function network_slicing(number_slices, total_number_centers, total_available_cpus, edges_adjacency_matrix, total_available_bandwidth, edges_delay, number_VNFs, required_cpus, required_bandwidth, delay_tolerance, failed_centers)
   
    model = Model(Ipopt.Optimizer)
    JuMP.register(model, :bump, 3, bump; autodiff = true)

    VNFs_placements = Array{VariableRef, 3}(undef, number_slices, number_VNFs, total_number_centers)
    for s in 1: number_slices
        for c in 1: total_number_centers
            for k in 1: number_VNFs
                VNFs_placements[s, k, c] = @variable(model, base_name="slice_$(s)_center_$(c)_VNF_$(k)", lower_bound=0, upper_bound=1)
            end
        end
    end
    assigned_cpus = Array{VariableRef, 2}(undef, number_slices, number_VNFs)
    for s in 1: number_slices
        for k in 1: number_VNFs
            assigned_cpus[s, k] = @variable(model, base_name="assigned_cpus_slice_$(s)_VNF_$(k)", lower_bound=1, upper_bound=required_cpus[s, k])
        end
    end
    Virtual_links = Array{VariableRef, 4}(undef, number_slices, number_VNFs - 1, total_number_centers, total_number_centers)
    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            for i in 1: total_number_centers
                for j in 1: total_number_centers
                    Virtual_links[s, k, i, j] = @variable(model, base_name="slice_$(s)_VL$(k)_to_VL$(k + 1)_PN$(i)_to_PN$(j)", lower_bound=0, upper_bound=1)
                end
            end
        end
    end
    @NLobjective(model, Max, sum(log(1 + (assigned_cpus[s, k] * VNFs_placements[s, k, c]) / required_cpus[s, k])
    for s in 1: number_slices 
        for k in 1: number_VNFs 
            for c in 1: total_number_centers)
                - 1 / (number_slices * number_VNFs * total_number_centers) * sum(100 * sin(VNFs_placements[s, k, c] * pi)
                for s in 1: number_slices 
                    for k in 1: number_VNFs 
                        for c in 1: total_number_centers)
                            + sum(bump(sum(Virtual_links[s, k, i, j] * edges_delay[i ,j] for k in 1: number_VNFs - 1 for i in 1: total_number_centers for j in 1: total_number_centers), delay_tolerance[s], 2 * delay_tolerance[s]) for s in 1: number_slices) 
                            - 1 / (number_slices * number_VNFs * total_number_centers * total_number_centers) * sum(sin(Virtual_links[s, k, i, j] * pi)
                            for s in 1: number_slices 
                                for k in 1: number_VNFs - 1 
                                    for i in 1: total_number_centers 
                                        for j in 1: total_number_centers))

    # Constraints

    # Node Embedding Constraints
    # Constraint 1: Each VNF is assigned only once to a center.
    for s in 1: number_slices
        for k in 1: number_VNFs
            @constraint(model, sum(VNFs_placements[s, k, c] for c in 1:total_number_centers) == 1)
        end
    end
    
    # Constraint 2: Each VNF is assigned to an exactly one center.
    for s in 1: number_slices
        for c in 1: total_number_centers
            @constraint(model, sum(VNFs_placements[s, k, c] for k in 1: number_VNFs) <= ceil(div(number_VNFs, max(1, (total_number_centers - 1 - length(failed_centers))))) + 1)
        end
    end
    # Constraint 3: Guarantee that allocated VNF resources do not exceed physical servers' processing capacity.
    for c in 1: total_number_centers
        @constraint(model, sum(VNFs_placements[s, k, c] * assigned_cpus[s, k] for s in 1: number_slices, k in 1: number_VNFs) <= total_available_cpus[c])
    end

    # Link Embedding Constraints
    # Constraint 2: Flow Conservation Constraint
    for s in 1: number_slices
        for i in 1: total_number_centers
            for k in 1: number_VNFs - 1
                @constraint(model, sum(Virtual_links[s, k, i, j] * edges_adjacency_matrix[i, j] for j in 1: total_number_centers) - 
                sum(Virtual_links[s, k, j, i] * edges_adjacency_matrix[j ,i] for j in 1: total_number_centers) == VNFs_placements[s, k, i] - VNFs_placements[s, k + 1, i])
            end
        end
    end
    # Constraint 3: Guarantee that allocated throughput resources do not exceed physical links' throughput capacity.
    for i in 1: total_number_centers
        for j in 1: total_number_centers
            @constraint(model, sum(Virtual_links[s, k, i, j] * required_bandwidth[s, k] for s in 1: number_slices, k in 1: number_VNFs - 1) <= total_available_bandwidth[i, j])
        end
    end

    # Solve the problem
    optimize!(model)
    status = termination_status(model)
    if status == MOI.OPTIMAL
        println("An optimal solution has been found!")
    elseif status == MOI.INFEASIBLE
        println("The problem is infeasible.")
    else
        println("The solver stopped with status: $status")
    end

    # Extract Results Values
    vnf_placement_values = Array{Int, 3}(undef, number_slices, number_VNFs, total_number_centers)
    for s in 1: number_slices
        for k in 1: number_VNFs
            for c in 1: total_number_centers
                if value(VNFs_placements[s, k, c]) > 0.5
                    vnf_placement_values[s, k, c] = 1
                else
                    vnf_placement_values[s, k, c] = 0
                end 
            end
        end
    end
    assigned_cpus_values = Array{Float32, 2}(undef, number_slices, number_VNFs)
    for s in 1: number_slices
        for k in 1: number_VNFs
            assigned_cpus_values[s, k] = value(assigned_cpus[s, k])
        end
    end
    virtual_link_values = Array{Int, 4}(undef, number_slices, number_VNFs - 1, total_number_centers, total_number_centers)
    for s in 1: number_slices
        for k in 1: (number_VNFs - 1)
            for i in 1: total_number_centers
                for j in 1: total_number_centers
                    if value(Virtual_links[s, k, i, j]) > 0.5
                        virtual_link_values[s, k, i, j] = 1
                    else 
                        virtual_link_values[s, k, i, j] = 0
                    end
                end
            end
        end
    end
    return vnf_placement_values, assigned_cpus_values, virtual_link_values
end