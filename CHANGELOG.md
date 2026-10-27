# Changelog

## 2.0.0

- New `coiling/` folder with the coiling calculation used in the revised paper. Ω is the signed area between the tangent paths of the loaded and zero-torsion centrelines on the unit sphere, with each centreline completed to the end fixtures, so that Ω = 2πΔWr. Only the 0.125 Hz trials are processed.
- `coil_extractTrials.m` splits the Zenodo recordings into per-trial files; `run_coiling.m` computes Ω for every trial.
- Removed the version 1 coiling and fitting code (`writheACN.m`, `calculateSampleWrithe.m`, `calculateSampleACNWritheAll.m`, `runSampleWrithe.m`, `runSampleACNWritheAll.m`, `buildSegData.m`, `SegDataAnalyser.m`). It remains available in version 1.0.4.
- Moved the loading, alignment and segmentation code to `preprocessing/`, unchanged.

## 1.0.4

- Coiling as the Gauss double integral of the tracked centreline; data DOI added.
