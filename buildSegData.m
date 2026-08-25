function segData = buildSegData(segs, beckhoffAligned, centerline, varargin)
%BUILDSEGDATA Construct the per-bend-angle segData struct array consumed
%by SegDataAnalyser.m, from the outputs of run_full_segmentation_pipeline.m.
%
%   segData = buildSegData(segs, beckhoffAligned, centerline)
%   segData = buildSegData(..., 'KExcl', 1)
%
% METHOD
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
%   codebase.
%
% INPUTS
%   segs            - table from segmentBendAngleTrialsFromBeckhoff.m
%   beckhoffAligned - struct from applyAlignmentLag.m
%   centerline      - struct from computeShaftCenterline.m, computed on
%                     the same aligned recording as segs/beckhoffAligned
%                     (sample k in centerline.splineCenterlines(:,:,k)
%                     corresponds to beckhoffAligned.t(k))
%
% NAME-VALUE OPTIONS
%   'KExcl' - neighbor exclusion passed to writheACN.m (default 1)
%
% OUTPUT  segData - [1 x nBendAngles] struct array:
%   .bendAngleDeg
%   .positive_rising.torsion / .dtz / .Wr.ACN   [Nx1 each, pooled]
%   .negative_rising.torsion / .dtz / .Wr.ACN   [Nx1 each, pooled]
%
% EXAMPLE
%   load('5mm04_aligned_segmentation.mat', 'beckhoffAligned', 'segs', 'centerline');
%   segData = buildSegData(segs, beckhoffAligned, centerline);

    p = inputParser;
    addParameter(p, 'KExcl', 1);
    parse(p, varargin{:});
    kExcl = p.Results.KExcl;

    bendLevels = unique(segs.bendAngleDeg);
    segData = struct([]);

    for gi = 1:numel(bendLevels)
        thisAngle = bendLevels(gi);
        rows = find(segs.bendAngleDeg == thisAngle);

        posT = []; posDtz = []; posACN = [];
        negT = []; negDtz = []; negACN = [];

        for r = rows(:)'
            idx = segs.segStartSample(r):segs.segEndSample(r);

            torsion  = beckhoffAligned.torsion(idx);
            dtz      = beckhoffAligned.dtz(idx);
            dTorsion = [diff(torsion); 0];

            posRisingMask = (torsion > 0) & (dTorsion > 0);
            negRisingMask = (torsion < 0) & (dTorsion < 0);

            wrACN = nan(numel(idx), 1);
            for k = 1:numel(idx)
                curve = squeeze(centerline.splineCenterlines(:, :, idx(k)));
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