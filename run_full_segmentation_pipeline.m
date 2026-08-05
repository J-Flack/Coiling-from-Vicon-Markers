%% run_full_segmentation_pipeline.m
% Primary segmentation pipeline, as recommended: align VICON <-> Beckhoff
% using the calibration section, downsample Beckhoff to the VICON rate,
% THEN segment -- using the Beckhoff 'bend'/'torsion' channels directly
% rather than inferring structure from VICON motion alone.
%
% Pipeline:
%   1. loadViconCSV / loadBeckhoffMat
%   2. downsampleBeckhoff      -- match sample rates (1000 Hz -> 100 Hz)
%   3. alignViconBeckhoff      -- estimate the temporal lag from the
%                                 initial calibration sweep
%   4. applyAlignmentLag       -- trim both streams so they correspond
%                                 sample-for-sample from here on
%   5. computeShaftCenterline  -- ONCE, on the full aligned recording,
%                                 BEFORE segmenting into trials (see the
%                                 note at that step re: runtime)
%   6. segmentBendAngleTrialsFromBeckhoff -- segment directly from the
%                                 now-aligned 'bend'/'torsion' channels
%
% Because step 4 makes VICON and Beckhoff share indices, the sample
% indices in the resulting segs table can be used directly to slice
% viconAligned.markers.<name> AND centerline.splineCenterlines for each
% trial -- no further interpolation needed.

clear; clc;

%% --- paths ---
viconPath    = '5mm04.csv';
beckhoffPath = '5mm_B_Initial.mat';
calibWindowSec = 30;   % must fully contain the initial alignment sweep
                       % in BOTH streams -- see note below if you change it

%% --- 1. load ---
vicon    = loadViconCSV(viconPath);
beckhoff = loadBeckhoffMat(beckhoffPath);

fprintf('VICON   : %d frames at %.2f Hz (%.1f s)\n', numel(vicon.time), vicon.sampleRate, vicon.time(end));
fprintf('Beckhoff: %d samples at %.2f Hz (%.1f s)\n', numel(beckhoff.t), beckhoff.sampleRate, beckhoff.t(end));
fprintf('Beckhoff channels: %s\n', strjoin(beckhoff.channelNames, ', '));

if ~isfield(beckhoff, 'bend') || ~isfield(beckhoff, 'torsion')
    error(['Expected ''bend'' and ''torsion'' channels in the Beckhoff file but ' ...
           'found: %s. Check loadBeckhoffMat output / beckhoff.channelNames above.'], ...
           strjoin(beckhoff.channelNames, ', '));
end

%% --- 2. downsample Beckhoff to the VICON rate ---
beckhoffDown = downsampleBeckhoff(beckhoff, vicon);
fprintf('Beckhoff downsampled to %.2f Hz (%d samples)\n', beckhoffDown.sampleRate, numel(beckhoffDown.t));

%% --- 3. align using the calibration section ---
align = alignViconBeckhoff(vicon, beckhoffDown, calibWindowSec);
fprintf('\nAlignment: lagSamples = %d (%.3f s), signFlipped = %d\n', ...
    align.lagSamples, align.lagSamples / align.fsShared, align.signFlipped);

% --- diagnostic plot: verify alignment visually before trusting it ---
figure('Name', 'VICON <-> Beckhoff calibration alignment', 'Color', 'w');
nCalib = numel(align.viconCalib);
tCalib = (0:nCalib-1) / align.fsShared;
plot(tCalib, align.viconCalib, 'b', 'LineWidth', 1.2); hold on;
shiftedTorsion = circshift(align.torsionCalib, align.lagSamples);
plot(tCalib, shiftedTorsion, 'r--', 'LineWidth', 1.2);
xlabel('Time (s)'); ylabel('Demeaned angle (deg, arbitrary common scale)');
legend('VICON base-cluster angle', 'Beckhoff torsion (shifted by lagSamples)');
title(sprintf('Calibration window alignment (lag = %d samples)', align.lagSamples));
hold off;
fprintf(['Check the plot above: the two traces should overlap closely. If they ' ...
    'don''t, the lag sign/magnitude may be wrong (e.g. calibWindowSec too short ' ...
    'to contain the full alignment sweep) -- do not trust the segmentation below ' ...
    'until this lines up.\n']);

%% --- 4. apply the lag so both streams share indices from here on ---
[viconAligned, beckhoffAligned] = applyAlignmentLag(vicon, beckhoffDown, align.lagSamples);
fprintf('\nAfter alignment: %d shared samples (%.1f s)\n', ...
    numel(viconAligned.time), viconAligned.time(end));

%% --- 5. compute the shaft centerline ONCE, on the full aligned recording,
% BEFORE segmenting into trials -- segments then just slice this result
% rather than each re-running their own spline fit.
%
% COST WARNING, read before running: computeShaftCenterline.m fits 3
% smoothing splines per frame and stores [splineResolution x 3 x nFrames]
% doubles. Over the FULL recording -- including calibration, bend-angle
% ramps, and the torsion-flat settle dwells, none of which are useful for
% the stiffness fit -- that's roughly 12x more frames than fitting only
% the ~14400 frames actually inside the 60 active windows found in step
% 6 below (144s of real cyclic data out of ~1820s total). If that ends up
% too slow/heavy in practice, the cheaper alternative is to call
% computeShaftCenterline separately per segment (slice viconAligned to
% each segment's own idx first) instead of once on everything -- ask if
% you'd rather have that version.
%
% splineResolution is dropped from the function's own default of 1000 to
% 200 here: 1000 points/frame was sized for inspecting a single trial in
% isolation, and gets expensive fast multiplied across an entire
% recording. A fixed SmoothingParam (0.999, per that function's own
% docstring) skips the per-frame GCV search, which is the single biggest
% speed lever if you keep this as a full-file pass.
splineResolution = 500;
bytesPerDouble = 8;
estGB = splineResolution * 3 * numel(viconAligned.time) * bytesPerDouble / 1e9;
fprintf(['\nAbout to compute the centerline over the FULL aligned recording: ' ...
    '%d frames x %d points x 3 = ~%.2f GB, plus per-frame spline-fit time. ' ...
    'Ctrl-C now if that''s more than you want to commit to.\n'], ...
    numel(viconAligned.time), splineResolution, estGB);

centerline = computeShaftCenterline(viconAligned, splineResolution, 1);
fprintf('Centerline computed: %d points x 3 x %d frames\n', ...
    size(centerline.splineCenterlines,1), size(centerline.splineCenterlines,3));

%% --- 6. segment directly from the aligned Beckhoff channels ---
segs = segmentBendAngleTrialsFromBeckhoff(beckhoffAligned);
disp('First 12 rows of the segment table:');
disp(segs(1:min(12, height(segs)), :));

fprintf('\nTotal detected segments: %d (expect %d = 3 repeats x 2 speeds x 10 angles)\n', ...
    height(segs), 3*2*10);

if height(segs) ~= 60
    warning('run_full_segmentation_pipeline:unexpectedSegmentCount', ...
        ['Expected 60 segments but found %d. Inspect segs and the QA plot below ' ...
         '-- check AngleTolDeg/MinHoldSec in segmentBendAngleTrialsFromBeckhoff.m ' ...
         'against the actual bend/torsion channel behaviour for this file.'], ...
         height(segs));
end

%% --- QA plot: bend/torsion channels with segment boundaries overlaid ---
% Light gray = full bend-hold window (includes settle dwell either side).
% Green/red = trimmed torsion-active window (segStart/segEnd -- use this
% one for curve fitting). Zoom into a couple of segments to compare them
% directly against a plot like the one that flagged the padding issue.
figure('Name', 'Aligned Beckhoff channels with detected segments', 'Color', 'w');
tiledlayout(2,1);

nexttile;
plot(beckhoffAligned.t, beckhoffAligned.bend, 'k'); hold on;
for i = 1:height(segs)
    xline(segs.holdStartTime(i), 'Color', [0.7 0.7 0.7]);
    xline(segs.holdEndTime(i), 'Color', [0.7 0.7 0.7], 'LineStyle', ':');
    xline(segs.segStartTime(i), 'g');
    xline(segs.segEndTime(i), 'r--');
end
ylabel('Bend angle (deg)'); title('Bend channel: gray = full hold window, green/red = trimmed active window');
hold off;

nexttile;
plot(beckhoffAligned.t, beckhoffAligned.torsion, 'k'); hold on;
for i = 1:height(segs)
    xline(segs.holdStartTime(i), 'Color', [0.7 0.7 0.7]);
    xline(segs.holdEndTime(i), 'Color', [0.7 0.7 0.7], 'LineStyle', ':');
    xline(segs.segStartTime(i), 'g');
    xline(segs.segEndTime(i), 'r--');
end
xlabel('Time (s)'); ylabel('Torsion'); title('Torsion channel: gray = full hold window, green/red = trimmed active window');
hold off;

%% --- save ---
save('5mm04_aligned_segmentation.mat', 'viconAligned', 'beckhoffAligned', 'align', 'segs', 'centerline', '-v7.3');
writetable(segs, '5mm04_segments_beckhoff.csv');
fprintf('\nSaved 5mm04_aligned_segmentation.mat and 5mm04_segments_beckhoff.csv\n');

%% --- example: slice out one trial's VICON + Beckhoff + centerline data together ---
% row = 1;
% idx = segs.segStartSample(row):segs.segEndSample(row);
% trialMarker174  = viconAligned.markers.m174(idx, :);   % one marker, this trial only
% trialTorsion    = beckhoffAligned.torsion(idx);        % Beckhoff, same samples
% trialDtz        = beckhoffAligned.dtz(idx);             % output torque, same samples
% trialCenterline = centerline.splineCenterlines(:,:,idx); % [splineResolution x 3 x nFramesInTrial]
