# Text Transmission via ADALM-PLUTO SDR 

![MATLAB](https://img.shields.io/badge/MATLAB-R2025a-blue.svg)
![SDR](https://img.shields.io/badge/Hardware-ADALM--PLUTO-orange.svg)

## Project Overview
This repository contains the MATLAB implementation of a complete **Software Defined Radio (SDR) digital communication link** using two **ADALM-PLUTO** devices. The system allows users to input a text message via the terminal, encode it, transmit it over the air, and successfully decode it at the receiver. 

The project evaluates the system's performance across different physical environments and distances, analyzing the effects of Free-Space Path Loss (FSPL) and AWGN on the signal constellation.

## System Architecture & Key Features

The communication chain is built from scratch in MATLAB and includes the following Digital Signal Processing (DSP) blocks:

### Transmitter (Tx)
* **Text-to-Bit Conversion & Framing:** Terminal input is converted into a bitstream. A known preamble (Header) is prepended for frame synchronization.
* **Channel Coding:** Applied to improve link reliability in noisy environments.
* **Modulation:** Binary Phase Shift Keying (BPSK).
* **Pulse Shaping:** Root Raised Cosine (RRC) filter to limit spectral occupancy and mitigate Inter-Symbol Interference (ISI).

### Receiver (Rx)
* **Matched Filtering:** RRC filtering to maximize the Signal-to-Noise Ratio (SNR) at the decision instants.
* **Symbol Timing Recovery (Gardner TED):** A Non-Data-Aided Gardner Timing Error Detector is used to recover the correct sampling clock asynchronously. The loop stability was analytically verified via **S-Curve** extraction.
* **Frame & Phase Synchronization:** Cross-correlation between the received signal and the known Header is performed to find the exact frame start. The complex angle of the correlation peak is used to correct the static phase offset ($\phi_{err}$) caused by propagation delay and PLL differences.
* **Automatic Gain Control (AGC):** Dynamically adjusts the receiver gain to prevent clipping.

## Experimental Results & Environment Testing
The system was tested in various indoor and outdoor scenarios to observe electromagnetic propagation effects:
- **Constellation Dispersion:** Demonstrated how increasing the Tx-Rx distance degrades the SNR, turning the ideal BPSK points into dispersed AWGN "clouds".
- **Phase Rotation:** Analyzed the phase shift introduced by the physical distance (fractions of wavelength $\lambda$) and successfully compensated it in software.

## How to Run
1. Connect two ADALM-PLUTO devices to your PC (or two different PCs).
2. Ensure the Communications Toolbox and the Communications Toolbox Support Package for ADALM-PLUTO Radio are installed in MATLAB.
3. Run the transmitter script `Tx.m` type your message in the terminal, and press Enter to transmit.
4. Run the receiver script `Rx.m`, and read the message!

## Documentation
For a deep dive into the theoretical analysis, Gardner TED S-Curve, and constellation plots, please refer to the project presentation and relation (they're in italian!):
- [Download Project Presentation (PDF)](Presentazione_SdC.pdf)
- [Download Project Relation (PDF)](relazioneProvaFinale_SdC.pdf)
