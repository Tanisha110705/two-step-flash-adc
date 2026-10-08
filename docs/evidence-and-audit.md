# Evidence and Audit

[← README](../README.md)

This page records where each claim in the repository comes from and what was checked.

## Starting point

When this documentation was written, the repository was **empty** (no commits). The only project evidence was the course report *"Mixed Signal Circuit Design – Theory DA-2"* (8 pages), which contains:

- the architecture description and comparator analysis;
- the complete MATLAB source, now [`matlab/two_step_adc_model.m`](../matlab/two_step_adc_model.m), transcribed verbatim;
- a screenshot of the MATLAB output figure, now [`assets/report-original-matlab-output.png`](../assets/report-original-matlab-output.png);
- written DNL/INL observations and interpretations.

The report PDF is not committed, because it contains personal and institutional details (registration number, course slot).

## Confirmed by both report and model run

| Item | Value |
|---|---|
| Resolution, partition | 8 bit = 4 + 4 |
| Vref, input range | 2 V, 0–2 V |
| Output | codes 0–255, 256 levels |
| Algorithm | `D_coarse = ⌊Vin/LSB_c⌋` (clamped), `V_dac = D_coarse·LSB_c`, `V_res = (Vin − V_dac)·16`, `D_fine = ⌊V_res/LSB_c⌋` (clamped), `D_out = 16·D_coarse + D_fine` |
| DNL | −0.104 … +0.024 LSB (report: −0.10 … +0.02) |
| INL | 0 … +0.120 LSB (report: ≈0 … +0.12) |
| Missing codes | none |
| Figure shapes | two-level DNL, sawtooth INL, three teeth every 16 codes |

## Confirmed by calculation

| Item | Value |
|---|---|
| LSB | 2/256 = 7.8125 mV |
| LSB_c | 2/16 = 0.125 V |
| Comparators | 255 (flash) vs. 30 (two-step), 88.2 % fewer |
| Two-step output = direct 8-bit `floor` | all 2001 swept points |

## Added by this repository's analysis

| Item | Evidence |
|---|---|
| Monotonic output on the sweep | `run_linearity_analysis.m` |
| Measured step widths are only 7 mV and 8 mV | `run_linearity_analysis.m` |
| DNL/INL → 0 for LSB-aligned sweeps | `sweep_step_study.m` |
| MATLAB vs. Octave colon-grid differences change no codes | Python check during audit |

## Report vs. model inconsistencies

1. **Cause of the DNL/INL pattern.** The report attributes the repeating DNL/INL pattern to capacitor mismatch, comparator imbalance and residue-stage gain error. The model contains none of these. The pattern comes entirely from the 1 mV sweep step against the 7.8125 mV LSB, and it disappears with an LSB-aligned sweep.
2. **"Comparators … working perfectly".** The report draws this conclusion from the small DNL. The model has no comparators to evaluate; each stage is an ideal `floor()`.
3. **DNL range in the Results bullets.** The bullets say the step error ranges from "about −0.10" to "about 0.10". The report's own DNL summary and the model run both give a maximum of +0.02 (+0.024).
4. **INL minimum.** The report says "slightly negative, very small", while the Octave run gives exactly 0. A tiny negative value from MATLAB floating-point rounding is possible but could not be checked without MATLAB.
5. **Missing-code reasoning.** The report says "since the difference in steps is less than 1 unit, the ADC always increases and does not miss codes". The no-missing-code condition is DNL > −1 LSB, and monotonicity needs its own check. Both were verified directly here.
6. **`LSB_fine`.** The report's equation uses `LSB_fine`, but the code uses `LSB_c` for the fine stage. They are equal (0.125 V) because of the ×16 residue gain, so the results are not affected.
7. **Power / area / speed.** The report states "lower power consumption", "chip area is reduced" and rates speed "High". None of these was simulated or measured. Only the comparator count is supported.
8. **Block list.** The report's block list names the coarse ADC, DAC, subtractor and gain amplifier but leaves out the fine ADC, which the code includes.

## Claims this repository does not make

- No transistor-level, schematic or layout implementation exists.
- No silicon, fabricated chip, hardware prototype or bench measurement.
- No measured or simulated power, area, speed or latency.
- No SNDR, ENOB, SFDR, noise, PVT or Monte Carlo results.
- No claim that 0.10 LSB DNL / 0.12 LSB INL describes physical converter linearity.
- No claim that mismatch, offset or gain errors were modeled.

## Privacy check

The committed files contain no local file paths, institutional identifiers or unrelated personal material. The report screenshot shows only the MATLAB figure window.
