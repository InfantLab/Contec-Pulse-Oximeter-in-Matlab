function ret = HeartRateUSB ()
%
% Attempting to talk to the contec.com.cn CMS60C Pulse Oximeter over USB.
% Caspar Addyman Oct 2011
%
% Note: You must first have installed the SiLabs
% USB to UART Bridge Virtual Comm Port (VCP) Drivers
%
% http://www.silabs.com/products/mcu/Pages/USBtoUARTBridgeVCPDrivers.aspx
%
% Communication Protocol in the pdf file in this folder.

port='/dev/cu.SLAB_USBtoUART';

% Data Format: 1 Start bit + 8 data bits + 1 stop bit, odd;
% Baud Rate: 115200

% Data from PC to Pulse Oximeter
% DATA:5 bytes in 1 package,60 packages/second,bit 7 stand for synchronization?
% See PDF for details.

PCtoMonitorBytes(1) = uint8(bin2dec('01111101')); % = hex2dec('7D'); //start command
PCtoMonitorBytes(2) = uint8(bin2dec('10000001')); % = hex2dec('81'); 
PCtoMonitorBytes(3) = uint8(bin2dec('10100001')); % = hex2dec('A1'); //ask for real time data
PCtoMonitorBytes(4) = uint8(bin2dec('10000000')); % = hex2dec('80'); 
PCtoMonitorBytes(5) = uint8(bin2dec('10000000')); % = hex2dec('80');
PCtoMonitorBytes(6) = uint8(bin2dec('10000000')); % = hex2dec('80');
PCtoMonitorBytes(7) = uint8(bin2dec('10000000')); % = hex2dec('80');
PCtoMonitorBytes(8) = uint8(bin2dec('10000000')); % = hex2dec('80');
blocking = 0;
 
configString = 'ReceiverEnable=1 BaudRate=115200 StartBits=1 DataBits=8 StopBits=1 Parity=No OutputBufferSize=1024 InputBufferSize=512 RTS=0 DTR=1';


 

[handle, errmsg] = IOPort('OpenSerialPort', port, configString);
if handle < 0
     error('Error-connecting to heartrate monitor over virtual comm port -- not found...this feature will be disabled');
end

IOPort('Purge', handle); %clear existing data queues.


[nwritten, when, errmsg, prewritetime, postwritetime, lastchecktime] = IOPort('Write', handle, PCtoMonitorBytes, blocking)
navailable = IOPort('BytesAvailable', handle)
IOPort('Flush', handle);
[data, when, errmsg] = IOPort('Read', handle );
 
PCtoMonitorBytes(1) = uint8(bin2dec('01111101')); % = hex2dec('7D'); //start command
PCtoMonitorBytes(3) = uint8(bin2dec('10101111')); % = hex2dec('AF'); //inform device we are connected

[nwritten, when, errmsg, prewritetime, postwritetime, lastchecktime] = IOPort('Write', handle, PCtoMonitorBytes, blocking)


navailable = IOPort('BytesAvailable', handle)
[data, when, errmsg] = IOPort('Read', handle )


ret = false;
IOPort('CloseAll');
return;

% Data Format: 1 Start bit + 8 data bits + 1 stop bit, odd;
% Baud Rate: 115200
% 
% s = serial(port); % Create serial port object s
% set(s,'Tag', 'CMS60C');
% set(s,'BaudRate',115200);
% set(s,'Parity', 'odd');
% set(s,'DataBits', 8);
% set(s,'StopBits', 1);
% set(s,'Terminator','LF');
% set(s,'Timeout', .1);
% % set(s, 'FlowControl', 'software');
% set(s, 'FlowControl', 'hardware');
% fopen(s); %open port
% get(s)
% 
% 
% 
% fwrite(s,PCtoMonitorBytes);
% 
% if(s.BytesAvailable > 0) 
%     fread(s, s.BytesAvailable);
% end
% 
% 
% % x = fscanf(s); % read data into variable x
% fclose(s) % close port
% delete(s)
% clear s
