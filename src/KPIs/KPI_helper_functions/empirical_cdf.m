
function [xSorted, yCDF] = empirical_cdf(x)

%% Empirical CDF Helper Function
% This helper returns the sorted finite samples and the corresponding
% empirical cumulative distribution values.

    x = x(:);
    x = x(isfinite(x));

    xSorted = sort(x);
    n = numel(xSorted);

    if n == 0
        yCDF = [];
        return;
    end

    yCDF = (1:n).' / n;

end