"""Render the README figures from the data exported by the MATLAB model.

Inputs (written by matlab/run_linearity_analysis.m and matlab/sweep_step_study.m):
    results/transfer/transfer_characteristic.csv
    results/linearity/linearity.csv
    results/sweep-study/sweep_step_study.csv

Before plotting, the script re-implements the converter in NumPy and checks that
it reproduces every exported output code, so the figures cannot drift from the
MATLAB model without failing loudly.

Usage:  python python/make_figures.py
"""
from pathlib import Path
import csv
import math

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "results"
ASSETS = ROOT / "assets"

N, N_STAGE, VREF = 8, 4, 2.0
LSB = VREF / 2**N
LSB_C = VREF / 2**N_STAGE

BLUE, ORANGE = "#2a78d6", "#eb6834"
INK, INK2, GRID = "#0b0b0b", "#52514e", "#e4e3df"

plt.rcParams.update({
    "figure.facecolor": "white", "axes.facecolor": "white",
    "axes.edgecolor": INK2, "axes.labelcolor": INK, "axes.titlecolor": INK,
    "xtick.color": INK2, "ytick.color": INK2, "text.color": INK,
    "axes.grid": True, "grid.color": GRID, "grid.linewidth": 0.8,
    "axes.spines.top": False, "axes.spines.right": False,
    "font.size": 10.5, "axes.titlesize": 12, "axes.titleweight": "bold",
    "legend.frameon": False, "savefig.dpi": 160,
})


def read_csv(path):
    with open(path, newline="") as f:
        rows = list(csv.DictReader(f))
    return {k: [r[k] for r in rows] for k in rows[0]}


def convert(v):
    """Same arithmetic as the loop body in matlab/two_step_adc_model.m."""
    d_coarse = min(math.floor(v / LSB_C), 2**N_STAGE - 1)
    v_dac = d_coarse * LSB_C
    v_res = (v - v_dac) * 2**N_STAGE
    d_fine = min(math.floor(v_res / LSB_C), 2**N_STAGE - 1)
    return d_coarse * 2**N_STAGE + d_fine


def save(fig, name):
    fig.savefig(ASSETS / name, bbox_inches="tight", pad_inches=0.15)
    plt.close(fig)
    print("wrote", ASSETS / name)


def main():
    t = read_csv(RES / "transfer" / "transfer_characteristic.csv")
    vin = np.array(t["vin_v"], float)
    code = np.array(t["code"], int)

    # MATLAB's 0:0.001:2 differs from this grid by at most a few ULPs; the
    # CSV stores 4 decimals, so rebuild the exact multiples of 1 mV.
    vin_exact = np.arange(len(vin)) * 1e-3
    port = np.array([convert(v) for v in vin_exact])
    assert np.array_equal(port, code), "NumPy port disagrees with MATLAB output"
    print("cross-check: NumPy port reproduces all", len(code), "MATLAB codes")

    lin = read_csv(RES / "linearity" / "linearity.csv")
    k = np.array(lin["code"], int)
    dnl = np.array(lin["dnl_lsb"], float)
    inl = np.array(lin["inl_lsb"], float)

    # ---- Transfer characteristic: full range + zoom on the first coarse step
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(11, 4.2),
                                 gridspec_kw={"width_ratios": [1.15, 1]})
    a1.step(vin, code, where="post", color=BLUE, lw=1.6)
    a1.plot([0, VREF], [0, 2**N], color=INK2, lw=1, ls="--")
    a1.text(1.25, 120, "ideal line\nDout = Vin / LSB", color=INK2, fontsize=9)
    a1.set(xlim=(0, VREF), ylim=(0, 260), xlabel="Input voltage Vin (V)",
           ylabel="Digital output code Dout",
           title="Transfer characteristic, 0–2 V → codes 0–255")
    a1.set_yticks([0, 64, 128, 192, 255])

    z = vin <= 0.25 + 1e-9
    zt = np.arange(0, 33) * LSB
    a2.step(vin[z], code[z], where="post", color=BLUE, lw=1.6, label="model output (1 mV sweep)")
    a2.step(zt, np.arange(33), where="post", color=INK2, lw=1, ls="--",
            label="ideal staircase (k·LSB)")
    a2.axvline(LSB_C, color=ORANGE, lw=1.2)
    a2.text(LSB_C + 0.004, 3, "coarse boundary\nVin = LSB_c = 0.125 V",
            color=INK, fontsize=9)
    a2.set(xlim=(0, 0.25), ylim=(0, 32), xlabel="Input voltage Vin (V)",
           ylabel="Digital output code Dout", title="Zoom: first two coarse segments")
    a2.set_yticks([0, 8, 16, 24, 32])
    a2.legend(loc="upper left", fontsize=9)
    fig.tight_layout()
    save(fig, "transfer-characteristic.png")

    def dnl_axes(ax):
        ax.plot(k, dnl, color=BLUE, lw=1.2, marker="o", ms=2.2)
        ax.axhline(0, color=INK2, lw=0.8)
        ax.set(xlim=(0, 255), ylim=(-0.14, 0.06), ylabel="DNL (LSB)")
        ax.annotate(f"max {dnl.max():+.3f} LSB", (0.995, 0.93), xycoords="axes fraction",
                    ha="right", fontsize=9, color=INK)
        ax.annotate(f"min {dnl.min():+.3f} LSB", (0.995, 0.03), xycoords="axes fraction",
                    ha="right", fontsize=9, color=INK)

    def inl_axes(ax):
        ax.plot(k, inl, color=ORANGE, lw=1.4)
        ax.axhline(0, color=INK2, lw=0.8)
        ax.set(xlim=(0, 255), ylim=(-0.02, 0.15), ylabel="INL (LSB)")
        ax.annotate(f"max {inl.max():+.3f} LSB,  min {inl.min():+.3f} LSB",
                    (0.995, 0.92), xycoords="axes fraction", ha="right", fontsize=9, color=INK)

    for name, fn, title in [
        ("dnl.png", dnl_axes, "DNL vs output code (1 mV input sweep)"),
        ("inl.png", inl_axes, "INL vs output code (1 mV input sweep)"),
    ]:
        fig, ax = plt.subplots(figsize=(10, 3.4))
        fn(ax)
        ax.set(xlabel="Output code k", title=title)
        ax.set_xticks(range(0, 257, 32))
        fig.tight_layout()
        save(fig, name)

    fig, (b1, b2) = plt.subplots(2, 1, figsize=(10, 5.8), sharex=True)
    dnl_axes(b1)
    b1.set_title("Linearity from code transitions (1 mV input sweep)")
    inl_axes(b2)
    b2.set_xlabel("Output code k")
    b2.set_xticks(range(0, 257, 32))
    for c in range(16, 256, 16):
        for ax in (b1, b2):
            ax.axvline(c, color=GRID, lw=0.8, zorder=0)
    fig.tight_layout()
    save(fig, "combined-linearity.png")

    # ---- Sweep-step study
    s = read_csv(RES / "sweep-study" / "sweep_step_study.csv")
    labels = s["label"]
    dmax = np.maximum(np.abs(np.array(s["dnl_min"], float)), np.abs(np.array(s["dnl_max"], float)))
    imax = np.maximum(np.abs(np.array(s["inl_min"], float)), np.abs(np.array(s["inl_max"], float)))
    x = np.arange(len(labels))
    w = 0.38
    fig, ax = plt.subplots(figsize=(10, 3.8))
    ax.bar(x - w / 2 - 0.01, dmax, w, color=BLUE, label="max |DNL|")
    ax.bar(x + w / 2 + 0.01, imax, w, color=ORANGE, label="max |INL|")
    for xi, d, i in zip(x, dmax, imax):
        ax.text(xi - w / 2 - 0.01, d + 0.003, f"{d:.4f}", ha="center", fontsize=8.5, color=INK)
        ax.text(xi + w / 2 + 0.01, i + 0.003, f"{i:.4f}", ha="center", fontsize=8.5, color=INK)
    ax.set_xticks(x, labels)
    ax.set(ylabel="Extracted error (LSB)", xlabel="Input-sweep step",
           ylim=(0, 0.14),
           title="Same ideal converter, different sweep steps: extracted DNL/INL")
    ax.grid(axis="x", visible=False)
    ax.legend(loc="upper right")
    fig.tight_layout()
    save(fig, "sweep-step-study.png")


if __name__ == "__main__":
    main()
