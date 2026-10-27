function beckhoffDown = downsampleBeckhoff(beckhoffData, targetFs)
%DOWNSAMPLEBECKHOFF Resample every channel in a loadBeckhoffMat struct
%down to a target sample rate (e.g. to match the VICON frame rate), using
%linear interpolation against the original time vector.
%
%   beckhoffDown = downsampleBeckhoff(beckhoffData, targetFs)
%   beckhoffDown = downsampleBeckhoff(beckhoffData, viconData)
%
% INPUTS
%   beckhoffData - struct from loadBeckhoffMat.m
%   targetFs     - EITHER the desired output sample rate in Hz (scalar),
%                  OR a struct that has a .sampleRate field (e.g. pass
%                  the struct from loadViconCSV.m directly, and its
%                  sampleRate will be used)
%
% OUTPUT  beckhoffDown (struct), same fields as beckhoffData, where:
%   .t            - new [Nd x 1] time vector, seconds, running from
%                   beckhoffData.t(1) to beckhoffData.t(end) at targetFs
%   .sampleRate   - targetFs
%   .channelNames - unchanged
%   .<name>       - every time-series channel (any field whose first
%                   dimension matches the length of the original .t) is
%                   resampled via interp1 onto the new time vector. 2D
%                   channels (e.g. a combined multi-column "data"/"d"
%                   array) are resampled all at once, column-by-column.
%                   Non-time-series fields (e.g. a scalar) are copied
%                   through unchanged.
%
% NOTE: this only matches SAMPLE RATE, not the temporal offset between
% the VICON and Beckhoff recordings. Use alignViconBeckhoff.m (and the
% lag it returns) to actually line the two streams up in time once they
% share a common rate.
%
% EXAMPLE
%   beckhoff     = loadBeckhoffMat('5mm_B_Initial.mat');
%   vicon        = loadViconCSV('5mm04.csv');
%   beckhoffDown = downsampleBeckhoff(beckhoff, vicon);   % or vicon.sampleRate
%   plot(beckhoffDown.t, beckhoffDown.torsion);

    if isstruct(targetFs)
        targetFs = targetFs.sampleRate;
    end

    N    = numel(beckhoffData.t);
    tIn  = beckhoffData.t;
    tOut = (tIn(1) : 1/targetFs : tIn(end))';

    skipFields = {'t', 'sampleRate', 'channelNames'};
    fns = fieldnames(beckhoffData);

    beckhoffDown = struct();
    for k = 1:numel(fns)
        name = fns{k};
        if any(strcmp(name, skipFields))
            continue
        end

        val = beckhoffData.(name);
        if isnumeric(val) && size(val, 1) == N
            beckhoffDown.(name) = interp1(tIn, val, tOut, 'linear', 'extrap');
        else
            beckhoffDown.(name) = val;   % not a time series at this rate -- pass through unchanged
        end
    end

    beckhoffDown.t            = tOut;
    beckhoffDown.sampleRate   = targetFs;
    beckhoffDown.channelNames = beckhoffData.channelNames;

end
