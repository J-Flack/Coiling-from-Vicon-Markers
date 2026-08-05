function results = calculateSampleACNWritheAll(sampleInput, varargin)
%CALCULATESAMPLEACNWRITHEALL Compute signed ACN/Gauss writhe and ACN for sample.mat.
%
% results = calculateSampleACNWritheAll('sample.mat')
% results = calculateSampleACNWritheAll(sample)
% results = calculateSampleACNWritheAll(...,'SampleIndex',1:10,'Frames','all')
%
% This is focused on the writheacn-style method only:
%   Wr_acn = signed discrete Gauss writhe using segment-pair solid angles
%   ACN    = unsigned average crossing number
%
% Expected sample format:
%   sample(i).centerline is [nPoints x 3 x nFrames]
%
% Name-value options:
%   'SampleIndex'     default all samples
%   'Frames'          'all' default, 'middle', 'first', 'last', or numeric local frame indices
%   'FrameStride'     default 1. Use e.g. 10 for every tenth frame.
%   'MaxPoints'       default Inf. Optionally downsample points for speed.
%   'KExcl'           default 1. Segment-pair neighbour exclusion.
%   'SaveEverySample' default true. Saves partial MAT after each sample.
%   'OutPrefix'       default 'sample_acn_writhe_all'
%
% Output table columns:
%   sampleIndex, frame, time, bendAngleDeg, repeatIdx, freqHz, nPointsUsed,
%   Wr_acn, ACN, nSegments, k_excl
%
% Notes:
%   This is O(nFrames*nSegments^2). For 10 samples x 3987 frames x 199
%   segments, expect it to take a while in MATLAB. Partial results are saved
%   after each sample when SaveEverySample is true.

p = inputParser;
addParameter(p, 'SampleIndex', []);
addParameter(p, 'Frames', 'all');
addParameter(p, 'FrameStride', 1);
addParameter(p, 'MaxPoints', Inf);
addParameter(p, 'KExcl', 1);
addParameter(p, 'SaveEverySample', true);
addParameter(p, 'OutPrefix', 'sample_acn_writhe_all');
parse(p, varargin{:});
opt = p.Results;

if ischar(sampleInput) || isstring(sampleInput)
    loaded = load(sampleInput, 'sample');
    if ~isfield(loaded, 'sample')
        error('MAT file must contain variable named sample.');
    end
    sample = loaded.sample;
else
    sample = sampleInput;
end

nSamples = numel(sample);
if isempty(opt.SampleIndex)
    sampleIdx = 1:nSamples;
else
    sampleIdx = opt.SampleIndex(:)';
end

allRows = cell(numel(sampleIdx),1);

for ss = 1:numel(sampleIdx)
    si = sampleIdx(ss);
    C = sample(si).centerline;
    if ndims(C) ~= 3 || size(C,2) ~= 3
        error('sample(%d).centerline must be [nPoints x 3 x nFrames].', si);
    end

    nFrames = size(C,3);
    frames = resolveLocalFrames(nFrames, opt.Frames);
    frames = frames(1:opt.FrameStride:end);

    nRows = numel(frames);
    sampleIndex = zeros(nRows,1);
    frame       = zeros(nRows,1);
    time        = nan(nRows,1);
    bendAngleDeg = nan(nRows,1);
    repeatIdx   = nan(nRows,1);
    freqHz      = nan(nRows,1);
    nPointsUsed = zeros(nRows,1);
    Wr_acn      = nan(nRows,1);
    ACN         = nan(nRows,1);
    nSegments   = zeros(nRows,1);
    k_excl      = opt.KExcl * ones(nRows,1);

    fprintf('Sample %d/%d: sample(%d), %d frames\n', ss, numel(sampleIdx), si, nRows);

    for kk = 1:nRows
        f = frames(kk);
        P = squeeze(C(:,:,f));
        P = cleanCurve(P, opt.MaxPoints);
        out = localWritheACN(P, opt.KExcl);

        sampleIndex(kk) = si;
        frame(kk) = f;
        if isfield(sample(si),'time') && numel(sample(si).time) >= f
            time(kk) = sample(si).time(f);
        end
        bendAngleDeg(kk) = getNumericField(sample(si), 'bendAngleDeg');
        repeatIdx(kk) = getNumericField(sample(si), 'repeatIdx');
        freqHz(kk) = getNumericField(sample(si), 'freqHz');
        nPointsUsed(kk) = size(P,1);
        Wr_acn(kk) = out.writhe;
        ACN(kk) = out.acn;
        nSegments(kk) = out.M;

        if mod(kk,100) == 0 || kk == nRows
            fprintf('  frame %d/%d complete\n', kk, nRows);
        end
    end

    T = table(sampleIndex, frame, time, bendAngleDeg, repeatIdx, freqHz, ...
        nPointsUsed, Wr_acn, ACN, nSegments, k_excl);
    allRows{ss} = T;

    if opt.SaveEverySample
        partialName = sprintf('%s_partial_sample_%02d.mat', opt.OutPrefix, si);
        results_partial = T; %#ok<NASGU>
        save(partialName, 'results_partial');
        fprintf('  saved %s\n', partialName);
    end
end

results = vertcat(allRows{:});
end

function frames = resolveLocalFrames(nFrames, framesOpt)
if isnumeric(framesOpt)
    frames = framesOpt;
elseif ischar(framesOpt) || isstring(framesOpt)
    switch lower(char(framesOpt))
        case 'all'
            frames = 1:nFrames;
        case {'middle','mid'}
            frames = round(nFrames/2);
        case 'first'
            frames = 1;
        case 'last'
            frames = nFrames;
        otherwise
            error('Unknown Frames option. Use all, middle, first, last, or numeric local indices.');
    end
else
    error('Frames must be string or numeric.');
end
frames = unique(round(frames(:)'));
frames = frames(frames >= 1 & frames <= nFrames);
if isempty(frames)
    error('No valid local frames selected. Valid range is 1:%d.', nFrames);
end
end

function x = getNumericField(s, name)
x = NaN;
if isfield(s,name)
    val = s.(name);
    if isnumeric(val) && isscalar(val)
        x = double(val);
    end
end
end

function P = cleanCurve(P, maxPoints)
P = double(P);
P = P(all(isfinite(P),2),:);
if size(P,1) < 3
    error('Curve has fewer than 3 valid points.');
end
keep = [true; vecnorm(diff(P,1,1),2,2) > eps];
P = P(keep,:);
if isfinite(maxPoints) && size(P,1) > maxPoints
    idx = unique(round(linspace(1,size(P,1),maxPoints)));
    P = P(idx,:);
end
end

function out = localWritheACN(r, k_excl)
if nargin < 2 || isempty(k_excl), k_excl = 1; end
r = double(r);
N = size(r,1);
if N < 3, error('Need at least 3 points.'); end
M = N - 1;
writhe_sum = 0.0;
acn_sum = 0.0;
for i = 1:M
    p1 = r(i,:);
    p2 = r(i+1,:);
    for j = i+1:M
        if abs(i-j) <= k_excl
            continue
        end
        q1 = r(j,:);
        q2 = r(j+1,:);
        Omega = solidAngleTwoSegments(p1,p2,q1,q2);
        writhe_sum = writhe_sum + 2.0*Omega;
        acn_sum = acn_sum + 2.0*abs(Omega);
    end
end
out.writhe = writhe_sum/(4*pi);
out.acn = acn_sum/(4*pi);
out.M = M;
out.params.k_excl = k_excl;
end

function Omega = solidAngleTwoSegments(p1,p2,q1,q2)
r13 = q1 - p1;
r14 = q2 - p1;
r24 = q2 - p2;
r23 = q1 - p2;
r34 = q2 - q1;
r12 = p2 - p1;

n1 = safeNormalize(cross(r13,r14));
n2 = safeNormalize(cross(r14,r24));
n3 = safeNormalize(cross(r24,r23));
n4 = safeNormalize(cross(r23,r13));

Omega_star = asin(clamp(dot(n1,n2),-1,1)) + ...
             asin(clamp(dot(n2,n3),-1,1)) + ...
             asin(clamp(dot(n3,n4),-1,1)) + ...
             asin(clamp(dot(n4,n1),-1,1));
sgn = sign(dot(cross(r34,r12),r13));
if sgn == 0
    Omega = 0.0;
else
    Omega = Omega_star*sgn;
end
end

function v = safeNormalize(v)
n = norm(v);
if n < eps
    v = [0 0 0];
else
    v = v ./ n;
end
end

function y = clamp(x,a,b)
y = min(max(x,a),b);
end
