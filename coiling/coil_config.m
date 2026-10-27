function cfg = coil_config()
%COIL_CONFIG  Settings for the coiling calculation.
%
%   Omega = 2*pi*DeltaWr [rad] is the signed area between the tangent paths
%   of the loaded and zero-torsion centrelines on the unit sphere, after
%   each centreline is completed to the two end fixtures. See README.md.
%
%   The values below are those used in the paper.

here = fileparts(mfilename('fullpath'));

%% ---- folders --------------------------------------------------------
root = fileparts(here);                             % repository root
cfg.alignedDir = fullfile(root, 'data');            % Zenodo files (cfg.alignedFiles)
cfg.dataDir    = fullfile(root, 'data', 'trials');  % per-trial files written by coil_extractTrials
cfg.outDir     = fullfile(here, 'results');         % coiling for every trial

%% ---- shafts ---------------------------------------------------------
cfg.shafts  = {'6mm_s', '6mm_m', '6mm_l', '8mm', '5mm'};
% aligned recording of each shaft, as named on Zenodo (DOI 10.5281/zenodo.22108526)
cfg.alignedFiles = {'6mmSData.mat', '6mmMData.mat', '6mmLData.mat', '8mmData.mat', '5mmData.mat'};
cfg.labels  = {'6 mm x 386', '6 mm x 470', '6 mm x 544', '8 mm x 435', '5 mm x 454'};
% Free length between the two end fixtures [mm]:
% stated shaft length minus the two 20 mm fixtures.
cfg.Lfree   = [346, 430, 504, 395, 414];
cfg.reps    = 1:3;
cfg.speed   = 'slow';   % trials with torsion at 0.125 Hz

%% ---- centreline ----------------------------------------------------
cfg.nPts    = 200;      % points along the centreline
cfg.lambda  = 3e-4;     % smoothing-spline penalty; smoothing parameter p = 1/(1+lambda) = 0.9997.
                        % The triplet centres are placed at equal spacing on [0,1]; the markers
                        % are 20 mm apart, so this is close to normalised arc length.

%% ---- zero-torsion reference ----------------------------------------
cfg.nRef    = 5;        % reference of each bend angle = mean centreline of the
                        % nRef frames with the smallest applied torsion

%% ---- completion to the end fixtures --------------------------------
% The untracked length (Lfree minus tracked length) is added at both ends
% with cubic Hermite curves. Fixture axes:
%   motor-side axis = chord of the zero-torsion centreline at the smallest
%                     bend angle (the same for all bends)
%   fixed-side axis = motor-side axis rotated by the measured bend angle
cfg.split   = 0.5;      % share of the untracked length at the motor-side end
cfg.nConn   = 16;       % points per Hermite curve
end
