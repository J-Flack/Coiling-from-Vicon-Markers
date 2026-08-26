%% SegDataAnalyser.m
% Top-level driver: loads a single aligned-segmentation file (produced by
% run_full_segmentation_pipeline.m), builds segData -- reconstructing the
% shaft centerline fresh from the aligned marker data rather than reusing
% any centerline stored in that file -- then pools the per-trial coiling
% (Omega/ACN), torsion, and output torque data across all tested bend
% angles for the positive- and negative-torsion loading regions.
%
% SCOPE: this script computes and pools coiling (Omega) alongside torsion
% and output torque -- it does NOT fit a torque model. Per Section II.D
% of the manuscript, this repository covers marker preprocessing and the
% coiling (Omega) calculation; torque-model fitting (Eq. 5/6) is
% intentionally out of scope for this release.
%
% Samples are windowed to |torsion| beyond TORSION_WINDOW_DEG, excluding
% the deadzone around 0 degrees of torsion noted in Section III.A, where
% the zero-torque crossing is not well defined by a linear model.

clear; clc;

TORSION_WINDOW_DEG = struct('positive', 7, 'negative', -8);

%% --- load the aligned-segmentation base file for this shaft ---
% Only the aligned streams and the trial table are needed -- the
% centerline is reconstructed by buildSegData.m rather than reused.
load('5mmData.mat', 'viconAligned', 'beckhoffAligned', 'segs');

%% --- build segData: one entry per bend angle, pooled across repeats/speeds ---
segData = buildSegData(segs, viconAligned, beckhoffAligned);

%% --- pool all bend angles' positive-rising / negative-rising samples ---
% Each bend angle's Omega/ACN trace is baseline-corrected against its own
% extremum before pooling across angles, since Omega's absolute offset
% carries no physical meaning on its own -- only its variation within a
% given configuration does (see writheACN.m).
t_p_e = []; dtz_p_e = []; ACN_p_e_n = [];
t_n_e = []; dtz_n_e = []; ACN_n_e_n = [];

for i = 1:numel(segData)
    pr = segData(i).positive_rising;
    nr = segData(i).negative_rising;

    if ~isempty(pr.Wr.ACN)
        ACN_p_e_n = [ACN_p_e_n; pr.Wr.ACN - max(pr.Wr.ACN)]; %#ok<AGROW>
        t_p_e     = [t_p_e;     pr.torsion];                  %#ok<AGROW>
        dtz_p_e   = [dtz_p_e;   pr.dtz];                       %#ok<AGROW>
    end
    if ~isempty(nr.Wr.ACN)
        ACN_n_e_n = [ACN_n_e_n; nr.Wr.ACN - min(nr.Wr.ACN)]; %#ok<AGROW>
        t_n_e     = [t_n_e;     nr.torsion];                  %#ok<AGROW>
        dtz_n_e   = [dtz_n_e;   nr.dtz];                       %#ok<AGROW>
    end
end

%% --- restrict to the analysis window (excludes the near-zero-torsion deadzone) ---
posMask = t_p_e >= TORSION_WINDOW_DEG.positive;
negMask = t_n_e <= TORSION_WINDOW_DEG.negative;

t_p_e = t_p_e(posMask); dtz_p_e = dtz_p_e(posMask); ACN_p_e_n = ACN_p_e_n(posMask);
t_n_e = t_n_e(negMask); dtz_n_e = dtz_n_e(negMask); ACN_n_e_n = ACN_n_e_n(negMask);

fprintf('Pooled, windowed samples: %d positive-rising, %d negative-rising.\n', ...
    numel(t_p_e), numel(t_n_e));

%% --- diagnostic plots: torsion vs. output torque, and torsion vs. coiling ---
figure('Name', 'Torsion vs. output torque');
subplot(1,2,1);
plot(t_p_e, dtz_p_e, '.');
xlabel('Torsion (deg)'); ylabel('dtz (Nm)');
title('Positive-rising, all bend angles pooled');
grid on;

subplot(1,2,2);
plot(t_n_e, dtz_n_e, '.');
xlabel('Torsion (deg)'); ylabel('dtz (Nm)');
title('Negative-rising, all bend angles pooled');
grid on;

figure('Name', 'Torsion vs. coiling (Omega)');
subplot(1,2,1);
plot(t_p_e, ACN_p_e_n, '.');
xlabel('Torsion (deg)'); ylabel('\Omega (baseline-corrected)');
title('Positive-rising, all bend angles pooled');
grid on;

subplot(1,2,2);
plot(t_n_e, ACN_n_e_n, '.');
xlabel('Torsion (deg)'); ylabel('\Omega (baseline-corrected)');
title('Negative-rising, all bend angles pooled');
grid on;

%% --- variables left in the base workspace ---
% t_p_e, t_n_e         : torsion angle (deg), windowed, positive/negative-rising
% dtz_p_e, dtz_n_e     : output torque (Nm), same rows
% ACN_p_e_n, ACN_n_e_n : baseline-corrected coiling (Omega), same rows
% Torque-model fitting against this pooled data is out of scope for this
% release -- see repository README.
