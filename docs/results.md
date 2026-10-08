# Results

[← README](../README.md)

**Source key:** **M** = model run (GNU Octave 8.4.0 executing the report's MATLAB code; see [`results/summary.txt`](../results/summary.txt)) · **R** = project report · **C** = calculation from verified parameters · **S** = sweep-step study ([`results/sweep-study/sweep_step_study.csv`](../results/sweep-study/sweep_step_study.csv)).

## ADC specifications

| Parameter | Value | Source |
|---|---:|---|
| Resolution | 8 bit | M (`N = 8`), R |
| Stage partition | 4 bit coarse + 4 bit fine | M (`N_stage = 4`), R |
| Reference | 2 V | M (`Vref = 2`), R |
| Input range | 0–2 V | M, R |
| Output codes | 0–255 (256 levels) | M, R |
| LSB | 7.8125 mV | C: 2 V / 256 |
| Stage step LSB_c | 0.125 V | C: 2 V / 16 |
| Residue gain | 16 | M (`2^N_stage`), R |
| Input sweep | 2001 points, 1 mV step | M (`0:0.001:Vref`), R |

## Comparator comparison

| Architecture | Comparators | Source |
|---|---:|---|
| 8-bit flash | 255 | C (2^8 − 1), R |
| 8-bit two-step | 30 | C (2·(2^4 − 1)), R |
| Reduction in count | 88.2 % | C; R gives "~88 %" |

This is a count, not measured power or area.

## Transfer characteristic

![Transfer characteristic](../assets/transfer-characteristic.png)

| Observation | Source |
|---|---|
| Uniform staircase from code 0 at 0 V to code 255 at 2 V | M, R (figure) |
| Last transition (code 255) found at 1.993 V; ideal 255 × LSB = 1.9921875 V | M |
| All 2001 swept outputs equal `min(floor(Vin/LSB), 255)` | M + NumPy cross-check |

## DNL

| Metric | Value | Source |
|---|---:|---|
| Minimum | −0.104 LSB | M; R ≈ −0.10 |
| Maximum | +0.024 LSB | M; R ≈ +0.02 |
| max \|DNL\| | 0.104 LSB | M; R ≈ 0.10 |
| Distinct values | −0.104 (47 codes), +0.024 (208 codes), 0 (code 0, by definition) | M |

## INL

| Metric | Value | Source |
|---|---:|---|
| Minimum | 0.000 LSB | M; R "≈ 0, slightly negative" |
| Maximum | +0.120 LSB (codes 5, 21, …, 245) | M; R ≈ +0.12 |
| max \|INL\| | 0.120 LSB | M; R ≈ 0.12 |
| Period | 16 codes (3 sawtooth teeth per period) | M; R figure |

## Missing codes

| Check | Result | Source |
|---|---|---|
| Distinct codes in sweep | 256 of 256 | M |
| Missing codes | none | M; R |
| Monotonic over sweep | yes | M |

## Sweep-step sensitivity

| Sweep step | max \|DNL\| (LSB) | max \|INL\| (LSB) | Source |
|---|---:|---:|---|
| 1 mV | 0.104 | 0.120 | S |
| 0.5 mV | 0.040 | 0.056 | S |
| 0.1 mV | 0.0112 | 0.0112 | S |
| 0.01 mV | 0.00096 | 0.00096 | S |
| LSB/8, LSB/64 | 0 | 0 | S |

## Overall interpretation

- The model works as an 8-bit converter. It produces all 256 codes over 0–2 V, monotonically and with no missing codes, and its output matches an ideal 8-bit quantizer bit for bit.
- It needs 30 comparators instead of 255 (an 88.2 % lower count).
- The DNL/INL values in the report are reproduced exactly, but they measure the 1 mV sweep resolution. The ideal model has zero DNL/INL. The repository therefore does **not** claim that the converter has 0.10 LSB DNL or 0.12 LSB INL in any physical sense. It also does not attribute the pattern to mismatch, offset or gain error, since none of those is modeled.
- Linearity numbers that reflect a real implementation will require the nonidealities listed under [future work](../README.md#future-work).

Next: [reproduction.md](reproduction.md)
