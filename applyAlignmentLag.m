function [viconAligned, beckhoffAligned] = applyAlignmentLag(viconData, beckhoffDataAtViconRate, lagSamples)
%APPLYALIGNMENTLAG Trim VICON and downsampled-Beckhoff data so they line
%up sample-for-sample, using the lag estimated by alignViconBeckhoff.m.
%
%   [viconAligned, beckhoffAligned] = applyAlignmentLag(viconData, beckhoffDataAtViconRate, lagSamples)
%
% Follows the sign convention documented in alignViconBeckhoff.m's
% .lagSamples output: if lagSamples > 0, VICON has that many extra
% lead-in samples relative to Beckhoff (trim them off VICON's start); if
% lagSamples < 0, the opposite (trim off Beckhoff's start instead). Both
% streams are then truncated to the same final length (the shorter of
% the two), so index i in viconAligned and index i in beckhoffAligned
% refer to the same instant from that point on -- in particular, sample
% indices returned by segmentBendAngleTrialsFromBeckhoff.m on
% beckhoffAligned can be used directly to slice
% viconAligned.markers.<name> for any marker.
%
% INPUTS
%   viconData               - struct from loadViconCSV.m
%   beckhoffDataAtViconRate - struct from downsampleBeckhoff.m (already
%                             at viconData.sampleRate -- this function
%                             does not check that, alignViconBeckhoff.m
%                             already enforces it upstream)
%   lagSamples              - from alignViconBeckhoff(...).lagSamples
%
% OUTPUTS  viconAligned, beckhoffAligned - same struct shapes as the
%   inputs, trimmed and re-zeroed in time so they correspond 1:1.

    if lagSamples > 0
        viconData = trimViconData(viconData, (lagSamples+1):numel(viconData.time));
    elseif lagSamples < 0
        beckhoffDataAtViconRate = trimBeckhoffData(beckhoffDataAtViconRate, ...
            (abs(lagSamples)+1):numel(beckhoffDataAtViconRate.t));
    end

    n = min(numel(viconData.time), numel(beckhoffDataAtViconRate.t));
    viconAligned    = trimViconData(viconData, 1:n);
    beckhoffAligned = trimBeckhoffData(beckhoffDataAtViconRate, 1:n);

end
