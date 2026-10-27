function w = coil_rodrigues(v, ax, ang)
%COIL_RODRIGUES  Rotate row vector v about unit axis ax by angle ang [rad].
w = v*cos(ang) + cross(ax, v)*sin(ang) + ax*(ax*v')*(1 - cos(ang));
end
