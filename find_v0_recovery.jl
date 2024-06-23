using JuMP, AmplNLWriter, HiGHS, MathOptInterface


include("utils.jl")


function find_v0_recovery(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, β, node_recovery_requirements)
    
    model = Model(HiGHS.Optimizer)
    set_silent(model)
    VNFs_placements = Array{VariableRef, 3}(undef, number_slices, number_VNFs, number_nodes)
    for s in 1: number_slices
        for k in 1: number_VNFs
            for c in 1: number_nodes
                VNFs_placements[s, k, c] = @variable(model, base_name="slice_$(s)_center_$(c)_VNF_$(k)", binary=true)
            end
        end
    end
    Virtual_links = Array{VariableRef, 4}(undef, number_slices, number_VNFs - 1, number_nodes, number_nodes)
    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            for i in 1: number_nodes
                for j in 1: number_nodes
                    Virtual_links[s, k, i, j] = @variable(model, base_name="slice_$(s)_VL$(k)_to_VL$(k + 1)_PN$(i)_to_PN$(j)", binary=true)
                    if adjacency_matrix[i, j] == 0
                        fix(Virtual_links[s, k, i, j], 0.0)
                    end
                end
            end
        end
    end

    clocks = [0.000001 for _ in 1: number_slices, _ in 1: number_VNFs]
    throughput = [0.01 for _ in 1: number_slices, _ in 1: number_VNFs - 1]
    @objective(model, Min, sum(recovery_objective_function(s, number_slices, number_nodes, number_VNFs, number_cycles, traffic, clocks, throughput, VNFs_placements, Virtual_links, β, zeros(number_nodes), node_recovery_requirements) for s in 1: number_slices)) 

    # Constraints

    # Node Embedding Constraints
    # Constraint 1: Each VNF is assigned only once to a center.
    for s in 1: number_slices
        for k in 1: number_VNFs
            @constraint(model, sum(VNFs_placements[s, k, c] for c in 1:number_nodes) == 1)
        end
    end
    
    # Constraint 2: Each VNF is assigned to an exactly one center.
    for s in 1: number_slices
        for c in 1: number_nodes
            @constraint(model, sum(VNFs_placements[s, k, c] for k in 1: number_VNFs) <= 1)
        end
    end
    # Constraint 3: Guarantee that allocated VNF resources do not exceed physical servers' processing capacity.
    for c in 1: number_nodes
        @constraint(model, sum(VNFs_placements[s, k, c] * clocks[s, k] for s in 1: number_slices, k in 1: number_VNFs) <= total_cpus_clocks[c] * nodes_state[c])
    end

    # Link Embedding Constraints
    # Constraint 1: Flow Conservation Constraint
    for s in 1: number_slices
        for i in 1: number_nodes
            for k in 1: number_VNFs - 1
                @constraint(model, sum(Virtual_links[s, k, i, j] for j in 1: number_nodes if adjacency_matrix[i, j] == 1) - 
                sum(Virtual_links[s, k, j, i] for j in 1: number_nodes if adjacency_matrix[i, j] == 1) == VNFs_placements[s, k, i] - VNFs_placements[s, k + 1, i])
            end
        end
    end
    # Constraint 2: Guarantee that allocated throughput resources do not exceed physical links' throughput capacity.
    for i in 1: number_nodes
        for j in 1: number_nodes
            @constraint(model, sum(Virtual_links[s, k, i, j] * throughput[s, k] for s in 1: number_slices, k in 1: number_VNFs - 1) <= total_throughput[i, j])
        end
    end
    

    # Solve the problem
    optimize!(model)

    # Extract Results Values
    vnf_placement_values = Array{Int, 3}(undef, number_slices, number_VNFs, number_nodes)
    for s in 1: number_slices
        for k in 1: number_VNFs
            for c in 1: number_nodes
                if value(VNFs_placements[s, k, c]) > 0.5
                    vnf_placement_values[s, k, c] = 1
                else
                    vnf_placement_values[s, k, c] = 0
                end 
            end
        end
    end
    virtual_link_values = Array{Int, 4}(undef, number_slices, number_VNFs - 1, number_nodes, number_nodes)
    for s in 1: number_slices
        for k in 1: (number_VNFs - 1)
            for i in 1: number_nodes
                for j in 1: number_nodes
                    if value(Virtual_links[s, k, i, j]) > 0.5
                        virtual_link_values[s, k, i, j] = 1
                    else 
                        virtual_link_values[s, k, i, j] = 0
                    end
                end
            end
        end
    end

    return objective_value(model), vnf_placement_values, virtual_link_values
end