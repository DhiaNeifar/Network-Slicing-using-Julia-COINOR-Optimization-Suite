using Random

function slice_instantiation(number_slices, number_VNFs)
    # TO GET ORIGINAL RESOURCE VALUES, DIVIDE EVERY THING BY 4x
    number_uRLLC = rand(1: (number_slices - 2))
    number_eMBB = rand(1: (number_slices - number_uRLLC - 1))
    number_mMTC = number_slices - number_uRLLC - number_eMBB
    number_cycles = vcat(rand(1000: 2000, number_uRLLC, number_VNFs), rand(4000: 20000, number_eMBB, number_VNFs), rand(1000: 2000, number_mMTC, number_VNFs))
    traffic = vcat(rand(20: 100, number_uRLLC, number_VNFs - 1), rand(400: 1200, number_eMBB, number_VNFs - 1), rand(280: 600, number_mMTC, number_VNFs - 1))
    delay_tolerance = vcat([1 for _ in 1: number_uRLLC], [10 for _ in 1: number_eMBB + number_mMTC])
    β = zeros(number_slices, 2)
    for s in 1: number_slices
        if 1 <= s < number_uRLLC + 1
            β[s, 1], β[s, 2] = 0.2, 0.8
        end
        if number_uRLLC + 1 <= s < number_uRLLC + number_eMBB + 1
            β[s, 1], β[s, 2] = 0.8, 0.2
        end
        if number_uRLLC + number_eMBB + 1 <= s <= number_uRLLC + number_eMBB + number_mMTC
            β[s, 1], β[s, 2] = 0.5, 0.5
        end
    end
    return number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance, β
end
