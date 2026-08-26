function segData = buildSegData(segs, viconAligned, beckhoffAligned, varargin)
%BUILDSEGDATA Construct the per-bend-angle segData struct array consumed
%by SegDataAnalyser.m, from the aligned outputs of
%run_full_segmentation_pipeline.m.
%
%   segData = buildSegData(segs, viconAligned, beckhoffAligned)
%   segData = buildSegData(..., 'KExcl', 1, 'FrameStride', 1, ...
%                           'SplineResolution', 500, 'SmoothingParam', 1)
%
% METHOD
%   The shaft centerline is reconstructed from viconAligned via
%   computeShaftCenterline.m at the start of this function, so the only
%   inputs this function depends on are the aligned marker/rig-controller
%   streams and the trial segmentation table -- everything else is
%   derived within this function, rather than passed in pre-computed.
%
%   One segData(i) entry is built per unique bend angle (10 levels, 0 to
%   90 degrees in 10-degree steps), pooling all repeats and speeds
%   recorded at that angle together -- the per-repeat/per-speed structure
%   is not needed downstream, only the aggregate torsion/torque/writhe
%   relationship at each configuration.
%
%   Within each trial's active window, samples are split into the
%   loading portion of each torsion half-cycle: positive_rising is
%   torsion > 0 while increasing, negative_rising is torsion < 0 while
%   decreasing (i.e. increasing in magnitude). This isolates the loading
%   branch of the torque-torsion curve from the unloading branch, which
%   is where the model in Eq. 5/6 is fit (unloading is used separately
%   for the hysteresis-area computation in Section II.D.4).
%
%   Signed writhe (Omega/ACN) is computed per frame on the corresponding
%   centerline slice via writheACN.m, the closed-form solid-angle
%   discretization of the Gauss double integral used throughout this
%   codebase. The per-frame writhe computation runs in a parfor loop: if
%   Parallel Computing Toolbox is available, frames within a trial are
%   distributed across workers; otherwise MATLAB falls back to running it
%   as an ordinary for loop with no code changes required.
%
% INPUTS
%   segs            - table from segmentBendAngleTrialsFromBeckhoff.m
%   viconAligned    - struct from applyAlignmentLag.m
%   beckhoffAligned - struct from applyAlignmentLag.m
%
% NAME-VALUE OPTIONS
%   'KExcl'            - neighbor exclusion passed to writheACN.m (default 1)
%   'FrameStride'       - process every Nth frame within each trial's
%                          active window rather than every frame (default
%                          1, i.e. every frame). Since writheACN.m's cost
%                          is O(M^2) per frame, a stride of 10 cuts total
%                          runtime by roughly 10x -- useful for a fast
%                          correctness pass while developing. Set back to
%                          1 for the frame resolution used in reported
%                          results.
%   'SplineResolution' - points per frame for the centerline
%                         reconstruction, passed to
%                         computeShaftCenterline.m (default 500, matching
%                         run_full_segmentation_pipeline.m)
%   'SmoothingParam'    - fixed smoothing parameter for the centerline
%                          spline fit, passed to computeShaftCenterline.m
%                          (default 1, matching
%                          run_full_segmentation_pipeline.m)
%
% OUTPUT  segData - [1 x nBendAngles] struct array:
%   .bendAngleDeg
%   .positive_rising.torsion / .dtz / .Wr.ACN   [Nx1 each, pooled]
%   .negative_rising.torsion / .dtz / .Wr.ACN   [Nx1 each, pooled]
%
% EXAMPLE
%   load('5mm04_aligned_segmentation.mat', 'viconAligned', 'beckhoffAligned', 'segs');
%   segData = buildSegData(segs, viconAligned, beckhoffAligned);              % full resolution
%   segDataFast = buildSegData(segs, viconAligned, beckhoffAligned, 'FrameStride', 10);  % quick check

    p = inputParser;
    addParameter(p, 'KExcl', 1);
    addParameter(p, 'FrameStride', 1);
    addParameter(p, 'SplineResolution', 500);
    addParameter(p, 'SmoothingParam', 1);
    parse(p, varargin{:});
    kExcl            = p.Results.KExcl;
    frameStride      = p.Results.FrameStride;
    splineResolution = p.Results.SplineResolution;
    smoothingParam   = p.Results.SmoothingParam;

    %% --- reconstruct the centerline fresh from the aligned marker data ---
    centerline = computeShaftCenterline(viconAligned, splineResolution, smoothingParam);

    %% --- build segData: one entry per bend angle, pooled across repeats/speeds ---
    bendLevels = unique(segs.bendAngleDeg);
    segData = struct([]);

    for gi = 1:numel(bendLevels)
        thisAngle = bendLevels(gi);
        rows = find(segs.bendAngleDeg == thisAngle);

        posT = []; posDtz = []; posACN = [];
        negT = []; negDtz = []; negACN = [];

        for r = rows(:)'
            idx = segs.segStartSample(r):segs.segEndSample(r);
            idx = idx(1:frameStride:end);

            torsion  = beckhoffAligned.torsion(idx);
            dtz      = beckhoffAligned.dtz(idx);
            dTorsion = [diff(torsion); 0];

            posRisingMask = (torsion > 0) & (dTorsion > 0);
            negRisingMask = (torsion < 0) & (dTorsion < 0);

            nK = numel(idx);
            wrACN = nan(nK, 1);
            parfor k = 1:nK
                curve = squeeze(centerline.splineCenterlines(:, :, idx(k))); %#ok<PFBNS>
                res = writheACN(curve, 'NeighborExclusion', kExcl);
                wrACN(k) = res.Wr;
            end

            posT   = [posT;   torsion(posRisingMask)];   %#ok<AGROW>
            posDtz = [posDtz; dtz(posRisingMask)];        %#ok<AGROW>
            posACN = [posACN; wrACN(posRisingMask)];      %#ok<AGROW>

            negT   = [negT;   torsion(negRisingMask)];    %#ok<AGROW>
            negDtz = [negDtz; dtz(negRisingMask)];         %#ok<AGROW>
            negACN = [negACN; wrACN(negRisingMask)];       %#ok<AGROW>
        end

        segData(gi).bendAngleDeg = thisAngle;
        segData(gi).positive_rising.torsion = posT;
        segData(gi).positive_rising.dtz     = posDtz;
        segData(gi).positive_rising.Wr.ACN  = posACN;
        segData(gi).negative_rising.torsion = negT;
        segData(gi).negative_rising.dtz     = negDtz;
        segData(gi).negative_rising.Wr.ACN  = negACN;
    end
end