function R = fastICAsat(X, fs, winLength, settlTime, overLap, filterType, order, fl, fh)
% R = fastICAsat(X, fs, winLength, settlTime, overLap, filterType, order, fl, fh)
% X must be a matrix containg the red recording in the first column and
% the infrared in the second column. fs is the sampling frequency.
% winLength is the window length in seconds used for estimating R.
% settlTime is the time in seconds of the previous window that is used to
% reduce filter settling distortion. overLap is the overlap of the windows
% in seconds. filterType specifies which filter to use; 1 is FIR and 2 is
% IIR. order is the filter order. fl and fh are the lower and higher
% cutfrequencies of the filter.

addpath('../FastICA_25') % Set path to fastica.m here.

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
DC = nan(numWin,2);             % DC-levels.
A = nan(numWin*2,2);            % ICA mixing matrix.
S = nan(2,numWin*winLength*fs); % ICA sources signales.
t = (0:dataLength-1)'/fs;       % Time vector for plotting.

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
    %Xw = medfilt1(Xw,5);
    Xm = Xw; % For plotting...
    
    % Bandpass filtering:
    Xw = filter(Bf,Af,Xw);
    %Xw = filtfilt(Bf,Af,Xw); % For zero phase distortion
    Xf = Xw;
    
    % Remove first part of data due to filter settling distortion.
    Xt = Xw(settlTime*fs+1:end,:);
    
    % Apply ICAML:
    try
        %[SS AA WW] = fastica(Xt','g','gauss','stabilization','on','maxNumIterations',10e4);
        [SS AA WW] = fastica(Xt', 'g', 'skew','maxNumIterations',10e4); %,'maxNumIterations',10e4);
        %[S(:,win(settlTime*fs+1:end)) A(2*i-1:2*i,:) WW] = fastica(Xt','g','skew','maxNumIterations',10e3,'numOfIC',2);
        % sort components according to energy:
        [Y,I]=sort((sum(AA.^2,1))'.*sum(SS.^2,2)); I = flipud(I);
        S(:,win(settlTime*fs+1:end)) = SS(I,:); A(2*i-1:2*i,:) = AA(:,I);
    
    % Plot signals:
    if draw
        figure(1)
        subplot(3,2,1), plot(t(win),Xn,'.'), title(['Normalized Raw Data, window # ',num2str(i)]), xlabel 'Time [s]'
        subplot(3,2,3), plot(t(win),Xm,'.'), title 'Median filtered Data', xlabel 'Time [s]'
        subplot(3,2,5), plot(t(win),Xf,'.'), title 'Bandpas filtered Data', xlabel 'Time [s]'
        
        subplot(3,2,2), plot(t(win(settlTime*fs+1:end)),S(1,win(settlTime*fs+1:end))','.')
        title 'Independent Source Signal 1', xlabel 'Time [s]'
        subplot(3,2,4), plot(t(win(settlTime*fs+1:end)),S(2,win(settlTime*fs+1:end))','.')
        title 'Independent Source Signal 2', xlabel 'Time [s]'

        drawnow
        %pause
    end
    catch
        disp('=========== error ===========')
        %error('msgid', '%s', 'MESSAGE')
        %error(gce) %('FastICA did not converge!')
    end
end

% Calculate R from mixing matrix:
RR = A(1:2:end-1,:)./A(2:2:end,:);
swap = RR(:,1) < 0 & RR(:,2) > 0;
RR(swap,:) = fliplr(RR(swap,:));
R = RR(:,1);

if draw
    figure(2)
    stairs((1:numWin)*(winLength-overLap),R), xlabel 'Time [s]', ylabel 'R value'
end

