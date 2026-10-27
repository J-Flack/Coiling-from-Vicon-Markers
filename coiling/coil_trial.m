function tr = coil_trial(cfg, shaft, rep)
%COIL_TRIAL  Coiling Omega for every frame of one trial.
%
%   tr = coil_trial(cfg, shaft, rep)
%
%   Reads <cfg.dataDir>/<shaft>_<cfg.speed>_<rep>.mat (struct array 'sample',
%   one element per bend angle, written by coil_extractTrials) and returns,
%   for every frame in which all shaft markers are visible:
%     tr.frame   sample index within its bend-angle segment
%     tr.bend    bend angle [deg], as recorded
%     tr.theta   applied torsion theta_Ext [rad]   (beckhoff.torsion)
%     tr.T       output torque [Nm]                (-beckhoff.dtz)
%     tr.Omega   coiling Omega = 2*pi*DeltaWr [rad]
%   and
%     tr.maxSepDeg  largest angle between a loaded tangent and the
%                   corresponding zero-torsion tangent [deg]
%     tr.geo        fixture points and axes, tracked and untracked length
%
%   Steps (see README.md):
%     1. centreline: centres of consecutive sets of three markers, smoothed
%        with a cubic smoothing spline (cfg.nPts points, cfg.lambda)
%     2. zero-torsion reference of each bend angle: mean centreline of the
%        cfg.nRef frames with the smallest applied torsion
%     3. fixtures: the untracked length is split between the two ends
%        (cfg.split); motor-side axis = chord of the reference centreline at
%        the smallest bend angle; fixed-side axis = that axis rotated by the
%        measured bend angle
%     4. each centreline is completed to the fixtures with minimum-bending
%        cubic Hermite curves, and its tangents form a path on the unit sphere
%     5. Omega = minus the signed area between the loaded and reference paths

fprintf('  %s %s %d ... ', shaft, cfg.speed, rep); t0 = tic;
iSh = find(strcmp(cfg.shafts, shaft));
L = cfg.Lfree(iSh);
S = load(fullfile(cfg.dataDir, sprintf('%s_%s_%d.mat', shaft, cfg.speed, rep)), 'sample');
sample = S.sample; clear S
nB = numel(sample);

%% ---- pass 1: centrelines and zero-torsion references -----------------
seg = cell(nB, 1);
Sm = [];
for i = 1:nB
    s  = sample(i);
    th = deg2rad(double(s.beckhoff.torsion(:)));
    T  = -double(s.beckhoff.dtz(:));
    X  = coil_markers(s);
    if isempty(Sm), Sm = coil_smoother(size(X, 1) - 2, cfg.nPts, cfg.lambda); end
    CL = coil_centerline(X, Sm);                          % F x nPts x 3
    good = ~any(any(isnan(CL), 3), 2);

    key = abs(th); key(~good) = inf;
    [~, ord] = sort(key); Z = ord(1:cfg.nRef);
    Zc = CL(Z, :, :);
    R0 = reshape(mean(Zc, 1), [], 3);                     % reference centreline, nPts x 3
    tz = coil_unit(diff(Zc, 1, 2));
    ref.t0    = coil_unit(diff(R0, 1, 1));
    ref.P0f   = R0(1, :);
    ref.P0l   = R0(end, :);
    ref.Ltr   = sum(sqrt(sum(diff(R0, 1, 1).^2, 2)));
    ref.zPf   = mean(reshape(Zc(:, 1, :), [], 3), 1);
    ref.zPl   = mean(reshape(Zc(:, end, :), [], 3), 1);
    ref.ztl   = coil_unit(reshape(mean(mean(tz(:, end-4:end, :), 1), 2), 1, 3));
    ref.chord = coil_unit(mean(reshape(Zc(:, end, :) - Zc(:, 1, :), [], 3), 1));

    idx = (1:numel(th))';
    seg{i} = struct('th', th(good), 'T', T(good), 'frame', idx(good), ...
        'bend', double(s.bendAngleDeg), 'CL', CL(good, :, :), 'ref', ref);
end
clear sample

%% ---- fixtures -------------------------------------------------------
segbend = cellfun(@(q) abs(q.bend), seg)';
[~, i0] = min(segbend); [~, i9] = max(segbend);
refs = cellfun(@(q) q.ref, seg);
Ltr = mean([refs.Ltr]);
a0  = refs(i0).chord;                                     % motor-side axis
nAx = coil_unit(cross(refs(i0).ztl, refs(i9).ztl));       % normal to the bending plane
lt  = max(L - Ltr, 1);                                    % untracked length
l1  = cfg.split * lt; l2 = (1 - cfg.split) * lt;
pa  = refs(i0).zPf - l1 * a0;                             % motor-side fixture point

%% ---- pass 2: Omega for every frame ----------------------------------
Om = cell(nB, 1); mindot = inf;
for i = 1:nB
    q = seg{i}; r = q.ref;
    b  = coil_rodrigues(a0, nAx, deg2rad(segbend(i)));    % fixed-side axis
    pb = r.zPl + l2 * r.ztl;                              % fixed-side fixture point
    t  = coil_unit(diff(q.CL, 1, 2));                     % F x nPts-1 x 3
    cur  = coil_tangentPath(t, q.CL(:, 1, :), q.CL(:, end, :), pa, a0, pb, b, cfg.nConn);
    refp = coil_tangentPath(reshape(r.t0, 1, [], 3), reshape(r.P0f, 1, 1, 3), ...
        reshape(r.P0l, 1, 1, 3), pa, a0, pb, b, cfg.nConn);
    Om{i} = coil_omega(cur, refp);
    mindot = min(mindot, min(min(1 + sum(cur .* refp, 3))));
end

%% ---- assemble -------------------------------------------------------
nF = cellfun(@(q) numel(q.th), seg);
tr = struct();
tr.shaft = shaft; tr.speed = cfg.speed; tr.rep = rep;
tr.frame = cell2mat(cellfun(@(q) q.frame, seg, 'UniformOutput', false));
tr.bend  = repelem(cellfun(@(q) q.bend, seg), nF);
tr.theta = cell2mat(cellfun(@(q) q.th, seg, 'UniformOutput', false));
tr.T     = cell2mat(cellfun(@(q) q.T,  seg, 'UniformOutput', false));
tr.Omega = cell2mat(Om);
tr.maxSepDeg = acosd(mindot - 1);
tr.geo = struct('Lfree', L, 'Ltracked', Ltr, 'untrackedMotorSide', l1, ...
    'untrackedFixedSide', l2, 'motorAxis', a0, 'motorPoint', pa, 'bendNormal', nAx);
fprintf('%d frames, %.1f s\n', numel(tr.Omega), toc(t0));
end
