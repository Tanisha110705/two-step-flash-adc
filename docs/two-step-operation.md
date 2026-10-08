# Two-Step Conversion Sequence

[← README](../README.md)

![Conversion flow](../assets/two-step-flow.svg)

Parameters: `Vref = 2 V`, `N_stage = 4`, `LSB_c = Vref / 2^4 = 0.125 V`, `LSB = Vref / 2^8 = 7.8125 mV`.

## Sequence

| Step | Operation | Model line | Range |
|---|---|---|---|
| 1 | Apply input | `Vin(i)` from `0:0.001:Vref` | 0 … 2 V |
| 2 | Coarse quantization | `D_coarse = min(floor(Vin(i)/LSB_c), 2^N_stage-1)` | 0 … 15 |
| 3 | DAC reconstruction | `V_dac = D_coarse * LSB_c` | 0 … 1.875 V |
| 4 | Subtract | `Vin(i) - V_dac` | 0 … 0.125 V |
| 5 | Amplify residue | `V_residue = (Vin(i) - V_dac) * 2^N_stage` | 0 … 2 V |
| 6 | Fine quantization | `D_fine = min(floor(V_residue/LSB_c), 2^N_stage-1)` | 0 … 15 |
| 7 | Combine | `D_out(i) = D_coarse*2^N_stage + D_fine` | 0 … 255 |

## Worked examples

All values below come from the model equations. The same numbers result from `two_step_adc_convert(Vin, 4, 2)`.

**Vin = 1.234 V**

```
D_coarse  = floor(1.234 / 0.125)        = floor(9.872)   = 9      (1001b)
V_dac     = 9 × 0.125                   = 1.125 V
Vin−V_dac = 1.234 − 1.125               = 0.109 V
V_residue = 0.109 × 16                  = 1.744 V
D_fine    = floor(1.744 / 0.125)        = floor(13.952)  = 13     (1101b)
D_out     = 9 × 16 + 13                 = 157                     (1001 1101b)
check     : floor(1.234 / 0.0078125)    = floor(157.95)  = 157
```

**Vin = 2.000 V (full scale, clamping)**

```
D_coarse  = min(floor(16), 15) = 15     V_dac = 1.875 V
V_residue = (2 − 1.875) × 16  = 2.0 V
D_fine    = min(floor(16), 15) = 15
D_out     = 15 × 16 + 15      = 255
```

Without both clamps, the full-scale input would produce 16 × 16 + 16 = 272, which overflows 8 bits.

**Vin = 0.125 V (coarse boundary)**

```
D_coarse = 1, V_dac = 0.125 V, V_residue = 0, D_fine = 0  →  D_out = 16
```

At the boundary the coarse stage steps up and the fine stage restarts from 0, so codes 15 → 16 change at exactly 0.125 V. Across the 1 mV sweep, every one of the 2001 outputs equals a direct `min(floor(Vin/LSB), 255)` 8-bit quantization.

## Why the two-step result equals a direct 8-bit quantization

For `0 ≤ Vin < Vref`, write `Vin = LSB_c·(c + f)` with integer `c = D_coarse` and fractional part `f ∈ [0, 1)`. Then

```
V_residue = 16·(Vin − c·LSB_c) = 16·LSB_c·f
D_fine    = floor(16·f)
D_out     = 16·c + floor(16·f) = floor(16·(c + f)) = floor(Vin / (LSB_c/16)) = floor(Vin / LSB)
```

because `LSB_c / 16 = LSB`. This identity depends on an **exact** gain of 16 and an exact DAC. Any error in either breaks it, which is the source of practical two-step nonlinearity.

Next: [mathematical-model.md](mathematical-model.md)
