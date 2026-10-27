function angleDeg = baseSquareRotationAngle(viconData)
%BASESQUARESROTATIONANGLE Unwrapped rotation angle (deg) of the base1-4
%marker cluster (the driven-fixture square), used as a VICON-side proxy
%for the commanded torsion angle -- this is what alignViconBeckhoff.m
%cross-correlates against the Beckhoff 'torsion' channel.
%
%   angleDeg = baseSquareRotationAngle(viconData)
%
% METHOD
%   1. Read base1..base4 directly from viconData.markers (loadViconCSV.m
%      sanitizes raw names like '5mm:base1' down to 'base1', so this is
%      just a direct field lookup -- no name matching needed).
%   2. Estimate a single rotation-axis direction for the whole record as
%      the mean of cross(base3-base1, base4-base2) across every frame
%      where all 4 markers are valid -- i.e. the normal to the
%      (assumed-rigid, assumed-flat) base square. On real data from this
%      rig this normal is extremely stable over time (sub-1% relative
%      variation during a calibration window), which is the whole point
%      of using a 4-marker rigid cluster rather than a single point: the
%      torsion axis direction falls out directly without needing a
%      separate geometric calibration step.
%   3. Build an orthonormal basis (u,v) spanning the plane perpendicular
%      to that axis.
%   4. Project (base1 - clusterCentroid) onto (u,v) each frame and take
%      atan2(v-component, u-component) as the instantaneous angle.
%   5. Unwrap -- separately within each contiguous run of
%      all-4-markers-valid frames, since unwrap() does not handle NaN
%      gaps gracefully and this rig's base markers are known to drop out
%      for extended stretches later in long recordings (this function
%      will simply return NaN there rather than something silently
%      wrong).
%
% INPUT   viconData - struct from loadViconCSV.m
% OUTPUT  angleDeg   - [N x 1] unwrapped rotation angle, degrees. NaN at
%                      any frame where one or more of base1-4 are
%                      missing AND at the frame immediately following a
%                      gap (unwrap needs an unbroken run to anchor to;
%                      the run after a gap is unwrapped on its own and
%                      will generally sit at an arbitrary multiple of
%                      360 degrees relative to the run before it -- fine
%                      for the calibration-window use case in
%                      alignViconBeckhoff.m, since that only uses one
%                      early contiguous run, but don't assume continuity
%                      in absolute angle across a dropout elsewhere).

    baseNames = {'base1','base2','base3','base4'};
    N = numel(viconData.time);
    B = nan(N, 4, 3);
    for i = 1:4
        if ~isfield(viconData.markers, baseNames{i})
            error('baseSquareRotationAngle:markerNotFound', ...
                'viconData.markers has no field ''%s''.', baseNames{i});
        end
        B(:, i, :) = viconData.markers.(baseNames{i});
    end

    b1 = squeeze(B(:,1,:)); b2 = squeeze(B(:,2,:));
    b3 = squeeze(B(:,3,:)); b4 = squeeze(B(:,4,:));

    valid = all(~isnan([b1 b2 b3 b4]), 2);

    % --- estimate a single, stable rotation axis from all valid frames ---
    normals = cross(b3 - b1, b4 - b2, 2);
    axisVec = mean(normals(valid, :), 1, 'omitnan');
    axisVec = axisVec / norm(axisVec);

    tmp = [1 0 0];
    if abs(dot(tmp, axisVec)) > 0.9
        tmp = [0 1 0];
    end
    u = tmp - dot(tmp, axisVec) * axisVec;
    u = u / norm(u);
    v = cross(axisVec, u);

    % --- project base1 relative to the cluster centroid onto (u,v) ---
    centroid = (b1 + b2 + b3 + b4) / 4;
    refVec = b1 - centroid;
    pu = refVec * u';
    pv = refVec * v';
    angleRad = atan2(pv, pu);

    % --- unwrap separately within each contiguous valid run ---
    angleDeg = nan(N, 1);
    d = diff([0; valid; 0]);
    starts = find(d == 1);
    ends   = find(d == -1) - 1;
    for k = 1:numel(starts)
        idx = starts(k):ends(k);
        angleDeg(idx) = rad2deg(unwrap(angleRad(idx)));
    end

end
