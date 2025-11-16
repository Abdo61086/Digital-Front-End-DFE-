import numpy as np
import matplotlib.pyplot as plt
from numpy.fft import fft, fftfreq

# ---------------------- Config ----------------------
input_txt = "output_DUT.txt"  # your input file
Fs = 6_000_000          # sampling frequency in Hz
Nfft = 32768            # FFT points
# ----------------------------------------------------

# Read data from file
with open(input_txt, "r") as f:
    data = np.array([float(line.strip()) for line in f if line.strip()])

# Zero-pad or truncate to Nfft
if data.size < Nfft:
    x = np.zeros(Nfft)
    x[:data.size] = data
else:
    x = data[:Nfft]

# FFT
X = fft(x)
freqs = fftfreq(Nfft, d=1/Fs)

# Only take positive frequencies
X_mag = 20 * np.log10(np.abs(X[:Nfft//2]) + 1e-20)
f_pos = freqs[:Nfft//2]

# Plot
plt.figure(figsize=(10,5))
plt.plot(f_pos/1e6, X_mag)
plt.title("Magnitude Spectrum")
plt.xlabel("Frequency (MHz)")
plt.ylabel("Magnitude (dB)")
plt.grid(True)
plt.show()
