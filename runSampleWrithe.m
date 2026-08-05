%% runSampleWrithe.m
% Script to calculate writhe metrics for sample.mat using calculateSampleWrithe.m.
%
% Keep this file in the same folder as:
%   sample.mat
%   calculateSampleWrithe.m

clear; clc;

sampleFile = 'sample.mat';
%%
% Default choice: one representative frame per sample, the midpoint of the
% hold region. This avoids accidentally running the expensive O(N^2) methods
% over every time frame.
results = calculateSampleWrithe(sampleFile, ...
    'SampleIndex', 1:10, ...
    'Frames', 'holdMid', ...
    'Methods', {'direct','acn','fuller','starostin','polar'}, ...
    'MaxPoints', 200, ...
    'KExcl', 1);

disp(results);

writetable(results, 'sample_writhe_results.csv');
save('sample_writhe_results.mat', 'results');

% Simple comparison plot for the main signed writhe outputs.
figure('Name','Sample writhe comparison');
plot(results.sampleIndex, results.Wr_direct, 'o-', 'DisplayName','Direct Gauss'); hold on;
plot(results.sampleIndex, results.Wr_acn, 's-', 'DisplayName','ACN signed');
plot(results.sampleIndex, results.Wr_fuller, '^-', 'DisplayName','Fuller');
plot(results.sampleIndex, results.Wr_starostin, 'd-', 'DisplayName','Starostin');
plot(results.sampleIndex, results.Wp_polar, 'x-', 'DisplayName','Polar');
xlabel('Sample index');
ylabel('Writhe');
grid on;
legend('Location','best');

%% Optional examples
% Run only one sample and one explicit frame:
% oneResult = calculateSampleWrithe(sampleFile, 'SampleIndex', 1, 'Frames', 1000);
%
% Run a short frame range for sample 1:
% rangeResult = calculateSampleWrithe(sampleFile, 'SampleIndex', 1, 'Frames', 1000:10:1200);
%
% Run only the faster tangent-sphere methods:
% fastResult = calculateSampleWrithe(sampleFile, 'Methods', {'fuller','starostin','polar'});
%
% Run every frame only if you are sure you want this computation:
% allFrameResult = calculateSampleWrithe(sampleFile, 'SampleIndex', 1, 'Frames', 'all', 'Methods', {'fuller','starostin','polar'});
