function results = alignViconBeckhoff(viconData, beckhoffDataAtViconRate, calibWindowSec)
%ALIGNVICONBECKHOFF Estimate the temporal offset between a VICON marker
%trajectory and a Beckhoff/TwinCat torsion log, using the initial
%zero-bend torsion sweep as a calibration segment.
%
%   results = alignViconBeckhoff(viconData, beckhoffDataAtViconRate, calibWindowSec)
%
% IMPORTANT -- CALL ORDER: this function expects beckhoffDataAtViconRate
% to ALREADY be at the same sample rate as viconData. Downsampling is
% downsampleBeckhoff.m's job, done once for the whole recording -- it is
% NOT repeated here. The usual call sequence is:
%
%   vicon        = loadViconCSV(viconFile);
%   beckhoff     = loadBeckhoffMat(beckhoffFile);
%   beckhoffDown = downsampleBeckhoff(beckhoff, vicon);     % <-- once, here
%   lagInfo      = alignViconBeckhoff(vicon, beckhoffDown); % <-- not here
%
% INPUTS
%   viconData               - struct from loadViconCSV.m. Must contain
%                             markers base1, base2, base3, base4
%   beckhoffDataAtViconRate - struct from downsampleBeckhoff.m (i.e.
%                             loadBeckhoffMat.m's output AFTER being
%                             downsampled to viconData.sampleRate). Must
%                             contain .t (seconds) and .torsion (degrees)
%   calibWindowSec          - duration (s) of the initial alignment
%                             segment to use for cross-correlation
%                             (default: 30). Should be long enough to
%                             fully contain the zero-bend torsion sweep
%                             in BOTH recordings even though their
%                             absolute start times differ by the
%                             (unknown) offset being estimated.
%
% OUTPUT  results (struct):
%   .viconAngle         - [Tv x 1] unwrapped base-square rotation angle
%                          (deg) over the FULL vicon record
%   .viconCalib         - demeaned vicon angle, calibration window only
%   .torsionCalib       - demeaned torsion, calibration window only (now
%                          already at the Vicon rate, just sliced)
%   .lagSamples         - estimated lag D, in (shared) sample units, from
%                          finddelay(torsionCalib, viconCalib). Meaning:
%                          viconCalib(n) corresponds to torsionCalib(n-D).
%                          If D > 0, the VICON recording has D extra
%                          samples of "lead-in" before the calibration
%                          motion relative to the Beckhoff recording
%                          (trim D samples off the start of the VICON
%                          stream to align it). If D < 0, trim |D|
%                          samples off the start of the Beckhoff stream
%                          instead.
%   .signFlipped        - true if viconAngle had to be sign-flipped to
%                          match the torsion sign convention (rotation
%                          direction definitions differed between the
%                          two systems)
%   .fsShared           - the shared sample rate used (Hz)
%
% IMPORTANT: verify the sign of lagSamples against a diagnostic plot for
% your data before trusting it blindly (plot viconCalib and torsionCalib
% shifted by lagSamples and check they overlap) -- see
% run_full_pipeline_example.m for exactly this check on real data.

    if nargin < 3 || isempty(calibWindowSec)
        calibWindowSec = 30;
    end

    fsVicon = viconData.sampleRate;
    fsBeckhoff = beckhoffDataAtViconRate.sampleRate;
    if abs(fsVicon - fsBeckhoff) > 1e-3 * fsVicon
        error('alignViconBeckhoff:rateMismatch', ...
            ['beckhoffDataAtViconRate.sampleRate (%.4f Hz) does not match ' ...
             'viconData.sampleRate (%.4f Hz). Call downsampleBeckhoff(beckhoff, vicon) ' ...
             'BEFORE alignViconBeckhoff -- see this function''s help.'], ...
            fsBeckhoff, fsVicon);
    end
    fsShared = fsVicon;

    %% --- 1. Compute VICON base-marker rotation angle (full record) ---
    viconAngle = baseSquareRotationAngle(viconData);   % [Tv x 1], deg

    %% --- 2. Slice both (already same-rate) signals to the calibration window ---
    nCalib = min([numel(viconAngle), numel(beckhoffDataAtViconRate.torsion), ...
                  round(calibWindowSec * fsShared)]);

    viconCalib   = viconAngle(1:nCalib) - mean(viconAngle(1:nCalib));
    torsionCalib = beckhoffDataAtViconRate.torsion(1:nCalib) - mean(beckhoffDataAtViconRate.torsion(1:nCalib));

    %% --- 3. Resolve sign convention, then estimate delay ---
    signFlipped = false;
    cc = corrcoef(viconCalib, torsionCalib);
    if cc(1,2) < 0
        viconCalib  = -viconCalib;
        signFlipped = true;
    end

    lagSamples = finddelay(torsionCalib, viconCalib);

    %% --- Package results ---
    results.viconAngle   = viconAngle;
    results.viconCalib   = viconCalib;
    results.torsionCalib = torsionCalib;
    results.lagSamples   = lagSamples;
    results.signFlipped  = signFlipped;
    results.fsShared     = fsShared;

end
