function viconOut = trimViconData(viconData, idx)
%TRIMVICONDATA Slice every time-series field of a loadViconCSV.m struct
%down to the given sample indices, and re-zero .time to start at the
%first kept sample.
%
%   viconOut = trimViconData(viconData, idx)
%
% INPUT
%   viconData - struct from loadViconCSV.m
%   idx       - index vector (or range) into the ORIGINAL viconData.time
%               / .frame / .markers.*, e.g. 501:numel(viconData.time)
%
% OUTPUT  viconOut - same struct shape, restricted to idx:
%   .frame            - original frame numbers (just the subset, NOT renumbered)
%   .time             - re-zeroed: (frame - frame(1)) / sampleRate, so the
%                       new first kept sample is t = 0 regardless of
%                       where idx started within the original record
%   .markers.<name>   - sliced the same way, for every name in .names
%   .sampleRate, .names - unchanged

    viconOut = viconData;
    viconOut.frame = viconData.frame(idx);
    viconOut.time  = (viconOut.frame - viconOut.frame(1)) / viconData.sampleRate;

    viconOut.markers = struct();
    for k = 1:numel(viconData.names)
        name = viconData.names{k};
        viconOut.markers.(name) = viconData.markers.(name)(idx, :);
    end

end
