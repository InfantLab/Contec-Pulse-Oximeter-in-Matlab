% Script for evaluating estimates of R agains SpO2 reference measurements.
% This version only works for data set with three subjects and a fixed
% window length corresponding to the interval of the anotation of the
% reference measurements.

Rplot = [];
REFplot = [];

for i = 1:3 % For each subject...
    R = RR(:,i);

    load(['../data/subject',num2str(i),'Ref.mat'], 'SpO2ref')  % Load reference.

    % Remove NaN's:
    idx = ~isnan(SpO2ref);
    SpO2ref = SpO2ref(idx);
    R = R(idx);
    idx = ~isnan(R);
    SpO2ref = SpO2ref(idx);
    R = R(idx);
    
    switch i
        case 1
            Rsub1 = R; % R
            REFsub1 = SpO2ref;
        case 2
            Rsub2 = R;
            REFsub2 = SpO2ref;
        case 3
            Rsub3 = R;
            REFsub3 = SpO2ref;
    end
end

Error = nan(3,1);
calCurve = nan(3,2);

for i = 1:3 % Calculate error for each combination of trainig and test set.
    switch i % Setup trainng and test set for each combination:
        case 1
            train = [Rsub1; Rsub2];
            trainRef = [REFsub1; REFsub2];
            test = Rsub3;
            testRef = REFsub3;
        case 2
            train = [Rsub2; Rsub3];
            trainRef = [REFsub2; REFsub3];
            test = Rsub1;
            testRef = REFsub1;
        case 3
            train = [Rsub3; Rsub1];
            trainRef = [REFsub3; REFsub1];
            test = Rsub2;
            testRef = REFsub2;
    end

    p = loocv(trainRef,train); % Fits a linear model with R as the explanatory variable using Leave-One-Out.
    pp = [1/p(1) roots(p)];    % Invert the linear model to have R along the x-axis and SpO2 along the y-axis.
    calCurve(i,:) = pp;        % Store current coeffcient.

    SpO2 = polyval(pp,test); % Convert R estimates to SpO2-values.
    err = abs(SpO2-testRef); % Euclidian error.
    Error(i) = mean(err);    % Mean error for current training and test set.
end

Error = mean(Error) % Over-all mean error.

calCurve = mean(calCurve); % Average calibration curve coefficients.
x = linspace(.5, 2.5, 2);  % Range to plot calibration curve.
y = polyval(calCurve,x);   % Calibration curve to plot.

figure, plot(x, y, Rsub1, REFsub1, 'x', Rsub2, REFsub2, '+', Rsub3, REFsub3, 's'),  xlim([0 3]), ylim([68 102])
xlabel 'Optical ratio R', ylabel 'Oxygen Saturation S_pO_2 (%)'
legend('Calibration curve', 'Subject 1', 'Subject 2', 'Subject 3')%,'location', 'southeast')

%print -depsc2 ../path/filename.eps % Save figure