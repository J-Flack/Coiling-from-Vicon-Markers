
function result = computeShaftCenterline(viconData, splineResolution, smoothingParam)
%COMPUTESHAFTCENTERLINE Generate the shaft centerline trajectory from
%VICON marker data, generalized to any number of spiral-mounted shaft
%markers, excluding the base/alignment markers.
%
%   result = computeShaftCenterline(viconData)
%   result = computeShaftCenterline(viconData, splineResolution)
%   result = computeShaftCenterline(viconData, splineResolution, smoothingParam)
%
% INPUTS
%   viconData        - struct from loadViconCSV.m
%   splineResolution - number of points to evaluate the fitted spline at,
%                      per frame (default: 1000)
%   smoothingParam   - optional fixed smoothing parameter (0-1) for the
%                      'smoothingspline' fit. If omitted/empty, MATLAB
%                      auto-selects a smoothing parameter per frame via
%                      generalized cross-validation (the default
%                      behaviour in the original DataProcessor1.m).
%                      Fixing this (e.g. 0.999, as previously explored)
%                      skips that per-frame search and can substantially
%                      speed up processing on long recordings, at the
%                      cost of not re-tuning smoothing strength frame by
%                      frame.
%
% METHOD
%   Shaft markers are mounted in a spiral pattern around the shaft
%   (~120 deg of rotation between consecutive markers), so individual
%   marker positions are offset from the true centerline by the mounting
%   radius. Averaging every sliding group of 3 consecutive markers (by
%   ascending numeric ID) approximately cancels this radial offset, since
%   three points spaced ~120 deg apart around a circle average close to
%   its center. A smoothing spline is then fit through these triplet
%   centers (normalized arc length vs X, Y, Z) and evaluated at
%   splineResolution points to give a dense centerline per frame -- the
%   same approach as DataProcessor1.m's spline block, generalized to
%   whatever marker count is present in a given trial.
%
% MARKER SELECTION
%   - Any marker whose (sanitized) name starts with "base" is treated as
%     an alignment/base marker and excluded.
%   - All remaining markers must have a numeric ID embedded in their name
%     (as produced by loadViconCSV.m, e.g. "m24" -> 24). They are sorted
%     ascending by that ID before processing as a safety net -- column
%     order in the source file is expected to already be ascending, but
%     this guarantees correct physical ordering along the shaft even if
%     that ever isn't the case, regardless of how many markers a given
%     trial has.
%   - At least 3 shaft markers are required (one full triplet).
%
% OUTPUT  result (struct):
%   .splineCenterlines - [splineResolution x 3 x T] centerline points
%                        (mm), per frame
%   .markerNames        - {1 x nMarkers} sanitized shaft marker names
%                        used, sorted ascending by numeric ID
%   .markerIDs          - [1 x nMarkers] the corresponding numeric IDs
%   .tripletCount       - number of sliding triplets = nMarkers - 2
%   .sFine              - [splineResolution x 1] normalized arc-length
%                        positions (0 to 1) of the spline points
%   .time, .sampleRate  - passed through from viconData for convenience
%
% EXAMPLE
%   v = loadViconCSV('6mmMed03.csv');
%   c = computeShaftCenterline(v);
%   frame = 1000;
%   plot3(c.splineCenterlines(:,1,frame), c.splineCenterlines(:,2,frame), c.splineCenterlines(:,3,frame));
%   xlabel('X'); ylabel('Y'); zlabel('Z'); axis equal; grid on;

    if nargin < 2 || isempty(splineResolution)
        splineResolution = 1000;
    end
    if nargin < 3
        smoothingParam = [];
    end

    if ~isfield(viconData, 'names') || ~isfield(viconData, 'markers')
        error('computeShaftCenterline:badInput', ...
            'viconData must be a struct from loadViconCSV.m (missing .names/.markers).');
    end

    %% --- 1. Identify and sort shaft markers (exclude base markers) ---
    allNames = viconData.names;
    isBase = startsWith(allNames, 'base', 'IgnoreCase', true);
    shaftNames = allNames(~isBase);

    markerIDs = nan(size(shaftNames));
    for k = 1:numel(shaftNames)
        digits = regexp(shaftNames{k}, '\d+', 'match', 'once');
        if isempty(digits)
            warning('computeShaftCenterline:noNumericID', ...
                'Marker "%s" has no numeric ID and is not a base marker -- skipping.', ...
                shaftNames{k});
            continue
        end
        markerIDs(k) = str2double(digits);
    end

    validMask  = ~isnan(markerIDs);
    shaftNames = shaftNames(validMask);
    markerIDs  = markerIDs(validMask);

    [markerIDs, sortOrder] = sort(markerIDs);
    shaftNames = shaftNames(sortOrder);

    nMarkers = numel(shaftNames);
    if nMarkers < 3
        error('computeShaftCenterline:tooFewMarkers', ...
            ['Found only %d shaft marker(s) after excluding base markers; ' ...
             'at least 3 are needed for triplet-averaging.'], nMarkers);
    end

    %% --- 2. Assemble marker data array [nMarkers x 3 x T], sorted order ---
    T = size(viconData.markers.(shaftNames{1}), 1);
    markerData = zeros(nMarkers, 3, T);
    for k = 1:nMarkers
        markerData(k, :, :) = permute(viconData.markers.(shaftNames{k}), [3, 2, 1]);
    end

    %% --- 3. Sliding-triplet centers (cancels spiral mounting offset) ---
    tripletCount = nMarkers - 2;
    s     = linspace(0, 1, tripletCount)';
    sFine = linspace(0, 1, splineResolution)';

    if ~isempty(smoothingParam)
        fitOpts = fitoptions('smoothingspline', 'SmoothingParam', smoothingParam);
    end

    %% --- 4. Fit a smoothing spline through the triplet centers, per frame ---
    splineCenterlines = zeros(splineResolution, 3, T);
    printInterval = max(1, round(T / 20));   % ~20 progress updates

    for t = 1:T
        frame = markerData(:, :, t);          % [nMarkers x 3]

        centerlinePts = zeros(tripletCount, 3);
        for i = 1:tripletCount
            centerlinePts(i, :) = mean(frame(i:i+2, :), 1);
        end

        if isempty(smoothingParam)
            fx = fit(s, centerlinePts(:,1), 'smoothingspline');
            fy = fit(s, centerlinePts(:,2), 'smoothingspline');
            fz = fit(s, centerlinePts(:,3), 'smoothingspline');
        else
            fx = fit(s, centerlinePts(:,1), 'smoothingspline', fitOpts);
            fy = fit(s, centerlinePts(:,2), 'smoothingspline', fitOpts);
            fz = fit(s, centerlinePts(:,3), 'smoothingspline', fitOpts);
        end

        splineCenterlines(:,1,t) = fx(sFine);
        splineCenterlines(:,2,t) = fy(sFine);
        splineCenterlines(:,3,t) = fz(sFine);

        if mod(t, printInterval) == 0 || t == T
            fprintf('computeShaftCenterline: frame %d / %d (%.0f%%)\n', t, T, 100*t/T);
        end
    end

    %% --- Package results ---
    result.splineCenterlines = splineCenterlines;
    result.markerNames       = shaftNames;
    result.markerIDs         = markerIDs;
    result.tripletCount      = tripletCount;
    result.sFine              = sFine;
    result.time               = viconData.time;
    result.sampleRate         = viconData.sampleRate;

end
