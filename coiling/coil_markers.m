function X = coil_markers(seg)
%COIL_MARKERS  Shaft marker positions of one segment, ordered along the shaft.
%
%   X = coil_markers(seg) returns [nMarkers x nFrames x 3] (mm). Markers
%   whose names start with 'base' are excluded; the rest are sorted by the
%   numeric ID in their name (as in computeShaftCenterline.m).

names = fieldnames(seg.markers);
keep  = ~strncmpi(names, 'base', 4);
names = names(keep);
id = zeros(numel(names), 1);
for k = 1:numel(names)
    id(k) = str2double(regexp(names{k}, '\d+', 'match', 'once'));
end
names = names(~isnan(id));
[~, o] = sort(id(~isnan(id)));
names = names(o);

F = size(seg.markers.(names{1}), 1);
X = zeros(numel(names), F, 3);
for k = 1:numel(names)
    X(k, :, :) = reshape(double(seg.markers.(names{k})), 1, F, 3);
end
end
