import numpy as np
import matplotlib.pyplot as plt
from numpy.fft import fft, fftfreq
from scipy.signal import sosfilt # <-- Import for applying the filter
class Notch_Filter:
    def __init__(self, FS, notches):
        self.Fs = FS
        self.notches = notches
    def notch_biquad_coeffs(self, f0, Fs, rp, rz):
        w0 = 2*np.pi*f0/Fs
        c = np.cos(w0)
        b0, b1, b2 = 1.0, -2.0*rz*c, 1.0*rz*rz
        a1, a2 = -2.0*rp*c, rp*rp
        return np.array([b0,b1,b2,a1,a2], dtype=float)
    
    def Calculate_filter_coefficients(self):
        # Calculate coefficients for each notch
        coeffs_f1_notch = self.notch_biquad_coeffs(self.notches[0]['f0'], self.Fs, self.notches[0]['r'], self.notches[0]['rz'])
        coeffs_f2_notch = self.notch_biquad_coeffs(self.notches[1]['f0'], self.Fs, self.notches[1]['r'], self.notches[1]['rz'])

        # Store them in the list your original code used
        biquads_float_original = [coeffs_f1_notch, coeffs_f2_notch]
        return biquads_float_original
    

    def print_filter_coefficients(self):
        filter_coeff = self.Calculate_filter_coefficients()
        print("\n" + "="*40)
        print("--- Filter Coefficient Report ---")
        print("="*40)
        i = 0
        for filter in filter_coeff:
            print(f"\nCoefficients for {self.notches[i]['f0']/1e6} MHz Notch [b0, b1, b2, a1, a2]:")
            print(f" b0 = {filter[0]:.10f}")
            print(f" b1 = {filter[1]:.10f}")
            print(f" b2 = {filter[2]:.10f}")
            print(f" a1 = {filter[3]:.10f}")
            print(f" a2 = {filter[4]:.10f}")
            i += 1

    def Filter_Response(self):
        filter_coeff = self.Calculate_filter_coefficients()
        Nfft_resp = 32768
        f_resp = np.linspace(0, self.Fs/2, Nfft_resp)

        w = 2*np.pi*f_resp/self.Fs
        H = np.ones_like(w, dtype=complex)
        for c in filter_coeff: # Using the original list format
            b0,b1,b2,a1,a2 = c
            ejw = np.exp(-1j*w); ej2w = np.exp(-1j*2*w)
            num = b0 + b1*ejw + b2*ej2w
            den = 1.0 + a1*ejw + a2*ej2w
            H *= num/den

        plt.figure(figsize=(10,5))
        plt.title("Golden Model Frequency Response (Design)")
        # ... (rest of the plotting code) ...
        plt.plot(f_resp/1e6, 20*np.log10(np.abs(H)+1e-12))
        plt.xlabel("Frequency (MHz)"); plt.ylabel("Magnitude (dB)")
        plt.ylim(-100, 5); plt.grid(True)
        plt.axvline(self.notches[0]['f0']/1e6, color='r', linestyle='--', label=f"Notch 1: {self.notches[0]['f0']/1e6} MHz")
        plt.axvline(self.notches[1]['f0']/1e6, color='g', linestyle='--', label=f"Notch 2: {self.notches[1]['f0']/1e6} MHz")
        plt.legend()
        plt.show()

    def apply_notch_filter(self, filter_coeff, x_n):
               
        b0, b1, b2, a1, a2 = filter_coeff
        y_n = np.zeros(len(x_n))
        for n in range(len(x_n)):
            if(n >= 2):
                y_n[n] = b0*x_n[n] + b1*x_n[n-1] + b2*x_n[n-2] - a1*y_n[n-1] - a2*y_n[n-2]

            elif(n >= 1):
                y_n[n] = b0*x_n[n] + b1*x_n[n-1] - a1*y_n[n-1]
            else:
                y_n[n] = b0*x_n[n]

            y_n[n] = y_n[n]
        return y_n

    def output_range(self, filter_output):
        filter_output_float = [sample / (1 << 14) for sample in filter_output]
        print(f"\n--- Signal Output Range ---")
        print(f"Min Amplitude: {np.min(filter_output_float):.10f}")
        print(f"Max Amplitude: {np.max(filter_output_float):.10f}")
        print("---------------------------\n")

    def notch_plot(self, notch_input, notch_output) :

        ### fft of xt for plotting
        notch_input_fft = np.fft.fft(notch_input)
        notch_input_fft_freq = np.fft.fftfreq(notch_input_fft.size, 1/self.Fs)


        ### fft of xf_d for plotting
        notch_output_fft = np.fft.fft(notch_output)
        notch_output_fft_freq = np.fft.fftfreq(notch_output_fft.size, 1/self.Fs)
        
        # == Time Domain == #
        plt.figure("Notch Filter", figsize=(10, 6))
        plt.subplot(2, 2, 1)
        plt.stem(notch_input[:100])
        plt.title("Notch Filter Input (6Mhz)")
        plt.grid()

        plt.subplot(2, 2, 2)
        plt.title("Notch Filter Output (6Mhz)")
        plt.stem(notch_output[:100])
        plt.grid()
        # == Freq Domain == #
        plt.subplot(2, 2, 3)
        plt.plot(notch_input_fft_freq, 20 * np.log10(np.abs(notch_input_fft)/len(notch_input_fft)))
        plt.grid()

        plt.subplot(2, 2, 4)
        plt.plot(notch_output_fft_freq, 20 * np.log10(np.abs(notch_output_fft)/len(notch_output_fft)))
        plt.grid()
        plt.savefig('./Model_Output/Figures/Notch_Filter.png')

