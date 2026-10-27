function H = coil_hermite(P0, T0, P1, T1, n)
%COIL_HERMITE  Cubic Hermite curves, one per row.
%   P0,T0,P1,T1 : [F x 3] end points and end tangents (tangents already scaled)
%   H           : [F x n x 3]
u   = linspace(0, 1, n);
h00 = 2*u.^3 - 3*u.^2 + 1;
h10 = u.^3 - 2*u.^2 + u;
h01 = -2*u.^3 + 3*u.^2;
h11 = u.^3 - u.^2;
F = size(P0, 1);
H = zeros(F, n, 3);
for d = 1:3
    H(:, :, d) = P0(:, d).*h00 + T0(:, d).*h10 + P1(:, d).*h01 + T1(:, d).*h11;
end
end
