using Random

function slice_instantiation(num_slices, number_VNFs=6)
    number_cycles = [rand(1.0: 1.5) for _ in 1: num_slices, _ in 1: number_VNFs]
    traffic = [rand(30: 50) for _ in 1: num_slices, _ in 1: number_VNFs - 1]
    delay_tolerance = rand(10000: 300000, num_slices)

    return number_cycles, traffic, delay_tolerance
end
