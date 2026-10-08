# Comparator Count: Full Flash vs. Two-Step

[← README](../README.md)

![Comparator count](../assets/flash-vs-two-step.svg)

## Count

| Architecture | Resolution | Stages | Comparators |
|---|---:|---|---:|
| Full flash | 8-bit | 1 × 8-bit | 2^8 − 1 = **255** |
| Two-step | 8-bit | 4-bit coarse + 4-bit fine | 2 × (2^4 − 1) = **30** |

```
Reduction = (255 − 30) / 255 × 100 = 225 / 255 × 100 = 88.2 %
```

Sources: the report gives 255, 30 and "~88 %". The formulas are standard, and `run_linearity_analysis.m` computes the same values from `N` and `N_stage`.

**What the 88.2 % means:** the converter has 88.2 % fewer comparators. That is a **count**. It is **not** a measured reduction in area, power or input capacitance. The MATLAB model has no individual comparators at all: each stage is an ideal `floor()`.

## Scaling (calculated)

For a two-step split of N bits into two N/2-bit stages:

| N | Flash `2^N − 1` | Two-step `2·(2^(N/2) − 1)` |
|---:|---:|---:|
| 6 | 63 | 14 |
| 8 | 255 | 30 |
| 10 | 1023 | 62 |
| 12 | 4095 | 126 |

## What the two-step design adds

Fewer comparators do not automatically mean less power or area, because the two-step ADC also needs:

- a **DAC** accurate to the full 8-bit level;
- a **subtractor** and a **residue amplifier** with a precise gain of 16, which in hardware usually means a closed-loop opamp or a switched-capacitor gain stage with its own power and settling time;
- a **sample-and-hold**, because the input must stay constant while the coarse decision, DAC settling and fine conversion happen in sequence;
- usually **redundancy and digital correction** to tolerate coarse-comparator offset.

The report's comparison table also rates power "Low", area "Reduced" and speed "High" for the two-step design. These are qualitative expectations from the literature. The project did not simulate or measure them.

## Tradeoff summary

| | Full flash | Two-step |
|---|---|---|
| Comparators (8-bit) | 255 | 30 |
| Conversion steps | 1 | 2 in series (coarse → DAC/residue → fine) |
| Extra analog blocks | none | DAC, subtractor, ×16 amplifier, S/H |
| Main accuracy limits | comparator offsets, ladder | + DAC accuracy, residue gain, inter-stage alignment |
| Latency | lowest | higher (sequential stages) |
