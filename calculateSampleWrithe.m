function results = calculateSampleWrithe(sampleInput, varargin)
%CALCULATESAMPLEWRITHE Compute open-curve writhe metrics for sample.mat data.
%
% results = calculateSampleWrithe('sample.mat')
% results = calculateSampleWrithe(sampleStruct)
% results = calculateSampleWrithe(..., 'SampleIndex', 1:10, 'Frames', 'holdMid')
% results = calculateSampleWrithe(..., 'Methods', {'direct','acn','fuller','starostin','polar'})
%
% INPUT
%   sampleInput : either the path to sample.mat, or the loaded sample struct array.
%
% NAME-VALUE OPTIONS
%   'SampleIndex'       indices of sample entries to process. Default: all.
%   'Frames'            numeric frame indices, or one of:
%                       'holdMid'  : midpoint of holdStartSample/holdEndSample, default
%                       'segMid'   : midpoint of segStartSample/segEndSample
%                       'first'    : first frame
%                       'last'     : last frame
%                       'all'      : every frame, use with care
%   'Methods'           cell array containing any of:
%                       'direct', 'acn', 'fuller', 'starostin', 'polar'
%                       Default: {'direct','acn','fuller','starostin','polar'}
%   'MaxPoints'         maximum centerline points for O(N^2) methods. Default: 200.
%                       Set Inf to disable subsampling.
%   'Axis'              optional axis for polar writhe. Default: chord direction.
%   'ReferenceDirection' optional reference direction for Fuller writhe. Default: chord direction.
%   'KExcl'             neighbour exclusion for ACN method. Default: 1.
%
% OUTPUT
%   results : table with one row per sample/frame and columns for each method.
%
% Notes
%   The centerline is assumed to be stored as [points x 3 x frames]. Writhe is
%   dimensionless, so mm versus m does not matter.

p = inputParser;
addParameter(p, 'SampleIndex', []);
addParameter(p, 'Frames', 'holdMid');
addParameter(p, 'Methods', {'direct','acn','fuller','starostin','polar'});
addParameter(p, 'MaxPoints', 200);
addParameter(p, 'Axis', []);
addParameter(p, 'ReferenceDirection', []);
addParameter(p, 'KExcl', 1);
parse(p, varargin{:});
opt = p.Results;

% --- Load or accept sample struct array ---
if ischar(sampleInput) || isstring(sampleInput)
    loaded = load(sampleInput);
    if ~isfield(loaded, 'sample')
        error('calculateSampleWrithe:noSampleVariable', ...
            'The MAT file must contain a variable named sample.');
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

methods = lower(string(opt.Methods));
validMethods = ["direct","acn","fuller","starostin","polar"];
for m = methods
    if ~any(m == validMethods)
        error('calculateSampleWrithe:badMethod', 'Unknown method: %s', m);
    end
end

rows = struct([]);
rowCount = 0;

for si = sampleIdx
    if si < 1 || si > nSamples
        error('calculateSampleWrithe:badSampleIndex', 'SampleIndex %d is out of range.', si);
    end
    C = sample(si).centerline;
    if ndims(C) ~= 3 || size(C,2) ~= 3
        error('calculateSampleWrithe:badCenterlineShape', ...
            'sample(%d).centerline must have size [points x 3 x frames].', si);
    end
    nFrames = size(C,3);
    frames = resolveFrames(sample(si), nFrames, opt.Frames);

    for f = frames(:)'
        curve = squeeze(C(:,:,f));
        curve = cleanCurve(curve, opt.MaxPoints);

        rowCount = rowCount + 1;
        rows(rowCount).sampleIndex = si; %#ok<AGROW>
        rows(rowCount).frame = f;
        rows(rowCount).bendAngleDeg = getFieldOrNaN(sample(si), 'bendAngleDeg');
        rows(rowCount).repeatIdx = getFieldOrNaN(sample(si), 'repeatIdx');
        rows(rowCount).freqHz = getFieldOrNaN(sample(si), 'freqHz');
        rows(rowCount).nPointsUsed = size(curve,1);

        rows(rowCount).Wr_direct = NaN;
        rows(rowCount).Wr_acn = NaN;
        rows(rowCount).ACN = NaN;
        rows(rowCount).Wr_fuller = NaN;
        rows(rowCount).Fuller_nonOppositionViolated = false;
        rows(rowCount).Wr_starostin = NaN;
        rows(rowCount).Starostin_endpointsAntiparallel = false;
        rows(rowCount).Wp_polar = NaN;
        rows(rowCount).Wpl_polar = NaN;
        rows(rowCount).Wpnl_polar = NaN;
        rows(rowCount).Polar_nPieces = NaN;

        if any(methods == "direct")
            r = localWritheDirectGauss(curve);
            rows(rowCount).Wr_direct = r.Wr;
        end
        if any(methods == "acn")
            r = localWritheACN(curve, opt.KExcl);
            rows(rowCount).Wr_acn = r.writhe;
            rows(rowCount).ACN = r.acn;
        end
        if any(methods == "fuller")
            r = localWritheFuller(curve, opt.ReferenceDirection);
            rows(rowCount).Wr_fuller = r.Wr;
            rows(rowCount).Fuller_nonOppositionViolated = r.nonOppositionViolated;
        end
        if any(methods == "starostin")
            r = localWritheStarostin(curve);
            rows(rowCount).Wr_starostin = r.Wr;
            rows(rowCount).Starostin_endpointsAntiparallel = r.endpointsAntiparallel;
        end
        if any(methods == "polar")
            r = localWrithePolar(curve, opt.Axis);
            rows(rowCount).Wp_polar = r.Wp;
            rows(rowCount).Wpl_polar = r.Wpl;
            rows(rowCount).Wpnl_polar = r.Wpnl;
            rows(rowCount).Polar_nPieces = r.nPieces;
        end
    end
end

if isempty(rows)
    results = table();
else
    results = struct2table(rows);
end
end

% =====================================================================
% Helper functions
% =====================================================================
function frames = resolveFrames(s, nFrames, framesOpt)
if isnumeric(framesOpt)
    frames = framesOpt;
elseif ischar(framesOpt) || isstring(framesOpt)
    switch lower(string(framesOpt))
        case "holdmid"
            if isfield(s,'holdStartSample') && isfield(s,'holdEndSample')
                frames = round(mean([s.holdStartSample, s.holdEndSample]));
            else
                frames = round(nFrames/2);
            end
        case "segmid"
            if isfield(s,'segStartSample') && isfield(s,'segEndSample')
                frames = round(mean([s.segStartSample, s.segEndSample]));
            else
                frames = round(nFrames/2);
            end
        case "first"
            frames = 1;
        case "last"
            frames = nFrames;
        case "all"
            frames = 1:nFrames;
        otherwise
            error('calculateSampleWrithe:badFramesOption', 'Unknown Frames option: %s', framesOpt);
    end
else
    error('calculateSampleWrithe:badFramesOption', 'Frames must be numeric or a recognized string.');
end
frames = unique(round(frames(:)'));
frames = frames(frames >= 1 & frames <= nFrames);
if isempty(frames)
    error('calculateSampleWrithe:noValidFrames', 'No valid frames were selected.');
end
end

function x = getFieldOrNaN(s, fieldName)
if isfield(s, fieldName)
    x = s.(fieldName);
    if ischar(x) || isstring(x) || isempty(x)
        x = NaN;
    end
else
    x = NaN;
end
end

function curve = cleanCurve(curve, maxPoints)
curve = double(curve);
ok = all(isfinite(curve),2);
curve = curve(ok,:);
if size(curve,1) < 4
    error('calculateSampleWrithe:tooFewValidPoints', 'Curve has fewer than 4 valid points.');
end
% Remove repeated consecutive points.
keep = [true; vecnorm(diff(curve,1,1),2,2) > eps];
curve = curve(keep,:);
if ~isempty(maxPoints) && isfinite(maxPoints) && size(curve,1) > maxPoints
    idx = round(linspace(1, size(curve,1), maxPoints));
    curve = curve(idx,:);
end
end

function result = localWritheDirectGauss(curve)
N = size(curve,1);
Wr = 0; nPairs = 0;
for i = 1:(N-2)
    Pi = curve(i,:); Pi1 = curve(i+1,:);
    for j = (i+2):(N-1)
        Pj = curve(j,:); Pj1 = curve(j+1,:);
        a = Pj-Pi; b = Pj1-Pi; c = Pj1-Pi1; d = Pj-Pi1;
        if min([norm(a),norm(b),norm(c),norm(d)]) < eps, continue; end
        ah = a/norm(a); bh = b/norm(b); ch = c/norm(c); dh = d/norm(d);
        omega = sphericalTriangleArea(ah,bh,ch) + sphericalTriangleArea(ah,ch,dh);
        Wr = Wr - omega/(4*pi);
        nPairs = nPairs + 1;
    end
end
result.Wr = Wr;
result.nSegmentPairs = nPairs;
end

function out = localWritheACN(r, k_excl)
N = size(r,1); M = N-1;
writhe_sum = 0; acn_sum = 0;
for i = 1:M
    p1 = r(i,:); p2 = r(i+1,:);
    for j = i+1:M
        if abs(i-j) <= k_excl, continue; end
        q1 = r(j,:); q2 = r(j+1,:);
        Omega = solidAngleTwoSegments(p1,p2,q1,q2);
        writhe_sum = writhe_sum + 2*Omega;
        acn_sum = acn_sum + 2*abs(Omega);
    end
end
out.writhe = writhe_sum/(4*pi);
out.acn = acn_sum/(4*pi);
out.M = M;
end

function result = localWritheFuller(curve, refDir)
if isempty(refDir)
    refDir = curve(end,:) - curve(1,:);
end
refDir = unitVector(refDir);
T = diff(curve,1,1); T = T ./ vecnorm(T,2,2);
oneMinusCos = 1 + T*refDir';
chi = 0;
for k = 1:(size(T,1)-1)
    chi = chi + sphericalTriangleArea(refDir,T(k,:),T(k+1,:));
end
result.Wr = chi/(2*pi);
result.nonOppositionViolated = min(oneMinusCos) < 1e-3;
end

function result = localWritheStarostin(curve)
T = diff(curve,1,1); T = T ./ vecnorm(T,2,2);
T1 = T(1,:); TM = T(end,:);
chi = 0;
for k = 2:(size(T,1)-1)
    chi = chi + sphericalTriangleArea(T1,T(k,:),T(k+1,:));
end
result.Wr = chi/(2*pi);
result.endpointsAntiparallel = (1 + dot(T1,TM)) < 1e-3;
end

function result = localWrithePolar(curve, zHat)
if isempty(zHat)
    zHat = curve(end,:) - curve(1,:);
end
zHat = unitVector(zHat);
ref = [1 0 0];
if abs(dot(ref,zHat)) > 0.9, ref = [0 1 0]; end
e1 = unitVector(ref - dot(ref,zHat)*zHat);
e2 = cross(zHat,e1);
z = curve*zHat'; x = curve*e1'; y = curve*e2';
T = diff(curve,1,1); T = T ./ vecnorm(T,2,2); M = size(T,1);
dz = diff(z); sgn = sign(dz);
if all(sgn == 0), error('calculateSampleWrithe:flatPolarAxis','Curve has zero extent along polar axis.'); end
firstNonzero = find(sgn ~= 0,1,'first');
sgn(1:firstNonzero) = sgn(firstNonzero);
for k = 2:numel(sgn)
    if sgn(k) == 0, sgn(k) = sgn(k-1); end
end
turnPts = find(diff(sgn) ~= 0) + 1;
pieceBounds = unique([1, turnPts(:)', size(curve,1)]);
nPieces = numel(pieceBounds)-1;
Wpl = 0;
pieces = struct('startPt',{},'endPt',{},'startSeg',{},'endSeg',{},'direction',{});
for ii = 1:nPieces
    pieces(ii).startPt = pieceBounds(ii);
    pieces(ii).endPt = pieceBounds(ii+1);
    pieces(ii).startSeg = pieceBounds(ii);
    pieces(ii).endSeg = pieceBounds(ii+1)-1;
    pieces(ii).direction = sign(z(pieceBounds(ii+1))-z(pieceBounds(ii)));
    if pieces(ii).direction == 0, pieces(ii).direction = sgn(min(pieces(ii).startSeg,M)); end
    anchor = pieces(ii).direction*zHat;
    for k = pieces(ii).startSeg:(pieces(ii).endSeg-1)
        Wpl = Wpl + sphericalTriangleArea(anchor,T(k,:),T(k+1,:));
    end
end
Wpl = Wpl/(2*pi);
Wpnl = 0; nZSamples = 200;
for ii = 1:nPieces
    zi = z(pieces(ii).startPt:pieces(ii).endPt); xi = x(pieces(ii).startPt:pieces(ii).endPt); yi = y(pieces(ii).startPt:pieces(ii).endPt);
    for jj = 1:nPieces
        if jj == ii, continue; end
        zj = z(pieces(jj).startPt:pieces(jj).endPt); xj = x(pieces(jj).startPt:pieces(jj).endPt); yj = y(pieces(jj).startPt:pieces(jj).endPt);
        zMin = max(min(zi),min(zj)); zMax = min(max(zi),max(zj));
        if zMax <= zMin, continue; end
        zSamples = linspace(zMin,zMax,nZSamples)';
        [zis,oi] = sort(zi); [zjs,oj] = sort(zj);
        xiAt = interp1(zis,xi(oi),zSamples,'linear'); yiAt = interp1(zis,yi(oi),zSamples,'linear');
        xjAt = interp1(zjs,xj(oj),zSamples,'linear'); yjAt = interp1(zjs,yj(oj),zSamples,'linear');
        theta = unwrap(atan2(yjAt-yiAt,xjAt-xiAt));
        sigma = sign(pieces(ii).direction*pieces(jj).direction);
        Wpnl = Wpnl + sigma*(theta(end)-theta(1))/(2*pi);
    end
end
result.Wp = Wpl + Wpnl;
result.Wpl = Wpl;
result.Wpnl = Wpnl;
result.nPieces = nPieces;
end

function area = sphericalTriangleArea(a,b,c)
a = unitVector(a); b = unitVector(b); c = unitVector(c);
triple = dot(a,cross(b,c));
den = 1 + dot(a,b) + dot(b,c) + dot(c,a);
area = 2*atan2(triple, den);
end

function Omega = solidAngleTwoSegments(p1,p2,q1,q2)
r13 = q1-p1; r14 = q2-p1; r24 = q2-p2; r23 = q1-p2; r34 = q2-q1; r12 = p2-p1;
n1 = unitVector(cross(r13,r14)); n2 = unitVector(cross(r14,r24));
n3 = unitVector(cross(r24,r23)); n4 = unitVector(cross(r23,r13));
OmegaStar = asin(clamp(dot(n1,n2),-1,1)) + asin(clamp(dot(n2,n3),-1,1)) + ...
            asin(clamp(dot(n3,n4),-1,1)) + asin(clamp(dot(n4,n1),-1,1));
sgn = sign(dot(cross(r34,r12),r13));
if sgn == 0, Omega = 0; else, Omega = OmegaStar*sgn; end
end

function v = unitVector(v)
v = v(:)';
n = norm(v);
if n < eps
    error('calculateSampleWrithe:zeroVector','Cannot normalize a zero vector.');
end
v = v/n;
end

function y = clamp(x,a,b)
y = min(max(x,a),b);
end
