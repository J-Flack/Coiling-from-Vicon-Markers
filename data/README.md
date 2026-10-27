# Data

Download the aligned, trial-segmented recordings from Zenodo, DOI [10.5281/zenodo.22108526](https://doi.org/10.5281/zenodo.22108526), and place them in this folder:

| Shaft (diameter × length, mm) | File | Name in `coil_config.m` |
|---|---|---|
| 6 × 386 | `6mmSData.mat` | `6mm_s` |
| 6 × 470 | `6mmMData.mat` | `6mm_m` |
| 6 × 544 | `6mmLData.mat` | `6mm_l` |
| 8 × 435 | `8mmData.mat` | `8mm` |
| 5 × 454 | `5mmData.mat` | `5mm` |

Each file holds the output of `preprocessing/run_full_segmentation_pipeline.m`:

- `viconAligned`: marker trajectories (mm) and time, on the shared sample index.
- `beckhoffAligned`: rig-controller channels on the same index. `torsion` is the applied torsion (deg), `dtz` the output torque (sign flipped: T = −dtz), and `bend` the bend angle.
- `segs`: one row per trial, with the bend angle, speed, repeat and sample range. The last row is a short segment recorded after the third repeat (labelled repeat 4); it is not used.
- `align`: alignment details.
- `centerline`: a centreline reconstruction from an earlier version of the analysis. The current code does not use it; it rebuilds the centreline from the markers.

`coiling/run_coiling.m` splits these files into one file per trial in `data/trials/` on its first run (`coiling/coil_extractTrials.m`). Only the trials at 0.125 Hz are used; the files also contain faster recordings, which are not analysed.

The raw VICON exports and rig-controller logs are not included, because of their size and number. They are available from the corresponding author on reasonable request.
