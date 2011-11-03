function R = masimoDSTsat(X, fs, M, winLength, settlTime, overLap, filterType, order, fl, fh)
% R = masimoDSTsat(X, fs, M, stepSize, winLength, settlTime, overLap,
% filterType, order, fl, fh)
% X must be a matrix containg the red recording in the first column and
% the infrared in the second column. fs is the sampling frequency. M is the
% order of the adaptive filter. winLength is the window length in seconds
% used for estimating R. settlTime is the time in seconds of the previous
% window that is used to reduce filter settling distortion. overLap is the
% overlap of the windows in seconds. filterType specifies which filter to
% use; 1 is FIR and 2 is IIR. order is the filter order. fl and fh are the
% lower and higher cutfrequencies of the filter.

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
R = nan(numWin,1);                  % DST arterial saturation ratio.
PPG = nan(numWin*winLength*fs,1);   % DST ppg signal.
NOISE = nan(numWin*winLength*fs,1); % DST noise signal.
t = (0:dataLength-1)'/fs;           % Time vector for plotting.

for i = 1:numWin
    % Data winow:
    win = (i-1)*(winLength-overLap)*fs+1:(i*winLength+settlTime)*fs-(i-1)*overLap*fs;
    Xw = X(win,:);
    
    % Normalize by DC-component:
    DC(i,:) = mean(Xw);
    totWinLength = (winLength+settlTime)*fs;
    Xw = Xw-repmat(DC(i,:),totWinLength,1);
    Xw = Xw./repmat(DC(i,:),totWinLength,1);
    Xn = Xw;
    
    % Median filtering
    %Xw = medfilt1(Xw,25);
    Xm = Xw; % For plotting...
    
    % Bandpass filtering:
    Xw = filter(Bf,Af,Xw);
    %Xw = filtfilt(Bf,Af,Xw); % For zero phase distortion
    Xf = Xw;
    
    % Remove first part of data due to filter settling distortion.
    Xt = Xw(settlTime*fs+1:end,:);
    
    % Apply DST:
    [R(i) PPG(win(settlTime*fs+1:end)) NOISE(win(settlTime*fs+1:end))] = masimoDST(Xt,M);
     
    % Plot signals:
    if draw
        figure(1)
        subplot(3,2,1), plot(t(win),Xn,'.'), title(['Normalized Raw Data, window # ',num2str(i)]), xlabel 'Time [s]'
        subplot(3,2,3), plot(t(win),Xm,'.'), title 'Median filtered Data', xlabel 'Time [s]'
        subplot(3,2,5), plot(t(win),Xf,'.'), title 'Bandpas filtered Data', xlabel 'Time [s]'
        
        subplot(3,2,2), plot(t(win(settlTime*fs+1:end)),PPG(win(settlTime*fs+1:end))','.')
        title 'DST ppg signal', xlabel 'Time [s]'
        subplot(3,2,4), plot(t(win(settlTime*fs+1:end)),NOISE(win(settlTime*fs+1:end))','.')
        title 'DST noise signal', xlabel 'Time [s]'

        drawnow
        %pause
    end
end


if draw
    tt = (1:numWin)*(winLength-overLap)+settlTime;
    figure(2), subplot(2,1,1), plot(tt,R, 'x'), xlabel 'Time [s]', ylabel 'R value'
    %title(['Sum of Squared Residuals: ',num2str(SSR)])
    xlim([0 round(dataLength/fs)])%, ylim([mu(1)-2*sigma(1) mu(1)+2*sigma(1)])
    subplot(2,1,2)%, plot(tt,abs(r),'x'), xlim([0 round(dataLength/fs)])%, ylim([mu(1)-2*sigma(1) mu(1)+2*sigma(1)])
    plot(refOD, 'x'), axis tight
    %xlabel 'Time [s]', ylabel 'Correlation'
    %figure(3), stairs(tt,DC), xlabel 'Time [s]', ylabel 'DC levels'
end
