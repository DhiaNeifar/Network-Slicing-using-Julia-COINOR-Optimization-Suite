using JuMP, AmplNLWriter, Ipopt, MathOptInterface


function primal_problem_recovery(number_slices, number_nodes, nodes_state, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, VNFs_placements, Virtual_links, nodes_recovery_resources, node_recovery_requirements, β)
    
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
    Recovery_states = Array{VariableRef, 1}(undef, number_nodes)
    for c in 1: number_nodes
        Recovery_states[c] = @variable(model, base_name="recovered_$(c))", lower_bound=0)
    end
    
    
    @objective(model, Min, sum(recovery_objective_function(s, number_slices, number_nodes, number_VNFs, number_cycles, traffic, clocks, throughput, VNFs_placements, Virtual_links, β, Recovery_states, node_recovery_requirements) for s in 1: number_slices)) 
    
    # Constraints
    constraints = Dict{String, ConstraintRef}()
    # Node Embedding Constraints
    # Constraint 1: Guarantee that allocated VNF resources do not exceed physical servers' processing capacity.
    for c in 1: number_nodes
        con_name = "Node$(c)_constraint"
        constraints[con_name] = @constraint(model, sum(VNFs_placements[s, k, c] * clocks[s, k] for s in 1: number_slices, k in 1: number_VNFs) <= total_cpus_clocks[c] * (nodes_state[c] + Recovery_states[c]))
    end

    # Link Embedding Constraints
    # Constraint 1: Guarantee that allocated throughput resources do not exceed physical links' throughput capacity.
    for i in 1: number_nodes
        for j in 1: number_nodes
            con_name = "Link($(i), $(j))_constraint"
            constraints[con_name] = @constraint(model, sum(Virtual_links[s, k, i, j] * throughput[s, k] for s in 1: number_slices, k in 1: number_VNFs - 1) <= total_throughput[i, j])
        end
    end

    # Recovery Constraints
    # Constraint 1: State of a node does not exceed one.
    for c in 1: number_nodes
        con_name = "Recovery_state_$(c)_constraint"
        constraints[con_name] = @constraint(model, nodes_state[c] + Recovery_states[c] <= 1)
    end
    # Constraint 2: Recovery resources used does not exceed available.
    con_name = "Recovery_Resources_constraint"
    constraints[con_name] = @constraint(model, sum(node_recovery_requirements[c] * Recovery_states[c] for c in 1: number_nodes) <= nodes_recovery_resources)


    # Solve the problem
    optimize!(model)


    # Extract Results Values
    clocks_values = Array{Float32, 2}(undef, number_slices, number_VNFs)
    for s in 1: number_slices
        for k in 1: number_VNFs
            if value(clocks[s, k]) < 0
                clocks_values[s, k] = 0
            else
                clocks_values[s, k] = value(clocks[s, k])
            end
        end
    end
    throughput_values = Array{Float32, 2}(undef, number_slices, number_VNFs - 1)
    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            if value(throughput[s, k]) < 0
                throughput_values[s, k] = 0
            else
                throughput_values[s, k] = value(throughput[s, k])
            end
        end
    end
    recovery_states_values = Array{Float32, 1}(undef, number_nodes)
    for c in 1: number_nodes
        if value(Recovery_states[c]) < 0
            recovery_states_values[c] = 0
        else
            recovery_states_values[c] = value(Recovery_states[c])
        end
        recovery_states_values[c] = value(Recovery_states[c])
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
    for c in 1: number_nodes
        con_name = "Recovery_state_$(c)_constraint"
        push!(λ, dual(constraints[con_name]))
    end
    con_name = "Recovery_Resources_constraint"
    push!(λ, dual(constraints[con_name]))
    return objective_value(model), clocks_values, throughput_values, recovery_states_values, λ
end