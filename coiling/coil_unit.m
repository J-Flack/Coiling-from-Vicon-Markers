function v = coil_unit(v)
%COIL_UNIT  Normalise vectors along the last (size-3) dimension.
d = ndims(v);
if d == 2 && size(v, 2) ~= 3 && size(v, 1) == 3
    v = v / norm(v); return
end
v = v ./ sqrt(sum(v.^2, d));
end
