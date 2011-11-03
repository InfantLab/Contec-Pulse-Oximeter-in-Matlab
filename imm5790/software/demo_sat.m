clear, close all

% Configuration:
fs = 200;       % Sampling frequency in [Hz].
winLength = 30; % Data window length in [s].
settlTime = 4;  % Filter settling time in [s].
overLap = 0;    % Allow data windos to overlap in [s].
filterType = 2; % 1 = FIR, 2 = IIR.
order = 4;      % Filter order.
fl = 0.9;       % Lower cut-frequency in [Hz].
fh = 3;         % Higher cut-frequency in [Hz].

M = 16;         % DST adaptive filter order.

Nsubjects = 3; % Number of subjects.
RR = nan(1,Nsubjects); % Allocate memory for storing estimates for every subject.

for i = 1:Nsubjects % For each subject...
    load(['../data/subject',num2str(i),'Data.mat'],'X'); % Load data matrix X from .mat file.
    
    % Estimate R:
    %R = icaMLsat(X, fs, winLength, settlTime, overLap, filterType, order, fl, fh);
    %R = icaMSsat(X, fs, winLength, settlTime, overLap, filterType, order, fl, fh);
    %R = icaMFsat(X, fs, winLength, settlTime, overLap, filterType, order, fl, fh);
    
    R = fastICAsat(X, fs, winLength, settlTime, overLap, filterType, order, fl, fh);
   
    %R = masimoDSTsat(X, fs, M, winLength, settlTime, overLap, filterType, order, fl, fh);

    % Store R for subject i in RR:
    if size(R,1) > size(RR,1)
        RRold = RR;
        RR = nan(length(R),Nsubjects);
        RR(1:size(RRold,1),:) = RRold;
        RR(:,i) = R;
    else
        RR(1:length(R),i) = R;
    end
end

figure, plot(RR,'x'), xlabel 'Estimate index', ylabel 'Optical ratio R', legend('Subject 1', 'Subject 2', 'Subject 3', 'location', 'best')
disp('Estimation of R for all subjects is done!')

evalEstimates;