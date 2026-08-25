function segs = segmentBendAngleTrialsFromBeckhoff(beckhoff, varargin)
%SEGMENTBENDANGLETRIALSFROMBECKHOFF Segment a long Beckhoff recording
%into individual bend-angle trials directly from the recorded 'bend' and
%'torsion' channels.
%
% This is the PREFERRED segmentation method once Beckhoff data is
% available: the 'bend' channel is a direct, ground-truth readout of the
% commanded bend angle, so trial boundaries come from simply locating
% where 'bend' is held flat for a sustained duration -- no envelope
% thresholds, no timing templates needed.
%
% Each detected bend-hold window is then trimmed down to the
% torsion-ACTIVE sub-range within it: the rig dwells at ~zero torsion for
% a few seconds both before and after the real cyclic motion (settling
% time), so the full hold window is wider than the 5 actual torsion
% cycles. segStart/segEnd below refer to that trimmed active window
% (recommended for curve fitting); holdStart/holdEnd refer to the full,
% untrimmed bend-hold window (useful for context/QA -- e.g. to see how
% much settle time is being excluded). Trimming also fixes a precision
% issue: estimating freqHz/nCyclesEstimated over the *untrimmed* window
% risks spurious zero-crossings if the flat settle dwell isn't exactly
% 0.0 (e.g. small sensor noise) -- computing it over the active window
% only avoids that entirely.
%
% v2: the bend-angle HOLD LEVELS are now auto-detected from the data via
% detectHoldLevels.m, rather than assumed to be 0:10:90. The first
% version hardcoded that list and silently found only the bend=0 level,
% because this rig's 'bend' channel actually runs 0 DOWN TO -90, not 0 up
% to +90 -- the same kind of sign-convention trap already hit between
% dtz and torsion on this rig. Repeat-boundary detection is also no
% longer direction-dependent: instead of looking for the angle "dropping
% back down" (which assumed an ascending 0->90 sweep), repeats are now
% assigned positionally -- every N consecutive segments within a speed
% group is one repeat, where N is the number of detected hold levels.
% This works regardless of which direction the sweep actually runs.
%
%   segs = segmentBendAngleTrialsFromBeckhoff(beckhoff)
%   segs = segmentBendAngleTrialsFromBeckhoff(beckhoff, 'AngleTolDeg', 2, ...)
%   segs = segmentBendAngleTrialsFromBeckhoff(beckhoff, 'BendAnglesDeg', 0:10:90)  % optional cross-check only
%
% INPUT
%   beckhoff - struct from loadBeckhoffMat.m, with at least:
%                .t        [N x 1] time, s
%                .bend     [N x 1] commanded/measured bend angle, deg
%                .torsion  [N x 1] commanded/measured torsion angle
%                          (deg or rad -- units don't matter here, only
%                          used for zero-crossing frequency estimation
%                          and the active-window trim, both of which are
%                          scale-relative, not absolute)
%
% Name-value options:
%   'BendAnglesDeg'      OPTIONAL nominal bend angles, used ONLY as a
%                        cross-check against what's actually detected
%                        (e.g. a count/magnitude mismatch warning) --
%                        detection itself never depends on this
%                        matching. Default [] (no cross-check). Spacing
%                        is compared by magnitude only; sign is not
%                        compared, since that's the exact convention
%                        mismatch this version is designed not to
%                        assume.
%   'AngleTolDeg'        tolerance for "bend is at this detected level" (default 2)
%   'MinHoldSec'         minimum sustained duration at a level to count as
%                        a real trial segment, filtering out the angle
%                        just passing through during a ramp between
%                        angles (default 3 -- shorter than the shortest
%                        real fast-trial active duration, so it won't
%                        reject a genuine fast segment)
%   'ActiveTolFraction'  fraction of this hold's own peak |torsion| above
%                        which a sample counts as "actively cycling"
%                        rather than settling (default 0.05). Relative,
%                        not absolute, so it's unit-agnostic (works for
%                        torsion in degrees or radians) and amplitude-
%                        agnostic (works whether the cycling amplitude
%                        for this particular hold is large or small).
%   Any other name-value pair is passed through to detectHoldLevels.m
%   (e.g. 'BinWidth', 'MinProminence', 'ClusterTolDeg') for tuning the
%   level-detection step itself.
%
% OUTPUT  segs - table, one row per detected (repeat, bend angle)
%   segment, sorted by time, columns:
%     bendAngleDeg (sign/units exactly as recorded in beckhoff.bend --
%       NOT normalized)
%     segStartTime/segEndTime/segStartSample/segEndSample  - the trimmed
%       torsion-ACTIVE window (use this for curve fitting)
%     holdStartTime/holdEndTime/holdStartSample/holdEndSample - the full,
%       untrimmed bend-hold window (context/QA only)
%     freqHz, nCyclesEstimated  - estimated from the active window
%     speedLabel ('slow'/'fast'), repeatIdx

    p = inputParser;
    p.KeepUnmatched = true;
    addParameter(p, 'BendAnglesDeg', []);
    addParameter(p, 'AngleTolDeg', 2);
    addParameter(p, 'MinHoldSec', 3);
    addParameter(p, 'ActiveTolFraction', 0.05);
    parse(p, varargin{:});

    bendAnglesDegNominal = p.Results.BendAnglesDeg;
    angleTol             = p.Results.AngleTolDeg;
    minHoldSec           = p.Results.MinHoldSec;
    activeTolFraction    = p.Results.ActiveTolFraction;
    detectArgs           = struct2pairs(p.Unmatched);

    t    = beckhoff.t(:);
    bend = beckhoff.bend(:);
    tors = beckhoff.torsion(:);
    fs   = 1 / median(diff(t));

    % --- auto-detect the actual hold levels, whatever sign/scale they use ---
    bendLevels = detectHoldLevels(bend, detectArgs{:});
    nLevels = numel(bendLevels);
    fprintf('detectHoldLevels found %d hold levels: %s\n', nLevels, mat2str(bendLevels', 4));

    if ~isempty(bendAnglesDegNominal)
        nNominal = numel(bendAnglesDegNominal);
        if nNominal ~= nLevels
            warning('segmentBendAngleTrialsFromBeckhoff:levelCountMismatch', ...
                ['Detected %d hold levels but %d nominal BendAnglesDeg were given. ' ...
                 'Proceeding with the %d levels actually found in the data -- check ' ...
                 'AngleTolDeg/MinProminence if this looks wrong.'], nLevels, nNominal, nLevels);
        else
            spacingDetected = sort(abs(diff(sort(bendLevels))));
            spacingNominal  = sort(abs(diff(sort(bendAnglesDegNominal(:)))));
            if max(abs(spacingDetected - spacingNominal)) > angleTol
                warning('segmentBendAngleTrialsFromBeckhoff:levelSpacingMismatch', ...
                    ['Detected hold-level spacing does not closely match the nominal ' ...
                     'BendAnglesDeg spacing (max diff %.2f deg). Detected: %s'], ...
                     max(abs(spacingDetected - spacingNominal)), mat2str(bendLevels', 4));
            end
        end
    end

    if nLevels == 0
        segs = emptySegsTable();
        return
    end

    % --- find sustained-hold windows at each detected level, then trim
    % each one down to the sub-range where torsion is actually cycling
    % (the hold window itself includes a settle dwell at ~zero torsion
    % before/after the real cyclic motion -- see ActiveTolFraction) ---
    rows = {};
    for a = bendLevels'
        isAtAngle = abs(bend - a) <= angleTol;
        d = diff([0; isAtAngle; 0]);
        starts = find(d == 1);
        ends   = find(d == -1) - 1;

        for k = 1:numel(starts)
            durSec = (ends(k) - starts(k) + 1) / fs;
            if durSec < minHoldSec
                continue   % too short -- just passing through during a ramp
            end

            holdIdx = starts(k):ends(k);
            torsHold = tors(holdIdx);

            % --- trim to the torsion-active sub-range ---
            % Threshold is a FRACTION of this hold's own peak |torsion|,
            % not an absolute degree/radian value, so it works whether
            % torsion is logged in degrees or radians, and regardless of
            % amplitude. Assumes the settle dwell sits at ~zero torsion
            % (motor at rest, not actively driving), which is a property
            % of what "torsion" means rather than a sign/scale assumption.
            segAmp = max(abs(torsHold));
            if segAmp > 0
                activeMask = abs(torsHold) > activeTolFraction * segAmp;
            else
                activeMask = true(size(torsHold));
            end
            if any(activeMask)
                firstActive = find(activeMask, 1, 'first');
                lastActive  = find(activeMask, 1, 'last');
            else
                firstActive = 1;
                lastActive  = numel(holdIdx);
            end
            activeStartSample = holdIdx(firstActive);
            activeEndSample   = holdIdx(lastActive);

            activeIdx  = activeStartSample:activeEndSample;
            torsActive = tors(activeIdx) - mean(tors(activeIdx), 'omitnan');
            activeDurSec = (activeEndSample - activeStartSample + 1) / fs;
            crossings = sum(sign(torsActive(1:end-1)) .* sign(torsActive(2:end)) < 0);
            nCycles = crossings / 2;
            freqHz  = nCycles / activeDurSec;

            rows(end+1, :) = {a, ...
                t(activeStartSample), t(activeEndSample), activeStartSample, activeEndSample, ...
                t(starts(k)), t(ends(k)), starts(k), ends(k), ...
                freqHz, nCycles}; %#ok<AGROW>
        end
    end

    if isempty(rows)
        segs = emptySegsTable();
        return
    end

    segs = cell2table(rows, 'VariableNames', ...
        {'bendAngleDeg', ...
         'segStartTime','segEndTime','segStartSample','segEndSample', ...
         'holdStartTime','holdEndTime','holdStartSample','holdEndSample', ...
         'freqHz','nCyclesEstimated'});
    segs = sortrows(segs, 'segStartTime');

    % --- classify slow/fast from the estimated frequency ---
    validFreq = segs.freqHz(segs.freqHz > 0);
    midFreq = sqrt(min(validFreq) * max(validFreq));  % geometric-mean split point
    segs.speedLabel = repmat({'slow'}, height(segs), 1);
    segs.speedLabel(segs.freqHz > midFreq) = {'fast'};

    % --- assign repeat index POSITIONALLY within each speed group: every
    % nLevels consecutive (time-sorted) segments is one repeat. This does
    % NOT assume which direction the sweep runs (ascending, descending,
    % or anything else) -- it only assumes each repeat visits every
    % detected level exactly once, which is what the protocol specifies. ---
    segs.repeatIdx = nan(height(segs), 1);
    for spLabel = {'slow', 'fast'}
        idx = find(strcmp(segs.speedLabel, spLabel{1}));
        if isempty(idx)
            continue
        end
        if mod(numel(idx), nLevels) ~= 0
            warning('segmentBendAngleTrialsFromBeckhoff:repeatGroupingMismatch', ...
                ['Found %d ''%s'' segments, not a multiple of the %d detected hold ' ...
                 'levels -- repeatIdx assignment below may be misaligned. Inspect ' ...
                 'segs for this speed group before trusting repeatIdx.'], ...
                 numel(idx), spLabel{1}, nLevels);
        end
        positionInGroup = (1:numel(idx))';
        segs.repeatIdx(idx) = ceil(positionInGroup / nLevels);
    end

end

function pairs = struct2pairs(s)
    fns = fieldnames(s);
    pairs = cell(1, 2*numel(fns));
    pairs(1:2:end) = fns;
    pairs(2:2:end) = struct2cell(s);
end

function segs = emptySegsTable()
    segs = table([], [], [], [], [], [], [], [], [], [], [], [], [], ...
        'VariableNames', {'bendAngleDeg', ...
        'segStartTime','segEndTime','segStartSample','segEndSample', ...
        'holdStartTime','holdEndTime','holdStartSample','holdEndSample', ...
        'freqHz','nCyclesEstimated','speedLabel','repeatIdx'});
end
