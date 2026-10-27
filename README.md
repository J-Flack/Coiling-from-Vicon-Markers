# Coiling-from-Vicon-Markers

MATLAB code for J. Flack, M. Wu and T. Verstraten, "Coiling in Flexible Shaft Torque Models as a Solution for Reliable Remote Actuation", *IEEE/ASME Transactions on Mechatronics* (under review, manuscript TMECH-08-2026-25593).

The code computes the coiling Ω of a flexible shaft from motion-capture markers, as used in the output-torque model of the paper,

    T_Out = k (θ_Ext − Ω),      Ω = 2π ΔWr  [rad]

Ω is the signed area between the paths traced on the unit sphere by the tangents of the loaded and the zero-torsion centrelines, after each centreline is completed to the two end fixtures.

**Version 2.0.0** replaces the coiling calculation of version 1 (Gauss double integral on the tracked centreline only) with the method above. Version 1.0.4 remains available from the release history.

## Repository layout

| Folder | Contents |
|---|---|
| `preprocessing/` | Loading, alignment and segmentation of the raw VICON and rig-controller recordings. These produced the data deposited on Zenodo; they are not needed to compute coiling from that deposit. |
| `coiling/` | Coiling calculation. |
| `data/` | Place the Zenodo files here (see `data/README.md`). |

## Requirements

MATLAB, with no toolboxes. The code also runs in GNU Octave 8.4.

## Computing coiling

1. Download the aligned, trial-segmented data from Zenodo (DOI [10.5281/zenodo.22108526](https://doi.org/10.5281/zenodo.22108526)) and place the five files (`5mmData.mat`, `6mmSData.mat`, `6mmMData.mat`, `6mmLData.mat`, `8mmData.mat`) in `data/`.
2. In MATLAB, `cd` into `coiling/` and run `run_coiling`.

The first run splits each recording into one file per trial, `data/trials/<shaft>_slow_<repeat>.mat` (`coil_extractTrials`). It then computes Ω for every frame of the 15 trials (5 shafts × 3 repeats, torsion at 0.125 Hz); a trial takes about 5 s. For each trial it writes to `coiling/results/`:

| File | Contents |
|---|---|
| `<shaft>_slow_<repeat>.mat` | struct `tr`: bend angle (deg), applied torsion θ_Ext (rad), output torque (Nm), Ω (rad), frame index, fixture geometry, and the largest angle between corresponding loaded and zero-torsion tangents |
| `<shaft>_slow_<repeat>.csv` | `bend_deg, theta_rad, T_Nm, Omega_rad`, one row per frame |

`run_coiling` also prints the largest angle between corresponding loaded and zero-torsion tangents for each shaft. Eqs. (3) and (4) of the paper are exact while this angle stays below 180°.

## Method

### Preprocessing (`preprocessing/`, already applied to the Zenodo data)

1. **In VICON Nexus:** a rigid-link marker template is built for each shaft. Marker gaps are filled by spline interpolation, and trajectories are low-pass filtered (fourth-order bidirectional Butterworth, 6 Hz cutoff) before export.
2. **Load** (`loadViconCSV`, `loadBeckhoffMat`, `trimViconData`, `trimBeckhoffData`): marker trajectories and the rig-controller log.
3. **Rate matching** (`downsampleBeckhoff`): the rig-controller log is downsampled to the VICON frame rate.
4. **Alignment** (`baseSquareRotationAngle`, `alignViconBeckhoff`, `applyAlignmentLag`): the rotation of a four-marker cluster on the driven fixture is cross-correlated with the commanded torsion over an initial calibration sweep. The lag found is removed, so both streams share one sample index.
5. **Segmentation** (`detectHoldLevels`, `segmentBendAngleTrialsFromBeckhoff`, `run_full_segmentation_pipeline`): the aligned recording is cut into trials (bend angle × speed × repeat) using the bend and torsion channels.
6. **Earlier centreline** (`computeShaftCenterline`, `buildRigidFrameAnchors`): the centreline stored in the Zenodo files. The code in `coiling/` does not use it.

### Coiling (`coiling/`)

| Step | Function | What it does |
|---|---|---|
| 1 | `coil_extractTrials` | Splits the aligned recordings into per-trial files. |
| 2 | `coil_markers` | Shaft markers (excluding `base*`), sorted by their numeric ID along the shaft. |
| 3 | `coil_smoother`, `coil_centerline` | The centres of consecutive sets of three markers cancel the 120° spiral mounting offset. A cubic smoothing spline through these centres gives the centreline at 200 points. |
| 4 | `coil_trial` | Builds the zero-torsion reference for each bend angle and the two end fixtures of each shaft, then Ω for every frame. |
| 5 | `coil_tangentPath`, `coil_hermite`, `coil_connMags` | Completes each centreline to the fixtures with cubic Hermite curves and returns its tangent path on the unit sphere. |
| 6 | `coil_omega`, `coil_tri` | Ω is minus the signed spherical area between the loaded and reference tangent paths, summed over spherical triangles (van Oosterom & Strackee 1983). Both paths start and end on the fixture axes, so Ω = 2πΔWr (Fuller 1978) and no closure convention is needed. |

Details of the processing that are not given in the paper:

- **Smoothing spline.** Smoothing parameter p = 0.9997 (`cfg.lambda` = 3e-4, p = 1/(1+λ)). The triplet centres are placed at equal spacing on [0, 1]. The markers are 20 mm apart, so this spacing is close to normalised arc length. The spline is the same as `csaps` with this smoothing parameter.
- **Zero-torsion reference.** For each bend angle, the mean centreline of the five frames with the smallest applied torsion (`cfg.nRef`).
- **Untracked length.** The free length of each shaft (stated length minus the two 20 mm fixtures, `cfg.Lfree`) is longer than the tracked centreline. The difference is split equally between the two ends (`cfg.split` = 0.5).
- **Fixture axes.** The motor-side fixture axis is the chord of the zero-torsion centreline at the smallest bend angle, and is the same for all bends. The fixed-side fixture axis is the motor-side axis rotated by the measured bend angle.
- **End completion.** The cubic Hermite curve leaves each fixture along its axis and meets the tracked end at its measured position and tangent. The two tangent magnitudes minimise the integrated squared second derivative of the curve (Yong & Cheng 2004), an approximation of its bending energy.
- **Signals.** Output torque is −`beckhoff.dtz`; torsion is `beckhoff.torsion` in degrees, converted to radians.

All settings are in `coiling/coil_config.m`. The values are those used in the paper.

## Citation

Please cite the paper above and this software via `citation.cff` (Zenodo concept DOI [10.5281/zenodo.22096159](https://doi.org/10.5281/zenodo.22096159), which resolves to the latest version).

## References

- F. B. Fuller, "Decomposition of the linking number of a closed ribbon: A problem from molecular biology," *Proc. Natl. Acad. Sci. USA*, vol. 75, no. 8, pp. 3557–3561, 1978.
- A. van Oosterom and J. Strackee, "The solid angle of a plane triangle," *IEEE Trans. Biomed. Eng.*, vol. BME-30, no. 2, pp. 125–126, 1983.
- J.-H. Yong and F. Cheng, "Geometric Hermite curves with minimum strain energy," *Comput. Aided Geom. Des.*, vol. 21, no. 3, pp. 281–301, 2004.

## License

MIT, see `LICENSE.txt`.
