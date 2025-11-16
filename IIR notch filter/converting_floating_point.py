import numpy as np

def float_to_s16_14_hex_array(x):
    scale = 1 << 14   # 2^14

    # Convert to fixed-point integer
    x_fixed = np.round(x * scale).astype(np.int32)

    # Valid S16.14 range:
    # sign(1) + int(1) + frac(14) → range = [-2, 1.9999...]
    min_val = -2**15        # -16384   (2's complement min for 16-bit)
    max_val =  2**15 - 1    # 16383

    # Clip to valid range
    x_fixed = np.clip(x_fixed, min_val, max_val)

    hex_strings = []
    for val in x_fixed:
        # Convert to 16-bit two's complement
        if val < 0:
            val = (1 << 16) + val
        hex_strings.append(f"{val:04X}")  # 4 hex digits

    return hex_strings

# Example usage
x = np.array([1, 1.6180137633, 0.9999720002, 1.5694929691, 0.94090], dtype=np.float64)
hex_array = float_to_s16_14_hex_array(x)
print(hex_array)

# b1_0 = (1)
# b1_1 = (1.6180137633)
# b1_2 = (0.9999720002)
# a1_1 = (1.5694929691)
# a1_2 = (0.94090)

# b2_0 = (1)
# b2_1 = (-0.99998750)
# b2_2 = (0.9999750002)
# a2_1 = (-0.970)
# a2_2 = (0.94090)