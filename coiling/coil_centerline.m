function CL = coil_centerline(X, Sm)
%COIL_CENTERLINE  Smoothed shaft centreline for every frame.
%
%   CL = coil_centerline(X, Sm)
%     X  : [nMarkers x F x 3] markers ordered along the shaft (coil_markers)
%     Sm : [nPts x nMarkers-2] smoother from coil_smoother
%     CL : [F x nPts x 3] centreline (mm)
%
%   Sliding triplets of consecutive markers are averaged, which cancels
%   the ~120 deg spiral mounting offset, and the triplet centres are
%   smoothed with the cubic smoothing spline on s in [0,1]. Frames with a
%   missing marker come out as NaN.

trip = (X(1:end-2, :, :) + X(2:end-1, :, :) + X(3:end, :, :)) / 3;   % nT x F x 3
[nT, F, ~] = size(trip);
CL = reshape(Sm * reshape(trip, nT, F*3), [], F, 3);                  % nPts x F x 3
CL = permute(CL, [2 1 3]);
end
