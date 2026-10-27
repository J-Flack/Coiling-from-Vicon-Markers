function Om = coil_omega(P, P0)
%COIL_OMEGA  Coiling angle from the loaded and zero-torsion tangent paths.
%
%   Om = coil_omega(P, P0)
%     P  : [F x m x 3] loaded tangent paths (fixture to fixture)
%     P0 : [1 x m x 3] zero-torsion tangent path (same end points)
%     Om : [F x 1] Omega = 2*pi*DeltaWr [rad]
%
%   The area between the two paths is split into spherical triangles
%   (P0_k, P_k, P_k+1) and (P0_k, P_k+1, P0_k+1); Omega is minus the sum of
%   their signed areas. Both paths start and end on the fixture axes, so the
%   region is closed and Omega = 2*pi*(Wr - Wr0) (Fuller 1978), whichever
%   closure is used for the open curve.

a  = P0(:, 1:end-1, :);
strips = coil_tri(a, P(:, 1:end-1, :), P(:, 2:end, :)) ...
       + coil_tri(a, P(:, 2:end, :),   P0(:, 2:end, :));
Om = -sum(strips, 2);
end
