import numpy as np
import matplotlib.pyplot as plt
from numpy.fft import fft, fftfreq
from scipy.signal import sosfilt # <-- Import for applying the filter

import Fractional_Decimator as FD
import Notch_Filter as NF
import CIC_Filter as CIC




#  ======================= input stream ======================= #
N = 10000  # No. samples
Fs = 9e6   # input sampling freq
Ts =1/Fs  
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
xt_fp = [round(sample * (1 << 15)) for sample in xt_raw]

with open("input_vectors.txt", "w") as f:
    for item in xt_fp:
        f.write(f"{(hex(item & 0xFFFF)[2:])}\n")


# ======================================= Decimator =============================================== #
L = 2      # UP sample factor
M = 3      # Down sample factor

decimator_input = xt_fp

dec = FD.Fractional_Decimator(Fs, L, M)

decimator_output = dec.decimator(decimator_input)

with open("FD_output.txt", "w") as f:
    for item in decimator_output:
        f.write(f"{(hex(int(item) & 0xFFFF)[2:])}\n")

dec.decimator_plot(decimator_input, decimator_output)

# ====================================================================================== #


# ======================================= Notch Filter =============================================== #


# change from S16.15 to S16.14
notch_input = [int(item) >> 1 for item in decimator_output]
with open("notch_input.txt", "w") as f:
    for item in notch_input:
        f.write(f"{(hex(int(item) & 0xFFFF)[2:])}\n")
notches = [
    {'f0': 2.4e6, 'r': 0.970, 'rz': 0.9999875},
    {'f0': 5e6, 'r': 0.970, 'rz': 0.9999875}
]

notch_filter = NF.Notch_Filter(FS = 6e6, notches = notches)

filter_coeff = notch_filter.Calculate_filter_coefficients()
# notch_filter.print_filter_coefficients()
# notch_filter.Filter_Response()


y1_n = notch_filter.apply_notch_filter(filter_coeff[0], notch_input)
notch_output = notch_filter.apply_notch_filter(filter_coeff[1], y1_n)
# notch_filter.output_range(notch_output)


with open("Notch_output.txt", "w") as f:
    for item in notch_output:
        f.write(f"{(hex(int(item) & 0xFFFF)[2:])}\n")



notch_filter.notch_plot( notch_input, notch_output)
# ====================================================================================== #


# =====================CIC=====================#
# change from S16.14 to S16.15
cic_in = [int(item) << 1 for item in notch_output]

D = 1
FS = 6e6
cic_filter = CIC.CIC_Filter(FS, D)

INT_stage_1 = cic_filter.INT_Stage(cic_in)
INT_stage_2 = cic_filter.INT_Stage(INT_stage_1)
INT_stage_3 = cic_filter.INT_Stage(INT_stage_2)

COMB_Stage_1 = cic_filter.COMB_Stage(INT_stage_3)
COMB_Stage_2 = cic_filter.COMB_Stage(COMB_Stage_1)
COMB_Stage_3 = cic_filter.COMB_Stage(COMB_Stage_2)

COMB_stage_3_down = cic_filter.down_sample(COMB_Stage_3)

cic_filter.cic_plot(notch_output, COMB_stage_3_down)


with open("CIC_output.txt", "w") as f:
    for item in COMB_stage_3_down:
        f.write(f"{(hex(int(item) & 0xFFFF)[2:])}\n")





# filtered_sig = cic_filter.fir_LPF(COMB_stage_3_down)

# cic_filter.Comp_fir_plot(COMB_stage_3_down, filtered_sig)
plt.show()

