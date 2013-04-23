function ret = HeartRateUSB_serial(command)
%
% Attempting to talk to the contec.com.cn CMS60C Pulse Oximeter over USB.
% Caspar Addyman Oct 2011
%
% CMS60C Communication Protocol in the pdf file in this folder.
% ./Communication protocol of pulse oximeter V7.0.pdf
%
% Note: You must first have installed the SiLabs
% USB to UART Bridge Virtual Comm Port (VCP) Drivers
%
% http://www.silabs.com/products/mcu/Pages/USBtoUARTBridgeVCPDrivers.aspx
%
% and PsychoToolBox in order to use the IOPORT function
%  
% http://psychtoolbox.org/HomePage
% http://docs.psychtoolbox.org/IOPort
%
% v0.1  - alpha version - just about works (8/11/2011) 

global serialPortOpen;
global serialObj;
global PCtoMonitorBytes;
global port;

    port='/dev/cu.SLAB_USBtoUART';

    if (nargin < 1)
        command = 'livedata';
    end

    switch lower (command)
        case 'connect'
            ret = connect();
        case 'livedata'
            ret = livedata();
        case 'flush'
            %clear queued data
            %not implemented yet
        case 'close'
            close();
        otherwise
            connect();
            ret = livedata();       
    end
end

function stayconnected()
%need to send stillconnected command at least once every 5 seconds
%can send it more often  
    
global lastConnected    
global serialPortOpen
global serialObj

    if isempty(serialPortOpen) || isempty(lastConnected)
        disp('stay connected - reconnect');
        connect();
    end
    
    if toc(lastConnected) < now - 3
        %inform device we are connected 
        [cmdstr cmdarray] = CMS60CInputCommand('connected');
       %  [nwritten, when, errmsg, prewritetime, postwritetime, lastchecktime] = IOPort('Write', monitorIO, cmdarray);
        fwrite(serialObj ,cmdarray);
        lastConnected = tic;
    end
end

function ret = livedata()    
% return livedata (this can build up in queue if request not made often enough)

global serialPortOpen
global serialObj

    stayconnected();
    %[data, when, errmsg] = IOPort('Read', monitorIO);
    data = fread(serialObj, serialObj.BytesAvailable);

    ALLPULSEDATA = [];
    NData = length(data);
    datablockindices = find(data==1);
    NBlocks = length(datablockindices);
    for j = 1:NBlocks
        % DATA:8 bytes in 1 package, ~60 packages/second
        if datablockindices(j)+8 <= NData
            packet = data(datablockindices(j)+1:datablockindices(j)+8);
            [PulseObj PulseArray] = CMS60CRealTimeDataDecode(packet);
            ALLPULSEDATA = [ ALLPULSEDATA ; PulseArray];
        end
    end
    ret = ALLPULSEDATA;
    return;
end


function ret = connect()

global serialPortOpen
global serialObj
global lastConnected
global port

try
    disp(['**** connecting to CMS60C Heart Rate monitor *****']);
    disp(['**** on port  -  ' port  '      ****']);

    port='/dev/tty.SLAB_USBtoUART';

    % Create a serial port object.
    serialObj = instrfind('Type', 'serial', 'Port', port, 'Tag', '');

    % Create the serial port object if it does not exist
    % otherwise use the object that was found.
    if isempty(serialObj)
        %Note that different CMS models connect at different baud rates. You may need to edit the following lines
        serialObj = serial(port, 'BaudRate',115200);  % CMS60C
        % serialObj = serial(port, 'BaudRate',19200); % CMS50D
    else
        fclose(serialObj);
        serialObj = serialObj(1);
    end
    % Data Format: 1 Start bit + 8 data bits + 1 stop bit, odd;
    % Baud Rate: 115200
    set(serialObj,'DataBits',8,'StopBits',1,'Parity','none');
    set(serialObj,'OutputBufferSize',512,'InputBufferSize',1024,'RequestToSend','off','DataTerminalReady','on');
    fopen(serialObj);
    if ~strcmpi(serialObj.Status, 'open')
         error('Error-connecting to heartrate monitor over virtual comm port -- not found...this feature will be disabled');
    end
    
    if(serialObj.BytesAvailable > 0) %clear out buffer
        null = fread(serialObj, serialObj.BytesAvailable);
    end
    

    %the second sequence command codes sent by the PC software in byte 3
    %these are sent indiviually and a response read for each one
    Command{1} = 'stopstore'; % stop sending stored data
    Command{2} = 'stopreal'; % stop sending real time data
    Command{3} = 'storeid'; % ask for storage indentifiers
    Command{4} = 'realtimepi'; % ask for for PI realtime support
    Command{5} = 'devid'; % ask for device identifiers
    Command{6} = 'realtime'; % ask for real time data

    
    %send these commands individually
    for i  = 1:6
        [cmdstr cmdarray] = CMS60CInputCommand(Command{i});
        disp(['*** startup command: ' cmdstr]);
%         [nwritten, when, errmsg, prewritetime, postwritetime, lastchecktime] = IOPort('Write', monitorIO, cmdarray);
        fwrite(serialObj ,cmdarray);
        WaitSecs(0.05);
        navailable = serialObj.BytesAvailable;
        data = fread(serialObj, serialObj.BytesAvailable);
        disp('returns ');
        disp(num2str(data'));
    end
    serialPortOpen = true;
    lastConnected = tic;
    ret = true;
catch exception
    disp('failed to connect ')
    disp(exception.message)
    serialPortOpen = [];
    lastConnected = tic - 20;
    fclose(serialObj);
    ret = false;
end
end

function close()
global serialObj
    % Disconnect from instrument object, obj1.
    fclose(serialObj);
    % Clean up all objects.
    delete(serialObj);
end
