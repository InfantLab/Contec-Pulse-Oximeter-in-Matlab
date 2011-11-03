function [r ppg noise] = masimoDST(X, M, R, stepSize)
% [r ppg noise] = masimoDST(X, M, R, stepSize)
% An implementation of the Masimo DST algorithm for estimation of the
% oxygen saturation ratio r. X must be a matrix containg data from the red
% recording alon the first column and data from the infrared recording
% along the second column. M is the order of the RLS adaptive filter. R is
% a vector specifying the range of r. stepSize specifies the increment of r.

% October 2008, Thomas Jensen, s021954@student.dtu.dk

if nargin < 1
    error('Usage: r = masimoDST(X, M, R, stepSize)')
end

if nargin < 2
    M = 32;             % Default filter order.
    R = [0; 5];         % Default range of r.
    stepSize = 0.01;    % Default step size of r.
elseif nargin < 3
    R = [0; 5];
    stepSize = 0.01;
elseif nargin < 4
    stepSize = 0.01;
end

dr = stepSize; % Step size for r for powerspectrum iterations.

% Setup and initialize RLS adaptive filter parameters and values:
lam = 1;                    % Exponential weighting factor
delta = 0.1;                % Initial input covariance estimate
w0 = zeros(M,1);            % Initial tap weight vector
P0 = (1/delta)*eye(M,M);    % Initial setting for the P matrix
Zi = zeros(M-1,1);          % FIR filter initial states
% Running the RLS adaptive filter for 1000 iterations. 
Hadapt = adaptfilt.rls(M,lam,P0,w0,Zi);
%Hadapt = adaptfilt.lms(M);
%Hadapt.PersistentMemory = true;

r = R(1); % Start value for r

P_ppg_old = 0;
dP_ppg = inf; % Initialize dP_ppg to start iterations.
%iter = 0;

while dP_ppg > 0 && r < R(2) % Find first peak within fixed step size.
    r = r+dr; % Increas r
    refSig =X(:,1)-r*X(:,2); % Contruct ref. noise signal.
    %[y,e] = filter(Hadapt,refSig,X(:,1)); % Filter coef., noise, noisy signal 
    [noise ppg] = filter(Hadapt,refSig,X(:,1)); % Filter coef., noise, noisy signal
    P_ppg = sum(ppg.^2); % Energy of ppg signal.
    dP_ppg = P_ppg - P_ppg_old; % Change in energy.
    P_ppg_old = P_ppg; % Save current value of P_ppg.
    %iter = iter+1;
end

if r == R(1) || r >= R(2)
    r = NaN;
    disp('DST did not converge!!!')
end

%figure(1), stairs(P(:,1), P(:,2))%, xlim([max(P(1))-0.1 max(P(1))])

%if nargout > 1
%    refSig =X(:,1)-r*X(:,2); % Contruct ref. noise signal.
%    [noise ppg] = filter(Hadapt,refSig,X(:,1)); % Filter coef., noise, noisy signal
%end