
Overview of files and directories.

data:
Contains a data-set consisting of measurements on three subjects using a two-wavelength pulse oximetry scheme.
The red and infrared recordings are stored in a matrix X as the first and second column respectively for each subject.
The matrix is saved in a file named subject1Data.mat for subject 1 etc. Reference SpO2 measurements are stored in 
vectors called SpO2ref and saved in files named subject1Ref.mat for subject 1 etc.

Software:

demo_sat.m is intended for demonstrating how data can be loaded and R estimated using one of the following five algorithms:

icaMLsat.m esimates R using the Maximum Likelihood ICA algorithm from the ICA:DTU Toolbox.
icaMSsat.m esimates R using the Molgedey and Schuster decorrelation ICA algorithm from the ICA:DTU Toolbox.
icaMFsat.m esimates R using the Mean Field ICA algorithm from the ICA:DTU Toolbox.

fastICAsat.m estimates R using the FastICA algorithm.

masimoDSTsat.m estimates R using the Masimo DST algorithm.

masimoDST.m is an implementation of the Masimo DST algorithm.

evalEstimates.m evaluates the estimated R against provided SpO2 reference measurements using a training- and test-set topology.
loocv.m is used by evalEstimates.m to fit a linear model as calibration curve using the Leave-One-Out method.

In addition, in order to run the demo the FastICA and ICA:DTU Toolbxes icaML, icaMF, icaMF are required. Please make sure that 
these toolbox scripts are placed in the same directgory as the demo code, or adapt the function to include the relevant path using the 
addpath Matlab function.

FastICA_25 can be downaloded from http://www.cis.hut.fi/projects/ica/fastica/

The ICA:DTU Toolbox can be downloaded from http://isp.imm.dtu.dk/toolbox/ica/