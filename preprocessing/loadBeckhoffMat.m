function beckhoff = loadBeckhoffMat(filepath)
%LOADBECKHOFFMAT Load a Beckhoff/TwinCat .mat log into a struct, exposing
%every channel found in the file (rather than hardcoding a fixed list),
%so new/renamed channels show up automatically.
%
%   beckhoff = loadBeckhoffMat(filepath)
%
% Expects the file to contain a time vector 't' (seconds) plus any number
% of other variables -- typically things like 'torsion', 'bend', 'dtz'
% (driven-end output torque), 'mfx'/'mfy'/'mfz', 'mtx'/'mty'/'mtz'
% (motor-side force/torque), 'dfx'/'dfy'/'dfz' (driven-side force), and
% combined arrays like 'data'/'d'.
%
% OUTPUT  beckhoff (struct):
%   .t            [N x 1] time, seconds
%   .sampleRate   scalar, Hz (= 1 / median(diff(t)))
%   .channelNames {1 x K} cell array listing every field found
%   .<name>       every other variable in the file, as found, with:
%                   - 1D vectors forced to column orientation
%                   - 2D arrays whose size matches N along one dimension
%                     but not the other transposed so that samples run
%                     along dimension 1 (matching .t)
%                   - anything else (e.g. scalars) left untouched
%
% NOTE: this loader does not know which channel is "the" torque or
% torsion signal for your rig -- check beckhoff.channelNames and confirm
% against your test-rig wiring/log documentation before assuming a name
% means what you expect (e.g. confirm sign conventions on torque/torsion
% channels independently, as these have differed between channels in
% past trials).

    raw = load(filepath);

    if ~isfield(raw, 't')
        error('loadBeckhoffMat:missingTime', ...
            'File does not contain a ''t'' (time) variable. Available variables: %s', ...
            strjoin(fieldnames(raw), ', '));
    end

    N = numel(raw.t);
    fns = fieldnames(raw);

    beckhoff = struct();
    for k = 1:numel(fns)
        name = fns{k};
        val = double(raw.(name));

        if isvector(val) && numel(val) == N
            val = val(:);                        % force column orientation
        elseif ismatrix(val) && any(size(val) == N) && size(val,1) ~= N
            val = val.';                          % put samples along dim 1
        end

        beckhoff.(name) = val;
    end

    beckhoff.sampleRate   = 1 / median(diff(beckhoff.t));
    beckhoff.channelNames = fns;

end
