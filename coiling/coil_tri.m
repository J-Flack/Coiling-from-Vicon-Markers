function A = coil_tri(a, b, c)
%COIL_TRI  Signed area of the spherical triangle (a,b,c) on the unit sphere.
%
%   A = 2*atan2( a.(b x c), 1 + a.b + b.c + c.a )   (Van Oosterom & Strackee 1983)
%   Inputs are arrays whose 3rd dimension holds xyz (e.g. [F x n x 3]);
%   singleton dimensions broadcast.

bx = b(:,:,1); by = b(:,:,2); bz = b(:,:,3);
cx = c(:,:,1); cy = c(:,:,2); cz = c(:,:,3);
ax = a(:,:,1); ay = a(:,:,2); az = a(:,:,3);
num = ax.*(by.*cz - bz.*cy) + ay.*(bz.*cx - bx.*cz) + az.*(bx.*cy - by.*cx);
den = 1 + (ax.*bx + ay.*by + az.*bz) + (bx.*cx + by.*cy + bz.*cz) + (cx.*ax + cy.*ay + cz.*az);
A = 2 * atan2(num, den);
end
