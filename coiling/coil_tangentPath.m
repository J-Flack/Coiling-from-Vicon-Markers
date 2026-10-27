function P = coil_tangentPath(t, Pf, Pl, pa, a, pb, b, nConn)
%COIL_TANGENTPATH  Tangent path of the completed centreline, fixture to fixture.
%
%   P = coil_tangentPath(t, Pf, Pl, pa, a, pb, b, nConn)
%     t      : [F x n x 3] unit tangents of the tracked centreline
%     Pf, Pl : [F x 1 x 3] first / last tracked centreline points
%     pa, a  : motor-side fixture point and axis  [1 x 3]
%     pb, b  : fixed-side fixture point and axis  [1 x 3]
%     nConn  : points per completing Hermite curve
%     P      : [F x (n + 2*(nConn-1) + 2) x 3] tangent path
%              = [a, completion at motor side, t, completion at fixed side, b]
%
%   Each completion is a cubic Hermite curve that leaves the fixture along
%   its axis and meets the tracked end at its position and tangent, with
%   tangent magnitudes from coil_connMags.

F  = size(t, 1);
Pf = reshape(Pf, F, 3); Pl = reshape(Pl, F, 3);
A  = repmat(a, F, 1);   B = repmat(b, F, 1);
tf = reshape(t(:, 1, :), F, 3); tl = reshape(t(:, end, :), F, 3);

PA = repmat(pa, F, 1);
[al, be] = coil_connMags(PA, A, Pf, tf);
c1 = coil_unit(diff(coil_hermite(PA, al.*A, Pf, be.*tf, nConn), 1, 2));

PB = repmat(pb, F, 1);
[al, be] = coil_connMags(Pl, tl, PB, B);
c2 = coil_unit(diff(coil_hermite(Pl, al.*tl, PB, be.*B, nConn), 1, 2));

P = cat(2, reshape(A, F, 1, 3), c1, t, c2, reshape(B, F, 1, 3));
end
