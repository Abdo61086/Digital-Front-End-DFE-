import numpy as np
import matplotlib.pyplot as plt

import Fractional_Decimator as FD

N = 10000  # No. samples
L = 2      # UP sample factor
M = 3      # Down sample factor
Fs = 9e6   # input sampling freq
Ts =1/Fs   


#  ======================= input stream ======================= #

# Test tones
f_tone_1 = 1e6
f_tone_2 = 2e6

f_tone_3 = 2.4e6
f_tone_4 = 5e6


t = np.arange(0, N*Ts, Ts)

# Data stream before quantization
xt_raw = 0.4*np.sin(2 * np.pi * f_tone_1 * t) + 0.3*np.sin(2 * np.pi * f_tone_2 * t) + 0.2*np.sin(2 * np.pi * f_tone_3 * t) + 0.1*np.sin(2 * np.pi * f_tone_4 * t)

# xt_fp = [fp.FixedPoint(sample, 1, 1, 15) for sample in xt_raw]

# Data stream After quantization
# xt = [float(sample) for sample in xt_fp]

xt_fp = [round(sample * (1 << 15)) for sample in xt_raw]
with open("input_vectors.txt", "w") as f:
    for item in xt_fp:
        f.write(f"{(hex(item & 0xFFFF)[2:])}\n")


#  ======================= Digital Front End (DFE) Filter Array  ======================= #

dec = FD.Fractional_Decimator()


xt_d = dec.decimator(xt_fp, L, M)






# ====================================================================================== #







#  ======================= Plots ======================= #
xt_float = [sample / (1 << 15) for sample in xt_fp]
xt_d_float = [sample / (1 << 15) for sample in xt_d]



### fft of xt for plotting
xf = np.fft.fft(xt_float)

xf_freq = np.fft.fftfreq(xf.size, Ts)


### fft of xf_d for plotting
xf_d = np.fft.fft(xt_d_float)
xf_d_freq = np.fft.fftfreq(len(xt_d), M*Ts/L)

# == Time Domain == #
plt.subplot(2, 2, 1)
plt.stem(xt_float[:100])
plt.title("Input Stream (9Mhz)")
plt.grid()

plt.subplot(2, 2, 2)
plt.title("Input Stream (Down Sampled 6Mhz)")
plt.stem(xt_d[:100])
plt.grid()


# # == Freq Domain == #
plt.subplot(2, 2, 3)
plt.title("Input Stream (9Mhz)")
plt.plot(xf_freq, np.abs(xf))
plt.grid()

plt.subplot(2, 2, 4)
plt.title("Input Stream (Down Sampled 6Mhz)")
plt.plot(xf_d_freq, np.abs(xf_d))
plt.grid()



plt.show()