function result = writheACN(curve, varargin)
%WRITHEACN Writhe (signed) and ACN (unsigned Average Crossing Number) of
%an open curve via the direct Gauss double integral, discretized over
%line segments (Levitt 1983; Klenin & Langowski 2000), with a
%configurable neighbor-exclusion window.
%
%   result = writheACN(curve)
%   result = writheACN(curve, 'NeighborExclusion', k)
%
% This is a cleaned-up extraction of the function body of writhe_acn()
% as supplied in writheacn.m -- only the function itself, with the
% broken script tail removed. That tail (load('40Deg_p.mat'); F=9281;
% r = squeeze(splineCenterlines(:,:,F)); ...) referenced a file that is
% not part of this delivery and would error if the .m file were run as
% a script rather than called as a function, so it is omitted here.
% Computation is otherwise byte-for-byte the same as the original.
%
% RELATIONSHIP TO writheDirectGauss.m: this is a SEPARATE, independent
% implementation of essentially the same no-closure direct-Gauss-sum
% idea, but:
%   - uses the segment-pair tetrahedron-face solid-angle formula (4
%     arcsin terms from face normals) rather than the fan-triangulated
%     spherical-quadrilateral / Van Oosterom-Strackee form used in
%     writheDirectGauss.m -- a genuinely different (though related)
%     closed-form solid-angle expression. The two should agree to
%     numerical precision away from near-degenerate segment pairs, and
%     comparing them is itself a useful cross-check.
%   - excludes pairs within 'NeighborExclusion' (k_excl) of each other
%     by INDEX (|i-j| <= k_excl skipped), rather than writheDirectGauss's
%     fixed adjacent-only exclusion -- so widening k_excl trades a bigger
%     "blind spot" around the diagonal for more numerical safety margin
%     near-singularity for closely-spaced points.
%   - also returns the unsigned Average Crossing Number (ACN), a useful
%     companion diagnostic: ACN >= |Wr| always, and a large ACN with
%     small |Wr| indicates a lot of "geometric crossing" whose signed
%     contributions are cancelling out (e.g. an S-shaped or wobbly
%     curve), which the Wr alone is blind to.
%
% INPUT
%   curve - [N x 3] points along the discretized centerline (mm), in
%           order from one end of the shaft to the other
%   'NeighborExclusion' - (optional) integer k_excl >= 0. Pairs of
%           segments with |i-j| <= k_excl are skipped to avoid the
%           near-singularity of nearly-coincident adjacent segments.
%           Default: 1 (skip only directly-adjacent pairs).
%
% OUTPUT  result (struct):
%   .Wr      - signed writhe (dimensionless) [renamed from the
%              original's .writhe for consistency with the other
%              writhe*.m functions in this library]
%   .acn     - unsigned Average Crossing Number (dimensionless)
%   .M       - number of segments (N-1)
%   .k_excl  - neighbor exclusion actually used
%
% EXAMPLE
%   r = writheACN(frame);
%   fprintf('Wr=%.4f  ACN=%.4f\n', r.Wr, r.acn);

    p = inputParser;
    addParameter(p, 'NeighborExclusion', 1);
    parse(p, varargin{:});
    k_excl = p.Results.NeighborExclusion;

    validateattributes(curve, {'double','single'}, {'2d','ncols',3});
    r = double(curve);
    N = size(r,1);
    if N < 3, error('writheACN:tooFewPoints', 'Need at least 3 points (2 segments).'); end

    M = N - 1;  % number of segments
    writhe_sum = 0.0;
    acn_sum    = 0.0;

    % Loop over unordered segment pairs (i < j); accumulate both (i,j)
    % and (j,i) at once via the factor of 2.
    for i = 1:M
        p1 = r(i,   :);
        p2 = r(i+1, :);
        for j = i+1:M
            if abs(i - j) <= k_excl
                continue; % skip adjacent/nearby segments to avoid near-singularity
            end
            q1 = r(j,   :);
            q2 = r(j+1, :);

            Omega = solid_angle_two_segments(p1,p2,q1,q2); % signed solid angle (radians)

            writhe_sum = writhe_sum + 2.0 * Omega;
            acn_sum    = acn_sum    + 2.0 * abs(Omega);
        end
    end

    % Divide by 4*pi to match the Gauss-integral normalization
    result.Wr     = writhe_sum / (4.0*pi);
    result.acn    = acn_sum    / (4.0*pi);
    result.M      = M;
    result.k_excl = k_excl;

end

% --------- Solid angle contribution for a pair of line segments (signed) ---------
function Omega = solid_angle_two_segments(p1,p2,q1,q2)
% Implementation following the Levitt / Klenin-Langowski segment-pair
% formula: endpoints labeled 1,2 on segment P (p1->p2) and 3,4 on
% segment Q (q1->q2). Forms unit normals n1..n4 of the four triangular
% faces of the tetrahedron with these four points, sums four arcsin
% terms, and applies an overall sign from the chirality of the
% configuration.

    r13 = q1 - p1;
    r14 = q2 - p1;
    r24 = q2 - p2;
    r23 = q1 - p2;
    r34 = q2 - q1;
    r12 = p2 - p1;

    n1 = safe_normalize(cross(r13, r14));
    n2 = safe_normalize(cross(r14, r24));
    n3 = safe_normalize(cross(r24, r23));
    n4 = safe_normalize(cross(r23, r13));

    d12 = clamp(dot(n1,n2), -1, 1);
    d23 = clamp(dot(n2,n3), -1, 1);
    d34 = clamp(dot(n3,n4), -1, 1);
    d41 = clamp(dot(n4,n1), -1, 1);

    Omega_star = asin(d12) + asin(d23) + asin(d34) + asin(d41);

    sgn = sign(dot(cross(r34, r12), r13));
    if sgn == 0
        Omega = 0.0;
    else
        Omega = Omega_star * sgn;
    end
end

function v = safe_normalize(v)
    n = sqrt(sum(v.^2, 2));
    n(n == 0) = eps;
    v = v ./ n;
end

function y = clamp(x, a, b)
    y = min(max(x, a), b);
end
