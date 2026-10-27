function levels = detectHoldLevels(x, varargin)
%DETECTHOLDLEVELS Auto-detect the distinct "held" plateau values within a
%step-and-ramp signal (e.g. a commanded bend-angle channel that dwells
%at a fixed value for tens of seconds, ramps briefly to the next value,
%dwells again, etc.) -- WITHOUT assuming a sign convention or a specific
%nominal value list.
%
% Why this exists: a first version of segmentBendAngleTrialsFromBeckhoff.m
% searched for a hardcoded nominal list (0:10:90) and silently found only
% the one level (0) that happened to match regardless of sign, because
% the actual 'bend' channel on this rig/file runs 0 down to -90, not 0 up
% to +90 -- the same kind of sign-convention trap already seen between
% dtz and torsion on this rig. Detecting levels directly from the data
% removes that whole class of bug.
%
% METHOD: histogram the signal at fine resolution. Time spent dwelling
% at a held level produces a sharp, tall spike in the histogram, while
% time spent ramping between levels spreads thinly across every
% intermediate value -- so dwell levels stand out as histogram peaks well
% above the flat ramp background, regardless of which direction or units
% the channel happens to use.
%
%   levels = detectHoldLevels(x)
%   levels = detectHoldLevels(x, 'BinWidth', 0.5, 'MinProminence', 5, 'ClusterTolDeg', 1.5)
%
% Name-value options:
%   'BinWidth'       histogram bin width, in the signal's own units
%                     (default 0.5)
%   'MinProminence'  a histogram bin counts as part of a "peak" if its
%                     count exceeds MinProminence x the median nonzero
%                     bin count (default 5). This is a RATIO, not a
%                     fixed absolute count, so it self-adjusts to file
%                     length / sample rate / number of repeats.
%   'ClusterTolDeg'  merge peak bins within this distance of each other
%                     into a single level (default 3 x BinWidth)
%
% OUTPUT  levels - sorted column vector of detected dwell values, in
%   whatever sign/units the input signal itself uses (deliberately NOT
%   normalized or sign-flipped -- confirm what that sign convention
%   actually means against your rig documentation, the same way
%   dtz/torsion's relative sign needed confirming, rather than assuming
%   this function got it "the right way up" for you).

    p = inputParser;
    addParameter(p, 'BinWidth', 0.5);
    addParameter(p, 'MinProminence', 5);
    addParameter(p, 'ClusterTolDeg', []);
    parse(p, varargin{:});
    binWidth      = p.Results.BinWidth;
    minProminence = p.Results.MinProminence;
    clusterTol    = p.Results.ClusterTolDeg;
    if isempty(clusterTol)
        clusterTol = 3 * binWidth;
    end

    x = x(~isnan(x));
    if isempty(x)
        levels = [];
        return
    end

    edges   = floor(min(x)/binWidth)*binWidth : binWidth : ceil(max(x)/binWidth)*binWidth;
    counts  = histcounts(x, edges);
    centers = edges(1:end-1) + binWidth/2;

    nonzero = counts(counts > 0);
    if isempty(nonzero)
        levels = [];
        return
    end
    thresh = minProminence * median(nonzero);

    isPeak      = counts > thresh;
    peakCenters = centers(isPeak);
    peakCounts  = counts(isPeak);

    if isempty(peakCenters)
        warning('detectHoldLevels:noPeaksFound', ...
            'No histogram bins exceeded MinProminence x median count -- try a lower MinProminence.');
        levels = [];
        return
    end

    % --- cluster adjacent peak bins into single levels (weighted by count) ---
    [peakCenters, order] = sort(peakCenters);
    peakCounts = peakCounts(order);

    levels = [];
    clusterVals    = peakCenters(1);
    clusterWeights = peakCounts(1);
    for i = 2:numel(peakCenters)
        if (peakCenters(i) - clusterVals(end)) <= clusterTol
            clusterVals(end+1)    = peakCenters(i);    %#ok<AGROW>
            clusterWeights(end+1) = peakCounts(i);      %#ok<AGROW>
        else
            levels(end+1) = sum(clusterVals .* clusterWeights) / sum(clusterWeights); %#ok<AGROW>
            clusterVals    = peakCenters(i);
            clusterWeights = peakCounts(i);
        end
    end
    levels(end+1) = sum(clusterVals .* clusterWeights) / sum(clusterWeights);

    levels = sort(levels(:));

end
