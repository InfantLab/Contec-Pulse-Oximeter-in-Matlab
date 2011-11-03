function R = icaMFsat(X, fs, winLength, settlTime, overLap, filterType, order, fl, fh)
% R = icaMSsat(X, fs, winLength, settlTime, overLap, filterType, order, fl, fh)
% X must be a matrix containg the red recording in the first column and
% the infrared in the second column. fs is the sampling frequency.
% winLength is the window length in seconds used for estimating R.
% settlTime is the time in seconds of the previous window that is used to
% reduce filter settling distortion. overLap is the overlap of the windows
% in seconds. filterType specifies which filter to use; 1 is FIR and 2 is
% IIR. order is the filter order. fl and fh are the lower and higher
% cutfrequencies of the filter.

addpath('../v3') % Set path to icaMF.m here.

% Setup ICAMF, see 'help icaMF' for info.
PAR.Sprior = 'combi';           % Use different prior pdf. for each source signal.
PAR.sources = 1;                % Number of source signals.
PAR.S(1).prior = 'bigauss';     % Prior pdf. of source 1.
PAR.S(2).prior = 'mog';         % Prior pdf. of source 2.
PAR.S(3).prior = 'mog';         % Prior pdf. of source 3...
PAR.Sigmaprior = 'diagonal';    % Individual noise on each sensor (wave-length).
PAR.solver = 'ec';              % Seems to be fastest.
PAR.optimizer = 'em';           % Seems to be fastest.
PAR.draw = 0;                   % Do not draw!!!
PAR.Aprior = 'positive'; % Constrain mixing matrix to be positive.
%PAR.A_init = rand(2,PAR.sources); % Positive initial mixing matrix.

[dataLength recordings] = size(X);

if recordings ~=2
    error('X must have have two columns!')
end

draw = 0; % Plot signals for each window. 1/0 = on/off.

%%% Setup Filters %%%
if filterType == 1
    Bf = fir1(order, [fl/(fs/2) fh/(fs/2)]); Af = 1; % FIR
elseif filterType == 2
    [Bf Af] = butter(order, [fl/(fs/2) fh/(fs/2)]); % IIR
end

numWin = floor((dataLength/fs-settlTime-overLap)/(winLength-overLap)); % Number of windows in recording.

%%% Variables for storing results %%%
DC = nan(numWin,2);                 % DC-levels.
A = nan(numWin*2,PAR.sources);      % ICA mixing matrix.
S = nan(PAR.sources,dataLength);    % ICA sources signales.
N = nan(2,dataLength);              % ICA noise term.
t = (0:dataLength-1)'/fs;           % Time vector for plotting.

for i = 1:numWin
    % Data winow:
    win = (i-1)*(winLength-overLap)*fs+1:(i*winLength+settlTime)*fs-(i-1)*overLap*fs;
    Xw = X(win,:);
    
    if draw
        figure(2)
        subplot(2,2,1), plot(t(win),Xw(:,1), '.r','MarkerSize',1), title 'Red', axis tight
        subplot(2,2,2), plot(t(win),Xw(:,2), '.b','MarkerSize',1), title 'Infrared', axis tight
        subplot(2,2,3), plot(t(win(2:end)),diff(Xw(:,1)), '.r','MarkerSize',1), title 'dRed', axis tight
        xlabel 'Time [s]'
        subplot(2,2,4), plot(t(win(2:end)),diff(Xw(:,2)), '.b','MarkerSize',1), title 'dInfrared', axis tight
        xlabel 'Time [s]'
        drawnow
    end
    
    % Normalize by DC-component:
    DC(i,:) = mean(Xw);
    totWinLength = (winLength+settlTime)*fs;
    Xw = Xw-repmat(DC(i,:),totWinLength,1);
    Xw = Xw./repmat(DC(i,:),totWinLength,1);
    %Xw = Xw-1;
    Xn = Xw;
    
    % Median filtering:
    %Xw = medfilt1(Xw,5); % 5 or 7 is a good size...
    Xm = Xw; % For plotting...
    
    % Bandpass filtering:
    Xw = filter(Bf,Af,Xw);
    %Xw = filtfilt(Bf,Af,Xw); % For zero phase distortion
    Xf = Xw;
    
    % Remove first part of data due to filter settling distortion.
    Xt = Xw(settlTime*fs+1:end,:);
    
    % Apply ICAMF:
    normalize = max(max(abs(Xt))); % Normalization factor
    Xt = Xt/normalize;
    
    [S(:,win(settlTime*fs+1:end)) A(2*i-1:2*i,:)] = icaMF(Xt',PAR);
    PAR.A_init = A(2*i-1:2*i,:); % Intialize ICAMF with previous mixing matrix.
    N(:,win(settlTime*fs+1:end)) = Xt'-A(2*i-1:2*i,:)*S(:,win(settlTime*fs+1:end)); % ICA noise term.
    
    % Plot signals:
    if draw
        figure(1)
        subplot(3,2,1), plot(t(win),Xn,'.','MarkerSize',2), title(['Normalized Raw Data, window # ',num2str(i)]), xlabel 'Time [s]'
        subplot(3,2,3), plot(t(win),Xm,'.','MarkerSize',2), title 'Median filtered Data', xlabel 'Time [s]'
        subplot(3,2,5), plot(t(win),Xf,'.','MarkerSize',2), title 'Bandpas filtered Data', xlabel 'Time [s]'
        subplot(3,2,2), plot(t(win(settlTime*fs+1:end)),S(:,win(settlTime*fs+1:end))','.','MarkerSize',2)
        title 'Independent Source Signals', xlabel 'Time [s]', ylabel(['R = ',num2str(A(2*i-1,1)/A(2*i,1))])
        subplot(3,2,4), plot(t(win(settlTime*fs+1:end)),N(1,win(settlTime*fs+1:end))','.','MarkerSize',2)
        title 'Noise from red recording', xlabel 'Time [s]'
        subplot(3,2,6), plot(t(win(settlTime*fs+1:end)),N(2,win(settlTime*fs+1:end))','.','MarkerSize',2)
        title 'Noise from infrared recording', xlabel 'Time [s]'
        drawnow
        pause
    end
end

% Calculate R from mixing matrix:
RR = A(1:2:end-1,:)./A(2:2:end,:);
R = RR(:,1);
