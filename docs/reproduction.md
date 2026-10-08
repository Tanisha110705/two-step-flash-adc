# Reproduction

[← README](../README.md)

No toolboxes are needed. The scripts use only core MATLAB/Octave functions: `floor`, `min`, `find`, `diff`, `cumsum`, `unique`, `setdiff`, `fopen`/`fprintf` and basic plotting.

## What was actually executed for this repository

| Step | Tool | Status |
|---|---|---|
| `two_step_adc_model.m`, `run_linearity_analysis.m`, `sweep_step_study.m` | GNU Octave 8.4.0 (`octave-cli`) | run; outputs in `results/` |
| `python/make_figures.py` | Python 3 + NumPy + Matplotlib | run; outputs in `assets/*.png` |
| Same scripts in MATLAB | MATLAB | **not run** (MATLAB not available) |

MATLAB and Octave build `0:0.001:2` slightly differently: 214 of the 2001 points differ by a few ULPs. A check that rebuilt both grids and ran the converter on each found **no difference in any output code**, so MATLAB should produce the same results.

## Option A: MATLAB

1. Open MATLAB and set the current folder to `two-step-flash-adc/matlab`.
2. Run the original model. It opens the transfer-characteristic and DNL/INL figure:
   ```matlab
   two_step_adc_model
   ```
3. Print the metrics and export the CSVs to `../results`:
   ```matlab
   run_linearity_analysis
   ```
4. Optionally, run the sweep-step study:
   ```matlab
   sweep_step_study
   ```
5. Check the printed values against [`results/summary.txt`](../results/summary.txt): DNL −0.1040 / +0.0240, INL +0.0000 / +0.1200, 256 of 256 codes, 0 missing.

## Option B: GNU Octave (as executed here)

```bash
cd matlab
octave-cli --eval "run_linearity_analysis"
octave-cli --eval "sweep_step_study"
```

In `octave-cli` the figure is created off-screen. Use `octave --gui` or `octave` with a display to see it.

## Regenerate the figures

```bash
pip install -r python/requirements.txt
python python/make_figures.py
```

The script reads `results/transfer/transfer_characteristic.csv`, `results/linearity/linearity.csv` and `results/sweep-study/sweep_step_study.csv`. It first checks that its own NumPy implementation reproduces every exported code (and stops if not), then writes:

- `assets/transfer-characteristic.png`
- `assets/dnl.png`, `assets/inl.png`, `assets/combined-linearity.png`
- `assets/sweep-step-study.png`

The SVG diagrams in `assets/` are hand-laid-out illustrations. They are not generated from data, apart from the residue sawtooth, which plots the model equation exactly.

## Expected output (`results/summary.txt`)

```
Resolution N                 : 8 bit
Stage resolution N_stage     : 4 bit (coarse) + 4 bit (fine)
Reference / input range      : 0 to 2 V
LSB = Vref/2^N               : 0.0078125 V (7.8125 mV)
LSB_c = Vref/2^N_stage       : 0.1250 V
Residue gain 2^N_stage       : 16
Input sweep                  : 2001 points, step 0.0010 V
Output code range            : 0 to 255
Distinct output codes        : 256 of 256
Missing codes                : 0
Monotonic (sweep)            : 1
Measured step widths (mV)    : [7 8]
DNL min / max (LSB)          : -0.1040 / +0.0240
max |DNL| (LSB)              : 0.1040
INL min / max (LSB)          : +0.0000 / +0.1200
max |INL| (LSB)              : 0.1200
Flash comparators 2^N-1      : 255
Two-step comparators 2(2^Ns-1): 30
Comparator-count reduction   : 88.2 %
```
