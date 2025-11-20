import numpy as np
import matplotlib.pyplot as plt

class CIC_Filter:
    def __init__(self, FS, D):
        self.D = D
        self.Fs = FS
        self.taps_D1  = [-0.0053, -0.0028, 0.0190, 0.0118, -0.0352, -0.0065, 0.0763, -0.0120, -0.1568, 0.0796, 0.5415, 0.5415, 0.0796, -0.1568, -0.0120, 0.0763, -0.0065, -0.0352, 0.0118, 0.0190, -0.0028, -0.0053];
        self.taps_D2  = [-5.0702e-04, 0.0106, 0.0185, -0.0142, -0.0311, 0.0398, 0.0504, -0.1014, -0.0817, 0.3225, 0.6024, 0.3225, -0.0817, -0.1014, 0.0504, 0.0398, -0.0311, -0.0142, 0.0185, 0.0106, -5.0702e-04];
        self.taps_D4  = [-0.0052, -0.0027, 0.0186, 0.0114, -0.0345, -0.0061, 0.0746, -0.0125, -0.1534, 0.0816, 0.5375, 0.5375, 0.0816, -0.1534, -0.0125, 0.0746, -0.0061, -0.0345, 0.0114, 0.0186, -0.0027, -0.0052];
        self.taps_D8  = [-0.0053, -0.0028, 0.0189, 0.0117, -0.0350, -0.0064, 0.0758, -0.0122, -0.1560, 0.0801, 0.5405, 0.5405, 0.0801, -0.1560, -0.0122, 0.0758, -0.0064, -0.0350, 0.0117, 0.0189, -0.0028, -0.0053];
        self.taps_D16 = [-0.0053, -0.0028, 0.0189, 0.0118, -0.0352, -0.0064, 0.0762, -0.0121, -0.1566, 0.0797, 0.5412, 0.5412, 0.0797, -0.1566, -0.0121, 0.0762, -0.0064, -0.0352, 0.0118, 0.0189, -0.0028, -0.0053];
    
    def fir_LPF(self, input_signal):
        match self.D:
            case 1:
                filter_coeff = self.taps_D1 
            case 2:
                filter_coeff = self.taps_D2

            case 4:
                filter_coeff = self.taps_D4 

            case 8:
                filter_coeff = self.taps_D8

            case 16:
                filter_coeff = self.taps_D16

        LPF_coeff_fp = [round(sample * (1 << 15)) for sample in filter_coeff]

        with open("filter_coeff_dddd1.txt", "w") as f:
            for item in LPF_coeff_fp:
             f.write(f"{(hex(item & 0xFFFF)[2:])}\n")

        filtered_signal = np.zeros(len(LPF_coeff_fp) + len(input_signal) - 1)
        for n in range(len(LPF_coeff_fp) + len(input_signal) - 1):
            y_n = 0
            for k in range(len(LPF_coeff_fp)):
                if 0 <= n-k < len(input_signal) :
                    y_n += (LPF_coeff_fp[k]) * (int(input_signal[n-k]))
                    
            filtered_signal[n] = y_n >> 15
        return filtered_signal        
    
    def INT_Stage(self, stage_in):
        stage_out = np.zeros(len(stage_in))
        for n in range(len(stage_in)):
            if(n>=1):
                stage_out[n] = stage_in[n] + stage_out[n-1]
            else:
                stage_out[n] = stage_in[n]
        return stage_out
    
    def COMB_Stage(self, stage_in):
        stage_out = np.zeros(stage_in.size)
        for n in range(stage_in.size):
            if(n>=1):
                stage_out[n] = stage_in[n] - stage_in[n-1]
            else:
                stage_out[n] = stage_in[n]
        return stage_out
    
    def down_sample(self, input_signal):
        input_signal_down = input_signal[0::self.D]
        return input_signal_down    
        
    def cic_plot(self, input_sig, output_sig) :
        input_sig_float = [sample / (1 << 15) for sample in input_sig]
        output_sig_float = [sample / (1 << 15) for sample in output_sig]

        ### fft of xt for plotting
        xf_in = np.fft.fft(input_sig_float)
        xf_in_freq = np.fft.fftfreq(xf_in.size, 1/self.Fs)
        
        ### fft of xf_d for plotting
        xf_out = np.fft.fft(output_sig_float)
        xf_out_freq = np.fft.fftfreq(len(xf_out), self.D/(self.Fs))

        # == Time Domain == #
        plt.figure("CIC Filter D = {}".format(self.D), figsize=(10, 6))
        plt.subplot(2, 2, 1)
        plt.stem(input_sig_float[:100])
        plt.title("CIC Filter input (6Mhz)")
        plt.grid()

        plt.subplot(2, 2, 2)
        plt.title("CIC Filter Output (6Mhz/{})".format(self.D))
        plt.stem(output_sig_float[:100])
        plt.grid()


        # == Freq Domain == #
        plt.subplot(2, 2, 3)
        plt.plot(xf_in_freq, 20 * np.log10(np.abs(xf_in)/len(xf_in)))
        plt.grid()

        plt.subplot(2, 2, 4)
        plt.plot(xf_out_freq, 20 * np.log10(np.abs(xf_out)/len(xf_out)))
        plt.grid()
        plt.savefig('./Model_Output/Figures/CIC_Filter_D_{}.png'.format(self.D))