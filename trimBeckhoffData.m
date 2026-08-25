function beckhoffOut = trimBeckhoffData(beckhoffData, idx)
%TRIMBECKHOFFDATA Slice every time-series field of a loadBeckhoffMat.m /
%downsampleBeckhoff.m struct down to the given sample indices, and
%re-zero .t to start at the first kept sample.
%
%   beckhoffOut = trimBeckhoffData(beckhoffData, idx)
%
% INPUT
%   beckhoffData - struct from loadBeckhoffMat.m or downsampleBeckhoff.m
%   idx          - index vector (or range) into the ORIGINAL
%                  beckhoffData.t, e.g. 5001:numel(beckhoffData.t)
%
% OUTPUT  beckhoffOut - same struct shape, restricted to idx:
%   .t            - re-zeroed: t(idx) - t(idx(1))
%   .<name>       - every channel whose first dimension matched the
%                   original .t length, sliced the same way
%   .sampleRate, .channelNames - unchanged

    N = numel(beckhoffData.t);
    skipFields = {'t', 'sampleRate', 'channelNames'};
    fns = fieldnames(beckhoffData);

    beckhoffOut = struct();
    for k = 1:numel(fns)
        name = fns{k};
        if any(strcmp(name, skipFields))
            continue
        end
        val = beckhoffData.(name);
        if isnumeric(val) && size(val, 1) == N
            beckhoffOut.(name) = val(idx, :);
        else
            beckhoffOut.(name) = val;
        end
    end

    tSub = beckhoffData.t(idx);
    beckhoffOut.t            = tSub - tSub(1);
    beckhoffOut.sampleRate   = beckhoffData.sampleRate;
    beckhoffOut.channelNames = beckhoffData.channelNames;

end
