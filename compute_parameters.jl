function compute_parameters(number_slices, number_nodes, number_VNFs, VNFs_placements, Virtual_links, clocks, throughput, number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance)
    uRLLC_slices_deployed = 0
    uRLLC_slices_delay = 0
    uRLLC_slices_resources = 0
    eMBB_slices_deployed = 0
    eMBB_slices_delay = 0
    eMBB_slices_resources = 0
    mMTC_slices_deployed = 0
    mMTC_slices_delay = 0
    mMTC_slices_resources = 0
    for s in 1: number_slices
        delay = 10 ^ -6 * sum(number_cycles[s, k] / clocks[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
        10 ^ -3 * sum(traffic[s, k] / throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)
        resources_consumed = sum(clocks[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
        sum(throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)
        if s <= number_uRLLC
            uRLLC_slices_delay += delay
            uRLLC_slices_resources += resources_consumed
            if delay < delay_tolerance[s]
                uRLLC_slices_deployed += 1
            end
        end
        if number_uRLLC < s <= number_uRLLC + number_eMBB
            eMBB_slices_delay += delay
            eMBB_slices_resources += resources_consumed
            if delay < delay_tolerance[s]
                eMBB_slices_deployed += 1
            end
        end
        if number_uRLLC + number_eMBB < s
            mMTC_slices_delay += delay
            mMTC_slices_resources += resources_consumed
            if delay < delay_tolerance[s]
                mMTC_slices_deployed += 1
            end
        end
    end
    return uRLLC_slices_deployed, uRLLC_slices_delay, uRLLC_slices_resources, eMBB_slices_deployed, eMBB_slices_delay, eMBB_slices_resources, mMTC_slices_deployed, mMTC_slices_delay, mMTC_slices_resources
end

