%RUN_COILING  Coiling Omega for every trial.
%
%   1. Splits each Zenodo recording in ../data into one file per trial in
%      ../data/trials (coil_extractTrials), if these are missing.
%   2. Computes Omega for every frame of the 15 trials (5 shafts x 3 repeats,
%      torsion at 0.125 Hz) and writes, per trial,
%        results/<shaft>_slow_<rep>.mat   struct 'tr' (see coil_trial)
%        results/<shaft>_slow_<rep>.csv   bend_deg, theta_rad, T_Nm, Omega_rad
%   3. Prints the largest angle between corresponding loaded and zero-torsion
%      tangents. Eq. (3)-(4) of the paper are exact while this stays below 180 deg.
%
%   Trials already in results/ are not recomputed; delete the folder to rerun.

clear; clc;
addpath(fileparts(mfilename('fullpath')));
cfg = coil_config();
if ~exist(cfg.outDir, 'dir'), mkdir(cfg.outDir); end
nSh = numel(cfg.shafts); nR = numel(cfg.reps);

%% 1. Per-trial files -------------------------------------------------------
for a = 1:nSh
    need = false;
    for r = cfg.reps
        name = sprintf('%s_%s_%d', cfg.shafts{a}, cfg.speed, r);
        need = need || (~exist(fullfile(cfg.dataDir, [name '.mat']), 'file') ...
                        && ~exist(fullfile(cfg.outDir, [name '.mat']), 'file'));
    end
    if need
        if ~exist(fullfile(cfg.alignedDir, cfg.alignedFiles{a}), 'file')
            error('run_coiling:noData', ...
                'Place %s from Zenodo (DOI 10.5281/zenodo.22108526) in %s.', ...
                cfg.alignedFiles{a}, cfg.alignedDir);
        end
        coil_extractTrials(cfg, cfg.shafts(a));
    end
end

%% 2. Coiling ---------------------------------------------------------------
fprintf('Computing coiling\n');
maxSep = zeros(nSh, nR);
for a = 1:nSh
    for k = 1:nR
        name = sprintf('%s_%s_%d', cfg.shafts{a}, cfg.speed, cfg.reps(k));
        out = fullfile(cfg.outDir, [name '.mat']);
        if exist(out, 'file')
            S = load(out, 'tr'); tr = S.tr;
        else
            tr = coil_trial(cfg, cfg.shafts{a}, cfg.reps(k));
            save(out, 'tr', '-v7');
            fid = fopen(fullfile(cfg.outDir, [name '.csv']), 'w');
            fprintf(fid, 'bend_deg,theta_rad,T_Nm,Omega_rad\n');
            fprintf(fid, '%.6g,%.8g,%.8g,%.8g\n', [tr.bend, tr.theta, tr.T, tr.Omega]');
            fclose(fid);
        end
        maxSep(a, k) = tr.maxSepDeg;
    end
end

%% 3. Validity check -------------------------------------------------------
fprintf('\nLargest angle between loaded and zero-torsion tangents [deg]\n');
for a = 1:nSh
    fprintf('  %-12s %6.1f\n', cfg.labels{a}, max(maxSep(a, :)));
end
fprintf('  all trials   %6.1f (Eq. 3-4 exact below 180)\n', max(maxSep(:)));
fprintf('Results in %s\n', cfg.outDir);
