# Mathematical Model

[← README](../README.md)

Every equation in sections 1–4 is used by [`matlab/two_step_adc_model.m`](../matlab/two_step_adc_model.m). Section 5 is clearly marked as theoretical background.

## 1. Parameters

```
N       = 8        bits, total resolution
N_stage = 4        bits per stage
Vref    = 2 V      reference = full-scale input
```

## 2. Derived step sizes

```
LSB    = Vref / 2^N        = 2 / 256 = 0.0078125 V = 7.8125 mV
LSB_c  = Vref / 2^N_stage  = 2 / 16  = 0.125 V
G      = 2^N_stage         = 16                      (residue gain)
LSB_c / G                  = 7.8125 mV = LSB          (fine step referred to the input)
```

The report writes `LSB_fine` for the fine stage. In the code the fine stage divides by `LSB_c`. The two are equal because the amplified residue spans the full `Vref`.

## 3. Conversion (per input sample)

```
D_coarse  = min( ⌊Vin / LSB_c⌋ , 2^N_stage − 1 )
V_DAC     = D_coarse · LSB_c
V_res     = (Vin − V_DAC) · 2^N_stage
D_fine    = min( ⌊V_res / LSB_c⌋ , 2^N_stage − 1 )
D_out     = D_coarse · 2^N_stage + D_fine
```

For `0 ≤ Vin ≤ Vref` this reduces to `D_out = min(⌊Vin / LSB⌋, 2^N − 1)` (derivation in [two-step-operation.md](two-step-operation.md#why-the-two-step-result-equals-a-direct-8-bit-quantization)).

## 4. Linearity extraction

With the swept input `Vin = 0 : 0.001 : Vref` (2001 points):

```
T_k        = min{ Vin_i : D_out(Vin_i) ≥ k },      k = 0 … 255   (transition voltage of code k)
step_k     = T_k − T_(k−1),                          k = 1 … 255
DNL_0      = 0
DNL_k      = (step_k − LSB) / LSB,                   k = 1 … 255
INL_k      = Σ_(j=0..k) DNL_j  =  (T_k − T_0)/LSB − k  =  (T_k − k·LSB)/LSB    (T_0 = 0)
```

Notes on the definitions as implemented:

- `T_0 = 0 V` is the start of the sweep, not a real transition. `DNL_0` is set to 0 by construction.
- `DNL_k` is plotted at code `k`, but it describes the spacing between transitions k−1 and k, which is the width of code **k − 1**. The width of the last code (255) is not evaluated.
- INL is referenced to the **ideal transition positions `k·LSB`** of a `floor` quantizer. There is no end-point or best-fit line correction.

### Effect of the sweep step (derived)

With a sweep step `h`, the measured transition is the first grid point at or above the ideal edge:

```
T_k(measured) = h · ⌈ k·LSB / h ⌉
INL_k         = (h·⌈k·LSB/h⌉ − k·LSB) / LSB   ∈ [0, h/LSB)
```

For `h = 1 mV`, `h/LSB = 0.128`, so INL can lie only in [0, 0.128) LSB. The observed maximum is 0.120 LSB. Every measured step is 7 mV or 8 mV, which gives DNL = −0.104 or +0.024 LSB. `k·LSB` is a multiple of 1 mV every 16 codes (16 × 7.8125 mV = 125 mV), so the pattern repeats every 16 codes. When `h` divides `LSB` exactly (e.g. `LSB/8`), the error is identically 0. The Octave run of [`matlab/sweep_step_study.m`](../matlab/sweep_step_study.m) confirms all of this.

## 5. Theoretical background (not used by the model)

- **Comparator count:** full flash `2^N − 1`; two-step `2·(2^N_stage − 1)`. At N = 8, N_stage = 4: 255 vs. 30.
- **Quantization error** of this `floor` quantizer: `e = Vin − D_out·LSB ∈ [0, LSB)`. A mid-tread (round-to-nearest) quantizer would shift the transitions by ½ LSB to get `e ∈ [−½, ½) LSB`. The model does not do this.
- **Missing-code condition:** code k is missing when `DNL_k = −1` (zero width). `DNL > −1` for every code means no missing codes.

Next: [code-walkthrough.md](code-walkthrough.md)
