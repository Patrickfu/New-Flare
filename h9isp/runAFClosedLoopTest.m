%% runAFClosedLoopTest
% Drives AF in closed-loop and collects high rate laser metrology data for
% post processing, also transfers meta file with APS raw measurements,
% Drive commands, and raw image sensor temperatures
%
% INPUTS:
% parameters.PythonPath         - path where python libraries reside        
% parameters.CamID              - camera id (0 = UT; 1 = NV; 2 = UTM)        
% parameters.LaserID            - identifier for keyence laser
% parameters.TimeStamp          - timestamp for data collection
% parameters.ClosedLoopFilename - filename prefix for APS, Drive, Temp log and high rate laser metrology mat file    
% parameters.ClosedLoopCommands - AF step commands to issue open loop
% parameters.ClosedLoopStepTime - wait time between steps (to allow settling)
% parameters.keyenceModel - laser metrology system (0 = Factory; 1 = Cupertino)
% parameters.SaveFolder         - folderlocation in which to save collected data
% 
% EXAMPLE CALL:
% parameters.PythonPath = './classes';
% parameters.CamID = 0; % UT
% parameters.LaserID = []; % no laser metrology
% parameters.TimeStamp = datestr(now, 'yyyymmdd_HHMMSS'); % timestamp to apply to collected data
% parameters.ClosedLoopFilename = []; % automatically generate filename
% parameters.ClosedLoopCommands = [-50 0 50 100 50 0]; % positions with respect to neutral position
% parameters.ClosedLoopStepTime = 250; % ms
% parameters.keyenceModel = 1;
% parameters.SaveFolder = '.';
% runAFClosedLoopTest(parameters);
%
function NewSaveFolder = runAFClosedLoopTest(parameters)

disp('Running AF Closed Loop Test...')
NewSaveFolder = [];

% Update status message for GUI if calling this function from GUI environment
if isfield(parameters, 'statusText')
   set(parameters.statusText, 'String', 'Begin AF Closed Loop Test...');
   drawnow;
end

try

% Define enumerations
UTCorD = 0;
NV = 1;
UTM = 2;

% Verify valid camera ID
if parameters.CamID ~= UTCorD && parameters.CamID ~=NV && parameters.CamID ~=UTM
    disp(sprintf('ERROR: Unrecognized Camera ID %d\n',parameters.CamID));    
    % Update status message for GUI if calling this function from GUI environment
    if isfield(parameters, 'statusText')
        set(parameters.statusText, 'String', 'Wrong configuration selected...');
        drawnow;
    end
    return;
end

% Set module ID (0 = UT D10/D11, 1 = NV D11, UT D12)
ModuleID = parameters.CamID; % D10, D11
if parameters.CamID == UTM  
    ModuleID = 1; % D12
end

% Set up paths to recognize python script location
MyPythonScriptsPath = parameters.PythonPath;
if count(py.sys.path, MyPythonScriptsPath) == 0
    insert(py.sys.path, int32(0), MyPythonScriptsPath);
end

% Create python object to interface to both cameras
h9isp = py.terminal.h9ispTerminal(''); % optional argument for python logger (disabled here)

% Open connection to the device
disp('Connecting to the camera via h9isp...')

% Update status message for GUI if calling this function from GUI environment
if isfield(parameters, 'statusText')
   set(parameters.statusText, 'String', 'Connecting to the camera...');
   drawnow;
end

h9isp.connectToDevice();
h9isp.read_telnet_cmd();

% If the parameters.ClosedLoopFilename is not specified, read the NVM for the camera serial
% number
PhoneSerialNumberString = [];
if isempty(parameters.ClosedLoopFilename)
    % Get the phone serial number
    PhoneSerialNumber = send(h9isp, 'gestalt_query ''SerialNumber''');
    idx = 1;
    while isempty(strfind(PhoneSerialNumber.char, 'SerialNumber'))
        if idx > 10
            % Update status message for GUI if calling this function from GUI environment
            if isfield(parameters, 'statusText')
                set(parameters.statusText, 'String', 'ERROR: Device serial number not read properly, Try re-running...', 'ForegroundColor', [1 0 0]);
                drawnow;
            end
            disp('Phone Serial Number not obtained');
        end
        PhoneSerialNumber = h9isp.read_telnet_cmd();
        idx = idx+1;
    end
    % Parse phone serial number printout
    PhoneSerialNumberString = regexp(PhoneSerialNumber.char,'(?<=")[^"]+(?=")','match');
    if ~isempty(PhoneSerialNumberString)
        PhoneSerialNumberString = PhoneSerialNumberString{1};
    else
        PhoneSerialNumberString = 'UnknownPhoneSerial';
    end
end

% Start up the h9isp iOS terminal and power on the camera modules
send(h9isp, 'h9isp -nbx');
send(h9isp, 'forget');
send(h9isp, 'on');
send(h9isp, sprintf('reloadnvm %d',ModuleID));

% Disable verbose output from the image sensor
send(h9isp, 'v');

% If the parameters.ClosedLoopFilename is not specified, read the NVM for the camera serial
% number
if isempty(parameters.ClosedLoopFilename)
    
    NvmMap = send(h9isp, sprintf('getNVM %d', ModuleID));
    idx = 1;
    while isempty(strfind(NvmMap.char, '<nvm-values>')) && isempty(strfind(NvmMap.char, '</nvm-values>'))
        if idx > 10
            % Update status message for GUI if calling this function from GUI environment
            if isfield(parameters, 'statusText')
                set(parameters.statusText, 'String', 'ERROR: Camera serial number not read properly, Try re-running...');
                drawnow;
            end            
            error('WARNING: Camera serial number not obtained');
        end
        NvmMap = h9isp.read_telnet_cmd();
        idx = idx + 1;
    end

    % Parse NvmMap for camera serial number
    NvmMapString = NvmMap.char;
    startIdx = strfind(NvmMapString, '0x0010:');
    endIdx = strfind(NvmMapString, '0x0020:');
    
    % Extract out serial number information
    m = sscanf(strtrim(NvmMapString(startIdx:endIdx-1)), ['0x0010:', '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s']);
    CameraSerialNumberHex = m(7:28);
    CameraSerialNumberString = NVM2SN(CameraSerialNumberHex);
    
    % Determine parameters.ClosedLoopFilename
%     parameters.ClosedLoopFilename = [CameraSerialNumberString '_' parameters.TimeStamp '_ClosedLoop'];
    parameters.ClosedLoopFilename = 'ClosedLoop';
    
    % Generate a new folder in which to store the logged data
    NewSaveFolder = fullfile(parameters.SaveFolder, PhoneSerialNumberString, CameraSerialNumberString, parameters.TimeStamp);
    if ~exist(NewSaveFolder)
        mkdir(NewSaveFolder);
    end
    
end

% Initialize UT sphere to (0,0) position with closed-loop sphere control
% enabled
if parameters.CamID == UTCorD || parameters.CamID == NV % D10, D11
    send(h9isp, 'oissetmode 0 3');
else % parameters.CamID = NV, D12
    send(h9isp, 'oissetmode 1 3');
end

% Enable meta-file logging for UT and NV (to be loaded to PDCA)
send(h9isp, sprintf('enableoismeta %d 1',ModuleID)); 
send(h9isp, sprintf('enableapsmeta %d 1',ModuleID)); 

% Put the AF controller into open loop mode
send(h9isp, sprintf('apsrunmodeset %d 2', ModuleID));

% Set OIS position to (0,0);  redundant command
if parameters.CamID == UTCorD || parameters.CamID == NV % D10, D11
    send(h9isp, 'oissetposition 0 0 0');
else % parameters.CamID = NV, D12
    send(h9isp, 'oissetposition 1 0 0');
end

% Start logging laser data
% NOTE:  Controller memory is limited to 64KB so CollectionTime should not
% exceed time required to fill the memory or else data at the end of the
% test will not be stored
CollectionTime = 5; % seconds

disp('Initializing the laser...')

% Update status message for GUI if calling this function from GUI environment
if isfield(parameters, 'statusText')
   set(parameters.statusText, 'String', 'Initializing the laser...');
   drawnow;
end

% Create the serial connection to the laser (NOTE: may have to modify this
% is port name is different)
try
    LaserObjPath = strcat('/dev/cu.', parameters.LaserID);
    if parameters.keyenceModel == 1
        LaserObj = TKeyenceLKG(LaserObjPath);
    else
        LaserObj = TKeyenceLKG5000(LaserObjPath);
    end
catch
    LaserObj = [];
    disp('ERROR: Not connected to laser metrology system; No laser data will be saved.');
    % Update status message for GUI if calling this function from GUI environment
    if isfield(parameters, 'statusText')
        set(parameters.statusText, 'String', 'Laser NOT connected, No laser data will be saved...');
        drawnow;
    end
end

% Start streaming the image sensor
disp('Begin streaming image sensor');
send(h9isp, sprintf('start %d 109 0', ModuleID));

% Enable AF resistance measurements for NV only, D11
if parameters.CamID == NV % for NV only
    disp('Enabling AF resistance measurements for NV');
    send(h9isp, 'i2cwrite 1 0xc 0x3e 1 2 0x0016');
    pause(1);
end

% i2c commands
if parameters.CamID == UTCorD || parameters.CamID == UTM % for UT only, D10, D11, D12
    disp('Enabling ARC');
    send(h9isp, sprintf('i2cwrite %d 0x1c 15 1 2 900',ModuleID));  % Enable ARC: writes 0x384 to the ARC CFG register
    pause(1);
else % parameters.CamID = NV
    disp('Enabling ISRC');
    send(h9isp, 'i2cwrite 1 0x0c 0x2 1 2 0x0301');
    pause(1);
end

% Start data collection of laser metrology data
disp('Start Data collection...');

% Update status message for GUI if calling this function from GUI environment
if isfield(parameters, 'statusText')
   set(parameters.statusText, 'String', 'Collecting data logs...');
   drawnow;
end

% Set the VCM to neutral and record the AF position
if parameters.CamID == UTCorD || parameters.CamID == UTM % UT
    send(h9isp, sprintf('apsactuatorset %d 0',ModuleID));
    pause(2);
    AFPositionString  = send(h9isp, sprintf('apspositionget %d',ModuleID));    %% UT ze, R

else % NV
    send(h9isp, 'apsactuatorset 1 1024');
    pause(2);
    AFPositionString  = send(h9isp, 'apspositionget 1');    %% NV ze, R
end

% Record AF position
AFPositionMetrics = sscanf(AFPositionString.char, 'apspositionget %d <APSPositionGet> <channel> %dx%d </channel> <result> %dx%d </result> <zposition (um)> %f </zposition (um)> <zposition> %dx%s </zposition> <eastSensorVal> %d </eastSensorVal> <westSensorVal> %d </westSensorVal> <afRes> %f </afRes> <coilTemp> %f </coilTemp> </APSPositionGet>');
NeutralPosition = AFPositionMetrics(6);
disp(['Neutral Position is ', num2str(NeutralPosition), ' um']);

% Format commands for meta file
cmd = [];
for n = 1:length(parameters.ClosedLoopCommands)
    cmd{2*(n-1)+1} = sprintf('apspositionset %d %d', ModuleID, int16(parameters.ClosedLoopCommands(n)+NeutralPosition));
    cmd{2*(n-1)+2} = sprintf('msecdelay %d', int16(parameters.ClosedLoopStepTime));
end

% i2c commands
if parameters.CamID == UTCorD || parameters.CamID == UTM % for UT only, D10, D11, D12
    disp('Disabling ARC');
    send(h9isp, sprintf('i2cwrite %d 0x1c 15 1 2 0',ModuleID));  % Disable ARC/ISRC 
    pause(1);
else % parameters.CamID = NV 
    disp('Disabling ISRC');
    send(h9isp, 'i2cwrite 1 0x0c 0x2 1 2 0x0101');
    pause(1);
end

% Put the AF controller into closed loop mode
send(h9isp, sprintf('apsrunmodeset %d 1', ModuleID));

% Start the meta file
disp('Enabling Logging');
send(h9isp, sprintf('oismetafilestart %d 0xff ./%s', ModuleID, [parameters.ClosedLoopFilename '.log']));

% Start data collection of laser metrology data
disp(['Start Data collection for ', num2str(CollectionTime), ' seconds...']);

% Begin collecting laser data
if ~isempty(LaserObj)
    KeyenceLKGStartDataStorage(LaserObj);
end

% Wait before starting closed-loop test
pause(parameters.ClosedLoopStepTime/1000);  % step time is in units of ms

% Run the AF control test
disp('Running AF Control Test');
for m = 1:length(cmd)
    send(h9isp, cmd{m});
end

% Wait for the test to finish running
pause(CollectionTime);

% Stop data collection
if ~isempty(LaserObj)
    [Accumulating, NumData] = KeyenceLKGStopDataStorage(LaserObj);
    disp('End Data collection...');
end

% Stop streaming the camera
send(h9isp, sprintf('stop %d', ModuleID));

if ~isempty(LaserObj)
    % Load data from the controller memory to the matlab workspace
    disp('Reading collected data from memory...');
    
    % Update status message for GUI if calling this function from GUI environment
    if isfield(parameters, 'statusText')
        set(parameters.statusText, 'String', 'Copying laser metrology data...');
        drawnow;
    end
    
    laserData = KeyenceLKGGetData(LaserObj,NumData);
    if ~isempty(NewSaveFolder)
        save(fullfile(NewSaveFolder,[parameters.ClosedLoopFilename, '_laser.mat']), 'laserData');
    else
        save(fullfile(parameters.SaveFolder, [parameters.ClosedLoopFilename, '_laser.mat']), 'laserData');
    end
end

% Update status message for GUI if calling this function from GUI environment
if isfield(parameters, 'statusText')
   set(parameters.statusText, 'String', 'Copying log files...');
   drawnow;
end

% Copy meta file from the phone
if ~isempty(NewSaveFolder)
    disp(['Copying log file: ' parameters.ClosedLoopFilename '.log from phone to ' NewSaveFolder]);
    getFiles(NewSaveFolder, [parameters.ClosedLoopFilename '.log']);
else
    disp(['Copying log file: ' parameters.ClosedLoopFilename '.log from phone']);
    getFiles(parameters.SaveFolder, [parameters.ClosedLoopFilename '.log']);
    NewSaveFolder = parameters.SaveFolder;
end

disp('End AF Closed Loop Test...')

% Update status message for GUI if calling this function from GUI environment
if isfield(parameters, 'statusText')
   set(parameters.statusText, 'String', 'End AF Closed Loop Test...');
   drawnow;
end

catch
    
    % If running the GUI, save a screen capture of the GUI in the test
    % folder (otherwise, skip)    
    if isfield(parameters, 'configs_list')
        export_fig(fullfile(parameters.SaveFolder,'screenshot_GUI.png'));
    end
    error(['Error: Run AF Closed Loop Test Failed', Err.message]);
 
end


end
