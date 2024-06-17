using JuMP, AmplNLWriter, Ipopt, MathOptInterface


function primal_problem(number_slices, number_nodes, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, VNFs_placements, Virtual_links, β)
    
    model = Model(Ipopt.Optimizer)
    set_silent(model)
    clocks = Array{VariableRef, 2}(undef, number_slices, number_VNFs)
    for s in 1: number_slices
        for k in 1: number_VNFs
            clocks[s, k] = @variable(model, base_name="clocks_slice_$(s)_VNF_$(k)", lower_bound=0)
        end
    end
    throughput = Array{VariableRef, 2}(undef, number_slices, number_VNFs - 1)
    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            throughput[s, k] = @variable(model, base_name="throughput_slice_$(s)_VL$(k)_to_VL$(k + 1)", lower_bound=0)
        end
    end
    alpha = 0.5

    @objective(model, Min, sum(β[s, 1] * (sum(clocks[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
    sum(throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)) + 
    β[s, 2] * (10 ^ -6 * sum(number_cycles[s, k] / clocks[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
    10 ^ -3 * sum(traffic[s, k] / throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes))
    for s in 1: number_slices)) 
    
    # Constraints
    constraints = Dict{String, ConstraintRef}()
    # Node Embedding Constraints
    # Constraint 1: Guarantee that allocated VNF resources do not exceed physical servers' processing capacity.
    for c in 1: number_nodes
        con_name = "Node$(c)_constraint"
        constraints[con_name] = @constraint(model, sum(VNFs_placements[s, k, c] * clocks[s, k] for s in 1: number_slices, k in 1: number_VNFs) <= total_cpus_clocks[c])
    end

    # Link Embedding Constraints
    # Constraint 1: Guarantee that allocated throughput resources do not exceed physical links' throughput capacity.
    for i in 1: number_nodes
        for j in 1: number_nodes
            con_name = "Link($(i), $(j))_constraint"
            constraints[con_name] = @constraint(model, sum(Virtual_links[s, k, i, j] * throughput[s, k] for s in 1: number_slices, k in 1: number_VNFs - 1) <= total_throughput[i, j])
        end
    end

    # Delay Constraints
    # Constraint 1: Total delay of a slice cannot exceed delay tolerance.
    # for s in 1: number_slices
    #     con_name = "Slice$(s)_delay_constraint"
    #     constraints[con_name] = @constraint(model, sum(number_cycles[s, k] / cycles[s, k] for s in 1: number_slices for k in 1: number_VNFs) + sum(traffic[s, k] / throughput[s, k] for s in 1: number_slices for k in 1: number_VNFs - 1) <= delay_tolerance[s])
    # end
    

    # Solve the problem
    optimize!(model)


    # Extract Results Values
    clocks_values = Array{Float32, 2}(undef, number_slices, number_VNFs)
    for s in 1: number_slices
        for k in 1: number_VNFs
            clocks_values[s, k] = value(clocks[s, k])
        end
    end
    throughput_values = Array{Float32, 2}(undef, number_slices, number_VNFs - 1)
    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            throughput_values[s, k] = value(throughput[s, k])
        end
    end

    λ = []
    for c in 1: number_nodes
        con_name = "Node$(c)_constraint"
        push!(λ, dual(constraints[con_name]))
    end    
    for i in 1: number_nodes
        for j in 1: number_nodes
            con_name = "Link($(i), $(j))_constraint"
            push!(λ, dual(constraints[con_name]))
        end
    end
    # for s in 1: number_slices
    #     con_name = "Slice$(s)_delay_constraint"
    #     push!(λ, dual(constraints[con_name]))
    # end
    return objective_value(model), clocks_values, throughput_values, λ
end