% Created by Wei Luo@ Apple Inc.
% Copyright 2017 Apple Inc. All Rights Reserved.
% 01-05-2017
% Version 1.0

close all;
clear;
clc;

% this code tests the image capture script made for field capture
ModuleID      = 'U0469'; 
%Cam_ID = 2;
%Mode = 121;
Cam_ID = 0;
Mode = 139;
chartDistance_mm = 37; % unit: mm

% Generate Timestamp
format shortg
dateTime = strread(num2str(fix(clock), '%02d'),'%s');
timeStamp = [dateTime{1} dateTime{2} dateTime{3} 'T' dateTime{4} dateTime{5} dateTime{6}];

% create the local directory to save the images
localDirectoryPath = ['~/Desktop/ImageCaptures_outdoor/' ModuleID filesep num2str(chartDistance_mm) filesep timeStamp filesep]; %
if ~exist(localDirectoryPath, 'dir')
    mkdir(localDirectoryPath);
end

PythonPath = '/Users/zhenhong_fu/Downloads/20170321_hxisp_control/h9isp';
if count(py.sys.path, PythonPath) == 0
    insert(py.sys.path, int32(0), PythonPath);
end

% Create python object to interface to both cameras
h9isp = py.terminal.h9ispTerminal(''); % optional argument for python logger (disabled here)

%% start connection
h9isp.connectToDevice();
tt = h9isp.read_telnet_cmd();

% remove all previous images
send (h9isp,'rm *.raw *.meta *.jpg *.mov');
send (h9isp, '');

% Start up the h9isp iOS terminal and power on the camera modules
send(h9isp, 'h10isp -jrx');
send(h9isp, 'forget');
send(h9isp, 'on');

% Disable verbose output from the image sensor
send(h9isp, 'v off');

send(h9isp, 'writeraw off');
send(h9isp, 'writejpeg on');
send(h9isp, 'writemeta off');


%start streaming
send(h9isp, ['start ' num2str(Cam_ID) ' ' num2str(Mode) ' 0']); % 119: full res

msecdelay=2000;
send(h9isp, ['msecdelay ' num2str(msecdelay)]);

% enable_flag=1;
% send( h9isp, ['afpeakprediction ' num2str(Cam_ID) ' ' num2str(enable_flag)]);

% auto focus
send(h9isp, ['f ' num2str(Cam_ID)]);
% read focus position);
pause(3);

% TimerID = tic;
% ElapsedT = 0;
% while(ElapsedT<30)
% 	ElapsedT = toc(TimerID);
%     % record the image sensor temperature
%     temp_test = char(send(h9isp, ['getsensortemp ' num2str(Cam_ID)]));
%     sensor_temp =  parseString_array_v2(temp_test, '<temperature> ', ' </temperature>');
%     fprintf(['Time: ' num2str(ElapsedT) ' sec,  Sensor temp: ' num2str(sensor_temp) ' C\n']);
% end


% start_V = 0; % unit: V
% end_V   = start_V + 15; % unit: V
% 
% DAC_start = round( start_V/35 * (DAC_35V - DAC_0V)  + DAC_0V);
% DAC_end = round( end_V/35 * (DAC_35V - DAC_0V) + DAC_0V);
% 
% % fly back
% send(h9isp, ['i2cwrite 2 0x0c 0x0 1 2 0x0140' ]);
% 
% 
% % I2CWRITE 2 0 2 1 1 0
% num_positions = 32;
% allVoltage = linspace(start_V, end_V, num_positions);
% all_DACs = round(linspace(DAC_start, DAC_end, num_positions));
% sensor_temps = zeros(1, num_positions);
% fabry_temps = zeros(1, num_positions);
% file_names = {''};
% for DAC_idx = 1:num_positions
% 
%     DAC_position = all_DACs(DAC_idx);
% 
%     % DAC_position
%     DAC_str = dec2hex(DAC_position, 4);
% 
%     % fly back
%     % send(h9isp, ['i2cwrite 2 0x0c 0x0 1 2 0x0140' ]);
%     % pause(0.1)
%     
%     
%     % set focus position
%     send(h9isp, ['i2cwrite 2 0x0c 0x0 1 2 0x' DAC_str]);
%     fprintf(['Set Position ' DAC_str ' %d of %d\n'], DAC_idx, num_positions);

    % record the image sensor temperature
    temp_temp = char(send(h9isp, ['getsensortemp ' num2str(Cam_ID)]));
    sensor_temp = parseString_array_v2(temp_temp, '<temperature> ', ' </temperature>');
    
    % record the focus position
    focus_temp = char(send(h9isp, ['GetFocusPos ' num2str(Cam_ID)]));
    focus_pos =  parseString_array_v2(focus_temp, '<position> ', ' </position>');

    % record the exposure time
    exposure_temp = char(send(h9isp, ['snap ' num2str(Cam_ID)]));
    focus_pos =  parseString_array_v2(exposure_temp, '<name>aeShutterTime (µs)</name>                    	<value>', '<name>aeShutterTime (µs)</name>                    	<value>33253</value>');
    
    % take an image
    for i=1:180
        nameBase  = [ModuleID '_foucus_pos=' num2str(focus_pos) '_sensor_temp=' num2str(sensor_temp) '_image_' num2str(i)];
        send(h9isp, ['namebase '  nameBase ' 0']);
        send(h9isp, ['p 1 ' num2str(Cam_ID)]);
    
        fprintf(['Take image %d\n'], i);
        pause(0.1)
    end
    

%     m_temperature = thermalcouple.ExTechSDL200GetTemperature;    
%     fabry_temps(DAC_idx) = m_temperature(1);

    % % record the image sensor temperature
    % temp_test = char(send(h9isp, ['getsensortemp ' num2str(Cam_ID)]));
    % sensor_temp =  parseString_array_v2(temp_test, '<temperature> ', ' </temperature>');

    % sensor_temps(DAC_idx) = sensor_temp;

    % fprintf('Position %d: Fabry: %5.2f,  Sensor: %5.2f\n', DAC_position, m_temperature(1), sensor_temp);


% end


% thermalcouple.delete
% clear thermalcouple

send(h9isp, 'off');
send(h9isp, 'quit');

% plot the temperature values
% plot(sensor_temps, 'o-')
% hold on
% plot(fabry_temps, '+-')
% grid on


portNum = 10000;  % hard-coded port number in python script

% saveas(gcf, [localDirectoryPath 'temp_plot.png'], 'png')
% save([localDirectoryPath 'variables.mat'])

fileExtension = '.jpg';
path=localDirectoryPath;
strcat(path, '/jpg');
getFiles(portNum, path, fileExtension)
fileExtension = '.meta';
path=localDirectoryPath;
strcat(path, '/meta');
getFiles(portNum, path, fileExtension)
fileExtension = '.raw';
path=localDirectoryPath;
strcat(path, '/raw');
getFiles(portNum, path, fileExtension)

fileExtension = '.mov';
path=localDirectoryPath;
strcat(path, '/mov');
getFiles(portNum, path, fileExtension)

