%RUNSAMPLEACNWRITHEALL Calculate ACN-style writhe for every frame in sample.mat.
%
% Put this file, calculateSampleACNWritheAll.m, and sample.mat in the same
% folder, then run this script.

clear; clc;
%%
sampleFile = 'sample.mat';
%%
outPrefix = 'sample_acn_writhe_all';
%%
% Full calculation: all 10 samples and all local centerline frames.
% This may take a while because the method is O(nFrames*nSegments^2).
results = calculateSampleACNWritheAll(sampleFile, ...
    'SampleIndex', [], ...      % [] = all samples
    'Frames', 'all', ...        % all local frames, e.g. 1:3987
    'FrameStride', 1, ...       % 1 = every frame; use 10 for a faster test
    'MaxPoints', Inf, ...       % use all 200 centerline points
    'KExcl', 1, ...             % skip adjacent segment pairs
    'SaveEverySample', true, ...
    'OutPrefix', outPrefix);
%%
save([outPrefix '.mat'], 'results');
writetable(results, [outPrefix '.csv']);

fprintf('\nSaved:\n  %s.mat\n  %s.csv\n', outPrefix, outPrefix);

% Simple overview plots.
figure;
gscatter(results.frame, results.Wr_acn, results.sampleIndex);
xlabel('Local frame');
ylabel('Signed ACN/Gauss writhe');
title('ACN-style signed writhe over all sample frames');
grid on;

figure;
gscatter(results.frame, results.ACN, results.sampleIndex);
xlabel('Local frame');
ylabel('ACN');
title('Average crossing number over all sample frames');
grid on;
