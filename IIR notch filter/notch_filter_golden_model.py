import numpy as np
import matplotlib.pyplot as plt
from numpy.fft import fft, fftfreq
from scipy.signal import sosfilt # <-- Import for applying the filter

# --- 1. Filter Definition (Same as your golden model) ---
Fs = 6_000_000
notches = [
    {'f0': 2.4e6, 'r': 0.970, 'rz': 0.9999875},
    {'f0': 5e6, 'r': 0.970, 'rz': 0.9999875}
]

# Filter function (same as yours)
def notch_biquad_coeffs(f0, Fs, rp, rz):
    w0 = 2*np.pi*f0/Fs
    c = np.cos(w0)
    b0, b1, b2 = 1.0, -2.0*rz*c, 1.0*rz*rz
    a1, a2 = -2.0*rp*c, rp*rp
    return np.array([b0,b1,b2,a1,a2], dtype=float)

# --- 2. Calculate and Print Filter Coefficients ---
# (This section is updated to be clearer)

# Calculate coefficients for each notch
coeffs_f1_notch = notch_biquad_coeffs(notches[0]['f0'], Fs, notches[0]['r'], notches[0]['rz'])
coeffs_f2_notch = notch_biquad_coeffs(notches[1]['f0'], Fs, notches[1]['r'], notches[1]['rz'])

# Store them in the list your original code used
biquads_float_original = [coeffs_f1_notch, coeffs_f2_notch]

print("\n" + "="*40)
print("--- Filter Coefficient Report ---")
print("="*40)

print(f"\nCoefficients for {notches[0]['f0']/1e6} MHz Notch [b0, b1, b2, a1, a2]:")
print(f" b0 = {coeffs_f1_notch[0]:.10f}")
print(f" b1 = {coeffs_f1_notch[1]:.10f}")
print(f" b2 = {coeffs_f1_notch[2]:.10f}")
print(f" a1 = {coeffs_f1_notch[3]:.10f}")
print(f" a2 = {coeffs_f1_notch[4]:.10f}")

print(f"\nCoefficients for {notches[1]['f0']/1e6} MHz Notch [b0, b1, b2, a1, a2]:")
print(f" b0 = {coeffs_f2_notch[0]:.10f}")
print(f" b1 = {coeffs_f2_notch[1]:.10f}")
print(f" b2 = {coeffs_f2_notch[2]:.10f}")
print(f" a1 = {coeffs_f2_notch[3]:.10f}")
print(f" a2 = {coeffs_f2_notch[4]:.10f}")


# --- 3. Format Coefficients for SciPy 'sosfilt' ---
# sosfilt expects a NumPy array of shape (n_sections, 6)
# where each row is [b0, b1, b2, a0, a1, a2]
# Your function assumes a0 = 1.0
sos = []
for c in biquads_float_original:
    b0, b1, b2, a1, a2 = c
    sos.append([b0, b1, b2, 1.0, a1, a2])
sos = np.array(sos)

print("\n--- Coefficients (SciPy 'sos' Format) ---")
print(f"Shape: {sos.shape} (N_sections, 6)")
print("Rows are: [b0, b1, b2, a0, a1, a2]")
print(sos)
print("="*40 + "\n")


# --- 4. (Optional) Verify Filter Frequency Response ---
# (This section was numbered 3 in the previous code)
Nfft_resp = 32768
f_resp = np.linspace(0, Fs/2, Nfft_resp)

def H_biquad(freqs, coeffs_list):
    w = 2*np.pi*freqs/Fs
    H = np.ones_like(w, dtype=complex)
    for c in coeffs_list: # Using the original list format
        b0,b1,b2,a1,a2 = c
        ejw = np.exp(-1j*w); ej2w = np.exp(-1j*2*w)
        num = b0 + b1*ejw + b2*ej2w
        den = 1.0 + a1*ejw + a2*ej2w
        H *= num/den
    return H

H = H_biquad(f_resp, biquads_float_original)

plt.figure(figsize=(10,5))
plt.title("Golden Model Frequency Response (Design)")
# ... (rest of the plotting code) ...
plt.plot(f_resp/1e6, 20*np.log10(np.abs(H)+1e-12))
plt.xlabel("Frequency (MHz)"); plt.ylabel("Magnitude (dB)")
plt.ylim(-100, 5); plt.grid(True)
plt.axvline(notches[0]['f0']/1e6, color='r', linestyle='--', label=f"Notch 1: {notches[0]['f0']/1e6} MHz")
plt.axvline(notches[1]['f0']/1e6, color='g', linestyle='--', label=f"Notch 2: {notches[1]['f0']/1e6} MHz")
plt.legend()
plt.show()


# --- 5. Load Signal from File ---
# (This section was numbered 4 in the previous code)
input_filename = 'input_DUT.txt' 
try:
    signal_in = np.loadtxt(input_filename)
    print(f"\nSuccessfully loaded {len(signal_in)} samples from '{input_filename}'.")
except IOError:
    print(f"\n--- WARNING: Could not read '{input_filename}'. ---")
    print("Creating a dummy signal for demonstration purposes.")
    # Create a dummy signal with components at the notch frequencies + a good signal
    N_samples = 8192
    t = np.arange(N_samples) / Fs
    f_noise1 = notches[0]['f0'] # 2.4 MHz
    f_noise2 = notches[1]['f0'] # 5.0 MHz
    f_good = 1.0e6              # 1.0 MHz
    signal_in = (
        0.8 * np.sin(2 * np.pi * f_good * t) +    # "Good" signal
        1.0 * np.sin(2 * np.pi * f_noise1 * t) +  # "Noise" to be notched
        1.0 * np.sin(2 * np.pi * f_noise2 * t) +  # "Noise" to be notched
        0.1 * np.random.randn(N_samples)         # Background noise
    )
    np.savetxt(input_filename, signal_in) # Save the dummy signal
    print(f"Dummy signal with noise at 2.4MHz and 5MHz saved to '{input_filename}'.")
    print("Please re-run the script to use this new file.")


# --- 6. Apply the Filter ---
# (This section was numbered 5 in the previous code)
print("Applying filter to the signal...")
signal_out = sosfilt(sos, signal_in)
print("Filtering complete.")

print(f"\n--- Signal Output Range ---")
print(f"Min Amplitude: {np.min(signal_out):.10f}")
print(f"Max Amplitude: {np.max(signal_out):.10f}")
print("---------------------------\n")

# --- 7. Save Filtered Signal to File ---
# (This section was numbered 6 in the previous code)
output_filename = 'golden_model.txt'
np.savetxt(output_filename, signal_out, fmt='%.18e') # Use high precision
print(f"Filtered signal saved to '{output_filename}'.")

# --- 8. Plot Input vs. Output (Time Domain) ---
# (This section was numbered 7 in the previous code)
plt.figure(figsize=(12, 6))
plt.title("Signal in Time Domain (First 500 samples)")
# Plotting fewer points for clarity
plot_len = min(len(signal_in), 500) 
t_axis = np.arange(plot_len) / Fs * 1e6 # Time in microseconds
plt.plot(t_axis, signal_in[:plot_len], label='Input Signal (from file.txt)', alpha=0.7)
plt.plot(t_axis, signal_out[:plot_len], label='Filtered Signal (output_signal.txt)', alpha=0.9)
plt.xlabel("Time (microseconds)")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True)
plt.show()

# --- 9. Plot Input vs. Output (Frequency Domain) ---
# (This section was numbered 8 in the previous code)
# Calculate FFTs
N_fft = len(signal_in)
freq_axis = fftfreq(N_fft, 1/Fs)

fft_in = fft(signal_in)
fft_out = fft(signal_out)

# Get positive frequencies for plotting
positive_freq_mask = (freq_axis >= 0) & (freq_axis <= Fs/2)
f_plot = freq_axis[positive_freq_mask] / 1e6 # Freq in MHz
# Normalize magnitude
fft_in_mag = 20 * np.log10(np.abs(fft_in[positive_freq_mask]) / N_fft)
fft_out_mag = 20 * np.log10(np.abs(fft_out[positive_freq_mask]) / N_fft)

plt.figure(figsize=(12, 6))
plt.title("Signal in Frequency Domain (FFT)")
plt.plot(f_plot, fft_in_mag, label='Input Spectrum (from file.txt)', alpha=0.7)
plt.plot(f_plot, fft_out_mag, label='Filtered Spectrum (output_signal.txt)')

# Mark the notches
plt.axvline(notches[0]['f0']/1e6, color='r', linestyle='--', label=f"Notch 1: {notches[0]['f0']/1e6} MHz")
plt.axvline(notches[1]['f0']/1e6, color='g', linestyle='--', label=f"Notch 2: {notches[1]['f0']/1e6} MHz")

plt.xlabel("Frequency (MHz)")
plt.ylabel("Magnitude (dB)")
plt.ylim(np.max(fft_in_mag) - 100, np.max(fft_in_mag) + 5) # Dynamic y-axis
plt.legend()
plt.grid(True)
plt.show()