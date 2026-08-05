# Reproducibility materials — Coiling in Flexible Shaft Torque Models

Supplemental code for TMECH-02-2026-23825, "Coiling in Flexible Shaft Torque Models as a Solution for Reliable Remote Actuation." Covers the writhe (Ω) computation and the preprocessing pipeline described in the Methods section.

## Pipeline overview

Two independent, unsynchronized systems record each trial: VICON Nexus (3D marker positions along the shaft, plus a 4-marker rigid cluster on the driven fixture) and the rig controller (motor-side torsion angle, bend angle, driven-end output torque), sampled much faster than VICON.

1. **In-Nexus processing.** A rigid-link marker template is built in VICON Nexus. Gaps from marker occlusion are filled by spline interpolation; trajectories are then low-pass filtered (4th-order bidirectional/zero-phase Butterworth, 6 Hz cutoff) before export. This step happens entirely inside Nexus, not in this codebase.
2. **Load** (`loadViconCSV.m`, `loadBeckhoffMat.m`) — parse marker trajectories and the rig-controller log into a common format; channels are identified against the rig's documentation to confirm sign conventions.
3. **Rate matching** — the rig-controller log is downsampled to the VICON frame rate.
4. **Temporal alignment** (`baseSquareRotationAngle.m`, `alignViconBeckhoff.m`, `applyAlignmentLag.m`) — the 4-marker rigid cluster is reduced to a single unwrapped rotation-angle signal (a VICON-side proxy for commanded torsion) by estimating one stable rotation axis for the recording and tracking a marker's angle around it. That signal is cross-correlated against the rig controller's torsion channel over an initial calibration sweep to resolve sign convention and estimate the integer-sample lag between streams. Whichever stream is ahead is trimmed by that many samples so both streams share a common index from that point on.
5. **Trial segmentation** (`run_full_segmentation_pipeline.m`) — the aligned recording is cut into individual trials (repeats × speeds × bend angles) using the rig controller's bend/torsion channels directly.
6. **Centerline reconstruction** (`computeShaftCenterline.m`, `buildRigidFrameAnchors.m`) — run once on the full aligned recording: consecutive marker triplets are averaged per frame to cancel the spiral mounting offset, then a smoothing spline is fit through the triplet centers and evaluated at a fixed number of points to give a dense 3D centerline curve.
7. **Per-trial slicing** — each trial is further split into positive/negative torsion direction and rising/falling half-cycles by indexing into the centerline and the aligned torsion/torque channels using each trial's sample range.
8. **Ω computation** (`writheACN.m`, `calculateSampleACNWritheAll.m`, `runSampleACNWritheAll.m`, `runSampleWrithe.m`) — signed writhe is computed per frame from the sliced centerline via the discretized Gauss double integral (closed-form solid-angle formula for each segment pair). Regularization near the singularity: neighbor-index exclusion (segment pairs within `|i-j| <= k_excl` are skipped), epsilon-guarded normalization of cross products, and clamping of the dot product to [-1, 1] before `asin`.
9. **Model fitting** (`fit_torque_model.m`) — the torque model is fit per shaft/direction using the aligned torsion angle, the computed writhe, and the measured output torque (warm-started nonlinear least squares).

`SegDataAnalyser.m` is included as the top-level driver that ties stages 6-9 together for a given segmented-data (`wts`) file; note it also contains several unused/commented-out writhe methods (DirectGauss, Fuller, PolarPriorNeukirch, Starostin, GaussSumNaive, etc.) retained from development — only the ACN path (`writheACN.m`) was used for the reported fits.

## Files

| File | Stage | Role |
|---|---|---|
| `loadViconCSV.m` | 2 | Parse exported VICON marker CSV |
| `loadBeckhoffMat.m` | 2 | Parse rig-controller log |
| `baseSquareRotationAngle.m` | 4 | Rigid-cluster rotation-angle proxy |
| `alignViconBeckhoff.m` | 4 | Cross-correlation lag estimation |
| `applyAlignmentLag.m` | 4 | Trim/shift streams to common index |
| `run_full_segmentation_pipeline.m` | 5 | Trial segmentation driver |
| `buildRigidFrameAnchors.m` | 6 | Rigid-frame anchor geometry for centerline |
| `computeShaftCenterline.m` | 6 | Triplet-averaging + smoothing spline centerline |
| `writheACN.m` | 8 | Core ACN solid-angle writhe formula + regularization |
| `calculateSampleACNWritheAll.m` | 8 | Per-frame writhe over a full sample |
| `runSampleACNWritheAll.m` | 8 | Batch runner across samples |
| `runSampleWrithe.m` | 8 | Single-sample writhe runner |
| `fit_torque_model.m` | 9 | Nonlinear least-squares torque model fit |
| `SegDataAnalyser.m` | 6-9 | Top-level driver tying the above together |

## Requirements

MATLAB (base MATLAB + Curve Fitting Toolbox, for the smoothing spline and `fittype`/`fitoptions` calls).

## Data

Raw VICON marker exports and rig-controller logs are not included in this repository due to size. [Add data availability statement / repository DOI here, e.g. an institutional or Zenodo data deposit, per journal/VUB policy.]

## Citation

[Add manuscript citation once accepted / DOI once minted.]
