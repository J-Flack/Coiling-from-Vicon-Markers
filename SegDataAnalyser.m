%% SegDataAnalyser.m
% Top-level driver: builds segData from a completed
% run_full_segmentation_pipeline.m run, then fits the torque model
% (fit_torque_model.m) separately for the positive- and negative-torsion
% loading regions across all tested bend angles.
%
% The fit is restricted to |torsion| beyond TORSION_WINDOW_DEG, excluding
% the deadzone around 0 degrees of torsion noted in Section III.A, where
% the zero-torque crossing is not well defined by the linear model.

clear; clc;

TORSION_WINDOW_DEG = struct('positive', 7, 'negative', -8);

%% --- load pipeline output for this recording ---
load('5mm04_aligned_segmentation.mat', 'beckhoffAligned', 'segs', 'centerline');

%% --- build segData: one entry per bend angle, pooled across repeats/speeds ---
segData = buildSegData(segs, beckhoffAligned, centerline);

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

%% --- restrict to the loading window used for the reported fit ---
posMask = t_p_e >= TORSION_WINDOW_DEG.positive;
negMask = t_n_e <= TORSION_WINDOW_DEG.negative;

%% --- fit and report ---
fitResult_positive = fit_torque_model(t_p_e(posMask), ACN_p_e_n(posMask), dtz_p_e(posMask))
fitResult_negative = fit_torque_model(t_n_e(negMask), ACN_n_e_n(negMask), dtz_n_e(negMask))

%% --- diagnostic plots ---
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