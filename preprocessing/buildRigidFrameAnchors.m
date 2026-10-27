function frameInfo = buildRigidFrameAnchors(refFrame, extrapDist)
%BUILDRIGIDFRAMEANCHORS Build the rigid near/far anchor points from a
%near-ZERO-BEND reference frame, by extrapolating extrapDist beyond each
%measured end along the local tangent direction there. The line between
%those two anchors is then treated as a rigid body: its midpoint is the
%rig's bend-axis pivot (see the rig schematic in the paper -- the bend
%axis sits between the fixed and driven ends, not at either end).
%
%   frameInfo = buildRigidFrameAnchors(refFrame)
%   frameInfo = buildRigidFrameAnchors(refFrame, extrapDist)
%
% This replaces guessing NearLength/FarLength mount dimensions: instead,
% anchor1/anchor2 come directly from extrapolating the ACTUAL measured
% reference curve a short, fixed distance beyond where markers start/end
% -- extrapDist only needs to be "a short distance for a stable local
% tangent fit", not an accurate physical mount length.
%
% INPUT
%   refFrame    - [N x 3] centerline points from a near-ZERO-bend trial.
%                 Needs to be close to straight for the "rigid frame"
%                 assumption to be meaningful -- pick a trial/frame where
%                 bendAngleDeg is at (or nearest to) 0.
%   extrapDist  - scalar, mm, distance to extrapolate beyond each
%                 measured end (default 50)
%
% OUTPUT  frameInfo (struct):
%   .anchor1      - [1x3] near (fixed-end side) anchor, extrapDist before
%                   refFrame(1,:), along the local start tangent
%   .anchor2      - [1x3] far (driven-end side) anchor, extrapDist after
%                   refFrame(end,:), along the local end tangent
%   .center       - [1x3] midpoint of anchor1/anchor2 -- the assumed
%                   bend-axis pivot
%   .u_ref        - [1x3] unit direction, anchor1 -> anchor2
%   .halfLen      - scalar, norm(anchor2-anchor1)/2
%   .extrapDist   - the value actually used (for reference/plotting)
%
% Use this ONCE per rig/shaft (from one near-0-deg trial), then pass the
% same frameInfo into extendShaftCenterlineRigid.m for every other trial.

    if nargin < 2 || isempty(extrapDist)
        extrapDist = 50;
    end

    nFit = max(2, min(10, floor(size(refFrame,1)/4)));

    % --- start tangent: robust direction fit through the first nFit points ---
    startPts = refFrame(1:nFit, :);
    tStart = localDirection(startPts);
    if dot(refFrame(nFit,:) - refFrame(1,:), tStart) < 0
        tStart = -tStart;   % point FORWARD, into the curve
    end
    anchor1 = refFrame(1,:) - extrapDist * tStart;

    % --- end tangent: robust direction fit through the last nFit points ---
    endPts = refFrame(end-nFit+1:end, :);
    tEnd = localDirection(endPts);
    if dot(refFrame(end,:) - refFrame(end-nFit+1,:), tEnd) < 0
        tEnd = -tEnd;       % point FORWARD, continuing past the curve
    end
    anchor2 = refFrame(end,:) + extrapDist * tEnd;

    center  = (anchor1 + anchor2) / 2;
    v       = anchor2 - anchor1;
    halfLen = norm(v) / 2;
    u_ref   = v / norm(v);

    frameInfo.anchor1    = anchor1;
    frameInfo.anchor2    = anchor2;
    frameInfo.center     = center;
    frameInfo.u_ref      = u_ref;
    frameInfo.halfLen    = halfLen;
    frameInfo.extrapDist = extrapDist;

end

function t = localDirection(pts)
% Best-fit line direction through a small point cluster (dominant
% singular vector), more stable against local noise/wiggle than a raw
% 2-point secant.
    c = mean(pts, 1);
    [~, ~, V] = svd(pts - c, 'econ');
    t = V(:,1)';
end