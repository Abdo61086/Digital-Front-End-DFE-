import matplotlib.pyplot as plt

def plot_float_file(path):
    # Read floats from file
    with open(path, "r") as f:
        data = [float(line.strip()) for line in f if line.strip()]

    # Plot
    plt.figure()
    plt.plot(data)          # Do NOT specify colors (default only)
    plt.title("Floating-Point Data Plot - input - output from Verilog - output from golden model")
    plt.xlabel("Sample Index")
    plt.ylabel("Amplitude")
    plt.grid(True)
    plt.show()


# Example usage:
plot_float_file("input_DUT.txt")
plot_float_file("new_output.txt")
plot_float_file("golden_model_output.txt")