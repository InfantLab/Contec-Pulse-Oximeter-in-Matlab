function p = loocv(x,y)
% p = loocv(x,y)
% Fits a linear model to data vectors x and y using the Leave-One-Out
% method and returns the coefficients of the linear model.

if nargin < 2
    error('Not enough input arguments!')
elseif size(x)~=size(y)
    error('x and y must have same size!')
end

% Remove NaN's:
idx = ~isnan(x);
x = x(idx);
y = y(idx);
idx = ~isnan(y);
x = x(idx);
y = y(idx);

% Leave One Out:
m = length(x);
P = nan(m,2);
for i = 1:m
    xx = x((1:end)~=i);
    yy = y((1:end)~=i);
    P(i,:) = polyfit(xx,yy,1);
end
p = mean(P);