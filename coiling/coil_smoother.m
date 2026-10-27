function Sm = coil_smoother(nT, nPts, lambda)
%COIL_SMOOTHER  Linear operator of a cubic smoothing spline.
%
%   Sm = coil_smoother(nT, nPts, lambda) returns the [nPts x nT] matrix
%   that maps nT data values sampled at s = linspace(0,1,nT) to the
%   smoothing spline evaluated at linspace(0,1,nPts). The spline
%   minimises
%       sum_i (y_i - g(s_i))^2 + lambda * int g''(s)^2 ds
%   (natural cubic spline, Reinsch / Green & Silverman 1994). This is the
%   same spline as csaps(s,y,p) and fit(...,'smoothingspline') with
%   SmoothingParam p = 1/(1+lambda); lambda = 0 gives the natural
%   interpolating cubic spline. Because the operator is linear, all
%   frames and coordinates are smoothed with one matrix product.

s  = linspace(0, 1, nT)';
sf = linspace(0, 1, nPts)';
h  = diff(s);
n  = nT;

Q = zeros(n, n-2);
R = zeros(n-2, n-2);
for j = 2:n-1
    Q(j-1, j-1) =  1/h(j-1);
    Q(j,   j-1) = -1/h(j-1) - 1/h(j);
    Q(j+1, j-1) =  1/h(j);
    R(j-1, j-1) = (h(j-1) + h(j))/3;
    if j < n-1
        R(j-1, j) = h(j)/6;
        R(j, j-1) = h(j)/6;
    end
end

G   = (eye(n) + lambda * Q * (R \ Q')) \ eye(n);   % knot values  [n x n]
Gam = [zeros(1, n); R \ (Q' * G); zeros(1, n)];    % second derivatives

i  = min(floor(sf * (n-1)) + 1, n-1);              % interval index (uniform s)
xl = sf - s(i);
xr = s(i+1) - sf;
hi = h(i);
Sm = (xl .* G(i+1, :) + xr .* G(i, :)) ./ hi ...
     - (xl .* xr / 6) .* ((1 + xl ./ hi) .* Gam(i+1, :) + (1 + xr ./ hi) .* Gam(i, :));
end
