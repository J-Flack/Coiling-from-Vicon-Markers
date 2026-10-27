function [al, be] = coil_connMags(P0, t0, P1, t1)
%COIL_CONNMAGS  End-tangent magnitudes of the completing Hermite curves.
%
%   [al, be] = coil_connMags(P0, t0, P1, t1)
%     P0, t0 : [F x 3] start point and unit start tangent
%     P1, t1 : [F x 3] end point and unit end tangent
%     al, be : [F x 1] magnitudes of the start and end tangents
%
%   The magnitudes minimise the integrated squared second derivative of the
%   cubic, int |H''|^2, an approximation of its bending energy
%   (Yong & Cheng 2004). A lower bound of 5% of the chord keeps the curve
%   regular when the solution is close to zero.

D  = P1 - P0; L = sqrt(sum(D.^2, 2));
c  = sum(t0 .* t1, 2);
r1 = 12 * sum(D .* t0, 2); r2 = 12 * sum(D .* t1, 2);
dt = 64 - 16 * c.^2;
al = max((8*r1 - 4*c.*r2) ./ dt, 0.05 * L);
be = max((8*r2 - 4*c.*r1) ./ dt, 0.05 * L);
end
