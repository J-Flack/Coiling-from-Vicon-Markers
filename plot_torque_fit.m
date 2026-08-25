function plot_torque_fit(fitobj, x, y, z, varargin)
%PLOT_TORQUE_FIT Recreate the Curve Fitting Tool's 3D fit plot style:
%a translucent surface for the fitted model and a black connected line
%for the raw data trajectory.
%
%   PLOT_TORQUE_FIT(fitobj, x, y, z) plots the fitted surface from
%   fitobj (a cfit/sfit object, e.g. returned by fit_torque_model) over
%   the range of x and y, with the raw (x,y,z) data overlaid as a black
%   line, matching the look of cftool's default Fit Plot.
%
%   NAME-VALUE OPTIONS
%     'Title'         : plot title (default 'Fit Plot')
%     'XLabel'        : default 't_p_e'
%     'YLabel'        : default 'ACN_p_e'
%     'ZLabel'        : default 'dtz_p_e'
%     'NumGridPoints' : resolution of the fitted surface mesh (default 40)
%     'NewFigure'     : true/false, open a new figure (default true)
%     'View'          : [az el] camera angle (default cftool-like [-37.5 30])
%
%   USAGE
%     [fitobj, gof, output] = fit([x y], z, ft, fo);
%     plot_torque_fit(fitobj, x, y, z, 'Title', '6mm medium - fast');
%
%   Or simply call fit_torque_model(..., 'PlotFit', true) to get this
%   automatically for a single test.

    p = inputParser;
    addParameter(p, 'Title', 'Fit Plot');
    addParameter(p, 'XLabel', 't_p_e');
    addParameter(p, 'YLabel', 'ACN_p_e');
    addParameter(p, 'ZLabel', 'dtz_p_e');
    addParameter(p, 'NumGridPoints', 40);
    addParameter(p, 'NewFigure', true);
    addParameter(p, 'View', [-37.5 30]);
    parse(p, varargin{:});
    o = p.Results;

    x = x(:); y = y(:); z = z(:);

    if o.NewFigure
        figure('Color', 'w');
    end

    % --- Fitted surface ---
    xg = linspace(min(x), max(x), o.NumGridPoints);
    yg = linspace(min(y), max(y), o.NumGridPoints);
    [XG, YG] = meshgrid(xg, yg);
    ZG = fitobj(XG, YG);

    surf(XG, YG, ZG, ...
        'FaceColor', [0.30 0.55 0.85], ...
        'FaceAlpha', 0.55, ...
        'EdgeColor', [0.55 0.65 0.75], ...
        'EdgeAlpha', 0.5, ...
        'LineWidth', 0.25);
    hold on;

    % --- Raw data trace (black line, as in cftool for trajectory-style data) ---
    plot3(x, y, z, 'k-', 'LineWidth', 1.0);

    xlabel(o.XLabel, 'Interpreter', 'none');
    ylabel(o.YLabel, 'Interpreter', 'none');
    zlabel(o.ZLabel, 'Interpreter', 'none');
    title(o.Title, 'Interpreter', 'none');

    legend({'Fitted surface', 'Raw data'}, 'Location', 'best');
    grid on;
    box on;
    view(o.View);
    hold off;
end