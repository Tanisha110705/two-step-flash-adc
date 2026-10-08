# Architecture

[← README](../README.md)

![Block diagram](../assets/adc-block-diagram.svg)

## Overview

| Item | Value | Where it is set |
|---|---|---|
| Resolution | 8 bit | `N = 8` |
| Partition | 4 + 4 bit (coarse + fine) | `N_stage = 4` |
| Reference / input range | 2 V / 0–2 V | `Vref = 2`, `Vin = 0:0.001:Vref` |
| Stage step | `LSB_c = Vref / 2^4 = 0.125 V` | `LSB_c = Vref / (2^N_stage)` |
| Residue gain | `2^4 = 16` | `(Vin(i) - V_dac) * (2^N_stage)` |
| Output | `D_out` = 0 … 255 | `(D_coarse * 2^N_stage) + D_fine` |

This is a **two-step (sub-ranging) flash ADC**. A single 8-bit flash would compare `Vin` against 255 reference levels at once. Here the conversion is split into two 4-bit flash conversions in series, linked by a DAC and a residue amplifier.

Everything described below exists in the model **only as ideal arithmetic**. There are no transistor-level or netlist-level blocks in this repository.

## Blocks

### 1. Coarse ADC (upper 4 bits)

- **Function:** a 4-bit flash quantizer over the full 0–2 V range.
- **Model:** `D_coarse = min(floor(Vin/LSB_c), 15)`.
- **Hardware equivalent:** 15 comparators with thresholds at `k × 0.125 V`, k = 1…15, plus a thermometer-to-binary encoder. The model does not instantiate comparators; `floor()` is the ideal equivalent.
- **Output:** `D_coarse` ∈ {0, …, 15} = `D_out[7:4]`.

### 2. DAC (coarse reconstruction)

- **Function:** turns the coarse code back into an analog estimate of `Vin`.
- **Model:** `V_dac = D_coarse × LSB_c`. Ideal levels 0, 0.125, …, 1.875 V.
- **Note:** the DAC must be accurate to the **full 8-bit level** (≪ 7.8 mV), not just 4 bits, because any DAC error goes straight into the residue.

### 3. Subtractor

- **Function:** `Vin − V_dac`, the part of the input the coarse stage did not resolve.
- **Range in the model:** `[0, 0.125 V)` for `Vin < 2 V`, and exactly 0.125 V at `Vin = 2 V`, where `D_coarse` is clamped.

### 4. Residue amplifier

- **Function:** scales the residue back up to the full reference range.
- **Model:** gain of exactly `2^N_stage = 16`, so `V_residue` ∈ [0, 2 V].
- **Why ×16:** it lets the fine ADC use the same 0.125 V step and reference as the coarse ADC. Without the gain, the fine stage would need 7.8125 mV threshold spacing over a 125 mV window.

### 5. Fine ADC (lower 4 bits)

- **Function:** a 4-bit flash quantizer on the amplified residue.
- **Model:** `D_fine = min(floor(V_residue/LSB_c), 15)`.
- **Hardware equivalent:** another 15 comparators.
- **Output:** `D_fine` ∈ {0, …, 15} = `D_out[3:0]`.

### 6. Digital combiner

- **Model:** `D_out = D_coarse × 16 + D_fine`. Both inputs are 0–15, so this is plain bit concatenation `{D_coarse, D_fine}` with no carry.
- **No redundancy:** the stages do not overlap and there is no digital error correction. This works for an ideal model. In hardware, a coarse-comparator error would send the residue out of the fine stage's range (see [Potential error sources](../README.md#potential-error-sources)).

## What the model does not contain

- Sample-and-hold or track-and-hold (the input is a static sweep, so it is not needed).
- Individual comparators, a reference ladder or capacitor arrays.
- Timing, clock phases, settling or pipelining.
- Any noise or mismatch source.

## Comparator budget

| Stage | Comparators | Formula |
|---|---:|---|
| Coarse | 15 | 2^4 − 1 |
| Fine | 15 | 2^4 − 1 |
| **Two-step total** | **30** | 2 × (2^4 − 1) |
| 8-bit full flash | 255 | 2^8 − 1 |

See [comparator-comparison.md](comparator-comparison.md).

Next: [two-step-operation.md](two-step-operation.md)
