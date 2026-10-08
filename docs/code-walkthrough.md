# Code Walkthrough

[← README](../README.md)

[`matlab/two_step_adc_model.m`](../matlab/two_step_adc_model.m) is the project's MATLAB model, transcribed character-for-character from the project report. The other scripts wrap it and leave it unchanged.

## 1. Parameter setup

```matlab
clear; clc;
N = 8;              % total resolution
N_stage = 4;        % bits per stage
Vref = 2;           % reference / full scale (V)
LSB = Vref / (2^N); % 7.8125 mV
```

## 2. Input sweep

```matlab
Vin = 0:0.001:Vref;          % 2001 points, 1 mV apart, 0 … 2 V
D_out = zeros(size(Vin));    % pre-allocated output codes
```

The 1 mV step is about 0.128 LSB. Because it does not divide the LSB, it limits how precisely the transitions can be located (§8).

## 3–7. Conversion loop

```matlab
for i = 1:length(Vin)
   LSB_c = Vref / (2^N_stage);                  % 0.125 V (constant; recomputed every iteration)
   D_coarse = floor(Vin(i) / LSB_c);            % 3. coarse quantization
   D_coarse = min(D_coarse, 2^N_stage - 1);     %    clamp to 15 (only active at Vin = 2 V)
   V_dac = D_coarse * LSB_c;                    % 4. DAC reconstruction
   V_residue = (Vin(i) - V_dac) * (2^N_stage);  % 5. subtract + ×16 residue gain
   D_fine = floor(V_residue / LSB_c);           % 6. fine quantization (same step as coarse)
   D_fine = min(D_fine, 2^N_stage - 1);         %    clamp to 15
   D_out(i) = (D_coarse * 2^N_stage) + D_fine;  % 7. combine: upper nibble + lower nibble
end
```

- `floor` stands in for an ideal flash quantizer, and `min(…, 15)` stands in for saturation at the top code.
- Nothing is ever below 0 because the sweep starts at 0 V. Negative inputs are not handled.
- `LSB_c` is loop-invariant. Computing it inside the loop is harmless.

## 8. Code-transition extraction

```matlab
num_codes = 2^N;
code_transitions = zeros(1, num_codes);
for k = 0:num_codes-1
   idx = find(D_out >= k, 1);               % first sample at or above code k
   if ~isempty(idx)
       code_transitions(k+1) = Vin(idx);
   end
end
```

`code_transitions(k+1)` is the transition voltage `T_k`, rounded **up** to the 1 mV grid. If a code were never reached, `find` would return the first sample of a higher code, so a missing code would appear as a zero-width step (DNL = −1). The `isempty` branch only runs if the top code is never reached.

## 9. DNL

```matlab
actual_steps = diff(code_transitions);   % T_k − T_(k−1), k = 1…255
DNL = (actual_steps - LSB) / LSB;
DNL = [0, DNL];                          % pad so DNL has 256 entries; DNL(code 0) = 0
```

## 10. INL

```matlab
INL = cumsum(DNL);                       % = (T_k − k·LSB)/LSB because T_0 = 0
```

## 11. Plotting

```matlab
figure('Color', 'w');
subplot(2,1,1); plot(Vin, D_out, 'LineWidth', 1.5);           % transfer characteristic
subplot(2,1,2); plot(0:num_codes-1, DNL, 'b'); plot(..., INL, 'r');  % linearity
```

The script does not save the figure. The report includes a screenshot of it, kept as [`assets/report-original-matlab-output.png`](../assets/report-original-matlab-output.png).

## Supporting scripts (added in this repository)

| File | What it adds |
|---|---|
| [`run_linearity_analysis.m`](../matlab/run_linearity_analysis.m) | Calls `two_step_adc_model` and then, using its workspace variables, checks missing codes (`setdiff(0:255, unique(D_out))`) and monotonicity (`all(diff(D_out) >= 0)`). Prints the measured step widths, DNL/INL extremes and comparator counts, and writes `results/summary.txt` plus two CSVs. |
| [`two_step_adc_convert.m`](../matlab/two_step_adc_convert.m) | The same loop body as a function `D_out = two_step_adc_convert(Vin, N_stage, Vref)`. |
| [`transition_linearity.m`](../matlab/transition_linearity.m) | The same §8–10 code as a function `[T, DNL, INL] = transition_linearity(Vin, D_out, N, LSB)`. |
| [`sweep_step_study.m`](../matlab/sweep_step_study.m) | Runs the two functions for sweep steps 1 mV, 0.5 mV, 0.1 mV, 0.01 mV, LSB/8 and LSB/64. Writes `results/sweep-study/sweep_step_study.csv`. |
| [`python/make_figures.py`](../python/make_figures.py) | Re-implements the converter in NumPy, asserts that it reproduces all 2001 exported codes, then renders `assets/*.png` from the CSVs. |

Next: [linearity.md](linearity.md)
