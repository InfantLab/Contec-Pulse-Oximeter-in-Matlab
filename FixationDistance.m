function distXY  = FixationDistance(x,y, ROICentre)
%
% Pass in 2 equal lenght vectors of x and y coordinates
% and the coordinates of a rectangular region of interest
% Get back the 

x2 = (x-ROICentre(1))*(x-ROICentre(1));
y2 = (y-ROICentre(2))*(y-ROICentre(2));
distXY = sqrt(x2 + y2);
