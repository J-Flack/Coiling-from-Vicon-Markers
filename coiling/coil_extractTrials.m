function coil_extractTrials(cfg, shafts)
%COIL_EXTRACTTRIALS  Split the aligned recordings into one file per trial.
%
%   coil_extractTrials()            all shafts in coil_config
%   coil_extractTrials(cfg, shafts) selected shafts, e.g. {'6mm_s'}
%
%   Reads the aligned recording of each shaft deposited on Zenodo
%   (DOI 10.5281/zenodo.22108526), <cfg.alignedDir>/<cfg.alignedFiles{i}>,
%   e.g. data/8mmData.mat. Each file holds viconAligned, beckhoffAligned and
%   the trial table segs (produced by preprocessing/run_full_segmentation_pipeline.m).
%   Only repeats cfg.reps are extracted; the short segment recorded after the
%   last repeat (labelled repeat 4) is skipped.
%
%   For every repeat of the trials at cfg.speed it writes <cfg.dataDir>/<shaft>_<speed>_<rep>.mat
%   containing a struct array 'sample', one element per bend angle, in the
%   row order of segs. Each element holds the samples
%   segs.segStartSample(i):segs.segEndSample(i) of the aligned streams:
%     .markers.<name>     [N x 3] marker positions (mm), base markers included
%     .beckhoff.<channel> [N x 1] rig-controller channels (torsion in deg, dtz, bend, ...)
%     .time               [N x 1] time (s)
%   plus the segs columns of that row (bendAngleDeg, speedLabel, repeatIdx, ...).
%   These are the inputs read by coil_trial.
%
%   The 'centerline' variable in the aligned files is the reconstruction used
%   in an earlier version of the paper; it is not used here, because
%   coil_trial rebuilds the centreline from the markers.

if nargin < 1 || isempty(cfg), cfg = coil_config(); end
if nargin < 2 || isempty(shafts), shafts = cfg.shafts; end
if ~exist(cfg.dataDir, 'dir'), mkdir(cfg.dataDir); end

for a = 1:numel(shafts)
    iSh = find(strcmp(cfg.shafts, shafts{a}));
    src = fullfile(cfg.alignedDir, cfg.alignedFiles{iSh});
    fprintf('Reading %s\n', src);
    S = load(src, 'viconAligned', 'beckhoffAligned', 'segs');
    segs = S.segs;
    vars = segs.Properties.VariableNames;
    mk = fieldnames(S.viconAligned.markers);
    bk = fieldnames(S.beckhoffAligned);
    nT = numel(S.beckhoffAligned.torsion);
    bk = bk(cellfun(@(f) isnumeric(S.beckhoffAligned.(f)) && isvector(S.beckhoffAligned.(f)) ...
        && numel(S.beckhoffAligned.(f)) == nT, bk));      % per-sample channels only

    for r = cfg.reps
        rows = find(strcmp(cellstr(segs.speedLabel), cfg.speed) & segs.repeatIdx == r);
        if isempty(rows)
            warning('coil_extractTrials:noRows', '%s: no %s trials for repeat %d', shafts{a}, cfg.speed, r);
            continue
        end
        sample = struct([]);
        for j = 1:numel(rows)
            i = rows(j);
            idx = segs.segStartSample(i):segs.segEndSample(i);
            e = struct();
            for v = 1:numel(vars)
                val = segs.(vars{v})(i);
                if iscell(val), val = val{1}; end
                e.(vars{v}) = val;
            end
            e.time = S.viconAligned.time(idx); e.time = e.time(:);
            for k = 1:numel(bk)
                x = S.beckhoffAligned.(bk{k});
                e.beckhoff.(bk{k}) = x(idx); e.beckhoff.(bk{k}) = e.beckhoff.(bk{k})(:);
            end
            for k = 1:numel(mk)
                M = S.viconAligned.markers.(mk{k});
                if size(M, 2) ~= 3, M = M.'; end              % [frames x 3]
                e.markers.(mk{k}) = M(idx, :);
            end
            if isempty(sample), sample = e; else, sample(j) = e; end %#ok<AGROW>
        end
        out = fullfile(cfg.dataDir, sprintf('%s_%s_%d.mat', shafts{a}, cfg.speed, r));
        save(out, 'sample', '-v7');
        fprintf('  wrote %s (%d bends)\n', out, numel(sample));
    end
end
end
