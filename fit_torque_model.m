function fitResult = fit_torque_model(x, y, z, metadata, varargin)
%FIT_TORQUE_MODEL Fit the custom torque model to one test's data and
%record every quantity needed for downstream statistical analysis.
%
%   fitResult = FIT_TORQUE_MODEL(x, y, z, metadata) fits
%       z = a*((x+d)*pi/180 + b*y) + c
%   to the vectors x (t_p_e), y (ACN_p_e), z (dtz_p_e) using the same
%   NonlinearLeastSquares / LAR-robust / Levenberg-Marquardt settings
%   shown in the Curve Fitting Tool, and returns a struct containing
%   coefficients, uncertainties, goodness-of-fit, residual diagnostics,
%   convergence info, and test metadata.
%
%   INPUTS
%     x, y, z   : column or row vectors of equal length (raw test data)
%     metadata  : struct with fields describing this test, e.g.
%                   metadata.Condition  = "6mm_medium"
%                   metadata.Speed      = "fast"
%                   metadata.SampleID   = "S03"
%                   metadata.TestOrder  = 7
%                   metadata.Timestamp  = datetime(...)
%                 Any fields you include are copied through to the
%                 output untouched, so you can add more (temperature,
%                 calibration date, etc.) without changing this function.
%
%   NAME-VALUE OPTIONS
%     'StartPoint' : 1x4 vector [a0 b0 c0 d0] initial guess (default [0 0 0 0])
%     'Lower'      : 1x4 vector of lower bounds (default: none, -Inf)
%     'Upper'      : 1x4 vector of upper bounds (default: none, +Inf)
%     'Robust'     : robust fitting method, default 'LAR' (set '' to disable)
%
%   OUTPUT
%     fitResult : struct with fields listed in the code below. Intended
%     to be collected across all 30 tests (via BATCH_FIT_TORQUE_MODEL)
%     into one row-per-test results table.

    p = inputParser;
    addParameter(p, 'StartPoint', [0 0 0 0]);
    addParameter(p, 'Lower', []);
    addParameter(p, 'Upper', []);
    addParameter(p, 'Robust', 'LAR');
    addParameter(p, 'PlotFit', false);
    addParameter(p, 'PlotTitle', '');
    parse(p, varargin{:});
    opts_in = p.Results;

    x = x(:); y = y(:); z = z(:);
    if ~(numel(x) == numel(y) && numel(y) == numel(z))
        error('fit_torque_model:sizeMismatch', 'x, y, and z must be the same length.');
    end

    %% Set up fit type and options (mirrors the Curve Fitting Tool settings)
    ft = fittype('a*((x+d)*pi/180+b*y)+c', 'independent', {'x', 'y'}, ...
                 'dependent', 'z');

    fo = fitoptions(ft);
    % Note: fitoptions(ft) for a custom equation already returns a
    % NonlinearLeastSquares options object -- Method is read-only here,
    % so we only set the properties that ARE configurable.
    fo.Algorithm    = 'Levenberg-Marquardt';
    fo.DiffMinChange = 1e-8;
    fo.DiffMaxChange = 0.1;
    fo.MaxFunEvals  = 1000000;
    fo.MaxIter      = 1000000;
    fo.StartPoint   = opts_in.StartPoint;
    if ~isempty(opts_in.Robust)
        fo.Robust = opts_in.Robust;
    end
    % Note: Levenberg-Marquardt in MATLAB's cftool ignores Lower/Upper
    % bounds (LM is unconstrained). Keeping this here in case you switch
    % Algorithm to 'Trust-Region', where bounds are respected.
    if ~isempty(opts_in.Lower)
        fo.Lower = opts_in.Lower;
    end
    if ~isempty(opts_in.Upper)
        fo.Upper = opts_in.Upper;
    end

    %% Fit
    [fitobj, gof, output] = fit([x, y], z, ft, fo);

    coeffNames = coeffnames(fitobj);   % should be {'a';'b';'c';'d'}
    coeffVals  = coeffvalues(fitobj);

    %% Confidence bounds -> standard errors
    ci = confint(fitobj, 0.95);        % 2 x nCoeff: [lower; upper]
    tcrit = tinv(0.975, gof.dfe);
    se = (ci(2, :) - ci(1, :)) / (2 * tcrit);

    %% Covariance matrix of coefficients (from the fit Jacobian)
    % Approximate parameter covariance from the (possibly reweighted)
    % Jacobian at convergence: cov(beta) = inv(J'J) * mse
    % This is the standard linearized-CI approximation used by nlparci.
    J = full(output.Jacobian);
    resid = output.residuals;
    mse = gof.sse / gof.dfe;
    try
        covB = inv(J' * J) * mse;
    catch
        covB = NaN(numel(coeffVals));
        warning('fit_torque_model:illConditioned', ...
            'J''J was singular; covariance matrix set to NaN. Check identifiability of a,b,c,d for this test.');
    end

    %% Residual diagnostics
    residMean   = mean(resid);
    residStd    = std(resid);
    residMaxAbs = max(abs(resid));
    if numel(resid) > 1
        residAutocorrLag1 = corr(resid(1:end-1), resid(2:end));
    else
        residAutocorrLag1 = NaN;
    end

    %% Assemble output struct
    fitResult = struct();

    % --- metadata (passed through as-is) ---
    if nargin >= 4 && isstruct(metadata)
        mfields = fieldnames(metadata);
        for k = 1:numel(mfields)
            fitResult.(mfields{k}) = metadata.(mfields{k});
        end
    end

    % --- coefficients ---
    for k = 1:numel(coeffNames)
        fitResult.(coeffNames{k})            = coeffVals(k);
        fitResult.([coeffNames{k} '_SE'])     = se(k);
        fitResult.([coeffNames{k} '_CI_lo'])  = ci(1, k);
        fitResult.([coeffNames{k} '_CI_hi'])  = ci(2, k);
    end
    fitResult.CoeffNames = coeffNames';
    fitResult.CoeffCovariance = covB;   % full matrix, keep out of flat tables

    % --- goodness of fit ---
    fitResult.N          = numel(z);
    fitResult.DFE         = gof.dfe;
    fitResult.SSE         = gof.sse;
    fitResult.RMSE        = gof.rmse;
    fitResult.Rsquare     = gof.rsquare;
    fitResult.AdjRsquare  = gof.adjrsquare;

    % --- residual diagnostics ---
    fitResult.ResidualMean       = residMean;
    fitResult.ResidualStd        = residStd;
    fitResult.ResidualMaxAbs     = residMaxAbs;
    fitResult.ResidualAutocorrLag1 = residAutocorrLag1;

    % --- convergence / solver diagnostics ---
    fitResult.ExitFlag    = output.exitflag;
    fitResult.Converged   = output.exitflag > 0;
    fitResult.Iterations  = output.iterations;
    fitResult.FuncCount   = output.funcCount;
    fitResult.Algorithm   = output.algorithm;
    fitResult.Message     = output.message;

    % --- input coverage (for checking slow vs fast tests span the same range) ---
    fitResult.x_min = min(x); fitResult.x_max = max(x);
    fitResult.y_min = min(y); fitResult.y_max = max(y);

    % --- keep the fit object itself in case you want to re-plot later ---
    fitResult.FitObject = fitobj;

    if ~fitResult.Converged
        warning('fit_torque_model:notConverged', ...
            'Fit for this test did not report successful convergence (exitflag = %d). Inspect before including in group stats.', output.exitflag);
    end

    %% Optional plot (fitted surface + raw data trace, cftool-style)
    if opts_in.PlotFit
        plotTitle = opts_in.PlotTitle;
        if isempty(plotTitle) && isfield(fitResult, 'Condition') && isfield(fitResult, 'Speed')
            plotTitle = sprintf('%s - %s', string(fitResult.Condition), string(fitResult.Speed));
        elseif isempty(plotTitle)
            plotTitle = 'Fit Plot';
        end
        plot_torque_fit(fitobj, x, y, z, 'Title', plotTitle);
    end
end