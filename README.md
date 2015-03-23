This is a small help file explaining how to get started using the Contec CMS60C (http://contecmed.com/) to capture real time heart rate and pulse oximetry data into Matlab.

Any questions, please contact 
Caspar Addyman <c.addyman@bbk.ac.uk>

Model number
============

Be aware that different models in the CMS range run at different baud rates:
- CMS60C  runs on a 115200 baud rate, parity no
- CMS50D+ runs on a 19200 baud rate, parity No.


You will need to comment in/out the appropriate lines in the connection script.
Either 
configString on line 142 of HeartRateUSB.m
or
serialObj on Line 117 ins HeartRateUSB_serial.m 



Requirements:
=============

This code should run in any version of Matlab >R2007 
It should also work in Octave >v3.1 but this hasn't been verified

Matlab ( >R2007)
http://www.mathworks.co.uk/

Octave ( >v3.1)
http://www.gnu.org/software/octave/

Optional:
=========

PsychToolbox version 3.0 
http://www.psychtoolbox.org/                      


Installation:
=============

Download the contents of this directory, unzip and install the Mac OSX VCP Driver.zip. The heartrate data is collected by calling the HeartRateUSB.m or the HeartRateUSB_serial.m script. (They are essentially identical but the former uses PsychToolBox IOPort function while the latter uses standard matlab serial commands.)



This code is open source and freely available for you to use in your own projects. 


Any questions, bugs or comments, please post them on github.com or email them to c.addyman@bbk.ac.uk

[![DOI](https://zenodo.org/badge/3891/YourBrain/Contec-Pulse-Oximeter-in-Matlab.svg)](http://dx.doi.org/10.5281/zenodo.16277)


Alternatives
============

Ian Hands has written a java/SWT app for reading CMS Pulse Oximeters

Info here
http://ian.ahands.org/progs/pulseox/ 

Code here
https://github.com/iphands/PulseOx


