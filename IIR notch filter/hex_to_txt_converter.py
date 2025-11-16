def s16_14_to_float(value_16bit):
    """Convert a 16-bit S16.14 fixed-point value to float."""
    # Convert unsigned 16-bit to signed (two's complement)
    if value_16bit & 0x8000:
        value_16bit -= 0x10000
    
    return value_16bit / float(1 << 14)


def convert_file_s16_14_to_float(input_hex_file, output_txt_file):
    floats = []

    # Read the hex file
    with open(input_hex_file, "r") as f:
        for line in f:
            hex_str = line.strip()
            if hex_str == "":
                continue
            
            value_16bit = int(hex_str, 16)
            float_val = s16_14_to_float(value_16bit)
            floats.append(float_val)

    # Save floats into .txt file
    with open(output_txt_file, "w") as f:
        for num in floats:
            f.write(f"{num}\n")

    print(f"Conversion complete. Saved to: {output_txt_file}")


# Example usage:
convert_file_s16_14_to_float("data_out.hex", "new_output.txt")
convert_file_s16_14_to_float("data_in.hex", "input_DUT.txt")
# convert_file_s16_14_to_float("golden_model.hex", "golden_model.txt")