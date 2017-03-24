close all;
clear all;
clc;

%% Camera control parameters
ModuleID = 'U0469'; 
Cam_ID = 2;
Mode = 121;
%Cam_ID = 0;
%Mode = 139;
Test_Name = 'Flare';

%% define positions
Home_Joint = [8.38896e-05,-1.57081,1.19209e-05,-1.57081,-2.3667e-05,0];
Move_Protrait_Left_Start_Joint=[1.01589,-1.71988,2.30098,-3.76121,-1.03189,0.0307272];
Move_Protrait_Right_Start_Joint =[-0.784197,-1.41941,-2.28105,0.599576,0.769512,-0.0276783];
Move_Landscape_Left_Start_Joint=[1.58381,-1.68332,1.6619,-3.1485,-1.59672,1.56773];
Move_Landscape_Right_Start_Joint =[-1.48732,-1.39393,-1.8521,0.13877,1.47158,-1.58474];


Home_TCP = [-0.0160479,-0.215021,0.804879,-0.0061934,-2.21394,2.22318];
Move_Protrait_Left_Start_TCP =[0.00622377,-0.278756,0.472582,-0.0183364,-2.18529,2.24967];
Move_Protrait_Right_Start_TCP = [0.00660604,-0.280286,0.478343,-0.00425317,-2.18079,2.2517];
Move_Landscape_Left_Start_TCP = [0.00397372,-0.286043,0.472545,1.19503,1.18814,-1.23936];
Move_Landscape_Right_Start_TCP = [0.0120503,-0.281544,0.472457,1.18567,-1.1744,1.20344];

%% intial UR3 and build connection
disp('UR3 initialization');
scs=tcpip('192.168.1.4',29999);
fopen(scs);
DataReceived = fread(scs,10)
fprintf(scs,'power on');
pause(1);
fprintf(scs, 'brake release');
pause(1);
fprintf(scs, 'load /programs/testing_comm2.urp');
pause(1);

disp('Receiver started');
t=tcpip('192.168.1.4',30000,'NetworkRole','Server');

fprintf(scs, 'play');
pause(2);

disp('Waiting for connection');
fopen(t);
disp('connection ok');

DataReceived = fread(t,9)

%% move to home position
fprintf(t,'(2)'); % task = 0 : reading joint position
pause(0.5);
joint_pose = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

fprintf(t,'(3)'); % task = 0 : reading tcp position
pause(0.5);
tcp_pose = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

Home = Home_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(6);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);


%% create images output folders

% Generate Timestamp
format shortg
dateTime = strread(num2str(fix(clock), '%02d'),'%s');
timeStamp = [dateTime{1} dateTime{2} dateTime{3} 'T' dateTime{4} dateTime{5} dateTime{6}];

% create the local directory to save the images
localDirectoryPath = ['~/Desktop/ImageCaptures/' Test_Name filesep ModuleID filesep filesep timeStamp filesep]; %
if ~exist(localDirectoryPath, 'dir')
    mkdir(localDirectoryPath);
end

PythonPath = '/Users/PatrickFu/Downloads/20170321_hxisp_control/h9isp';
if count(py.sys.path, PythonPath) == 0
    insert(py.sys.path, int32(0), PythonPath);
end

% Create python object to interface to both cameras
h9isp = py.terminal.h9ispTerminal(''); % optional argument for python logger (disabled here)

%% start connection and framing
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
send(h9isp, ['start ' num2str(Cam_ID) ' ' num2str(Mode) ' 0']);

msecdelay=2000;
send(h9isp, ['msecdelay ' num2str(msecdelay)]);

% auto focus
send(h9isp, ['f ' num2str(Cam_ID)]);
pause(3);

%% start flare validation

% protrait left
Home = Move_Protrait_Left_Start_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(10);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

for i=1:90
    i
    RY=1*0.0174
    Home = [0, 0, 0, 0, -RY, 0]; %Landscape
    Pose = strcat('(1,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')');
    fprintf(t, Pose);
    pause(1);
    rec = fscanf(t,'%c',t.BytesAvailable);
    pause(0.5);
    
    % record the image sensor temperature
    temp_temp = char(send(h9isp, ['getsensortemp ' num2str(Cam_ID)]));
    sensor_temp = parseString_array_v2(temp_temp, '<temperature> ', ' </temperature>');
    
    % record the focus position
    focus_temp = char(send(h9isp, ['GetFocusPos ' num2str(Cam_ID)]));
    focus_pos =  parseString_array_v2(focus_temp, '<position> ', ' </position>');

    nameBase  = [ModuleID '_foucus_pos=' num2str(focus_pos) '_sensor_temp=' num2str(sensor_temp) '_PT_<angle>' num2str(i)];
    send(h9isp, ['namebase '  nameBase ' 0']);
    send(h9isp, ['p 1 ' num2str(Cam_ID)]);
    
    fprintf(['Take image %d\n'], i);
    pause(0.5)
    
end
pause(3)

Home = Home_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(15);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

% protrait right
Home = Move_Protrait_Right_Start_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(10);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

for i=1:90
    RY=1*0.0174;
    Home = [0, 0, 0, 0, RY, 0];
    Pose = strcat('(1,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')');
    fprintf(t, Pose);
    pause(1);
    rec = fscanf(t,'%c',t.BytesAvailable)
    pause(0.5);
    
    % record the image sensor temperature
    temp_temp = char(send(h9isp, ['getsensortemp ' num2str(Cam_ID)]));
    sensor_temp = parseString_array_v2(temp_temp, '<temperature> ', ' </temperature>');
    
    % record the focus position
    focus_temp = char(send(h9isp, ['GetFocusPos ' num2str(Cam_ID)]));
    focus_pos =  parseString_array_v2(focus_temp, '<position> ', ' </position>');

    nameBase  = [ModuleID '_foucus_pos=' num2str(focus_pos) '_sensor_temp=' num2str(sensor_temp) '_PT_<angle>' num2str(-i)];
    send(h9isp, ['namebase '  nameBase ' 0']);
    send(h9isp, ['p 1 ' num2str(Cam_ID)]);
    
    fprintf(['Take image %d\n'], i);
    pause(0.5)
    
end
pause(3)

Home = Home_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(15);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

% landscape left
Home = Move_Landscape_Left_Start_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(10);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

for i=1:90
    i
    RX=1*0.0174
    Home = [0, 0, 0, -RX, 0, 0]; %Landscape
    Pose = strcat('(1,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')');
    fprintf(t, Pose);
    pause(1);
    rec = fscanf(t,'%c',t.BytesAvailable);
    pause(0.5);
    
    % record the image sensor temperature
    temp_temp = char(send(h9isp, ['getsensortemp ' num2str(Cam_ID)]));
    sensor_temp = parseString_array_v2(temp_temp, '<temperature> ', ' </temperature>');
    
    % record the focus position
    focus_temp = char(send(h9isp, ['GetFocusPos ' num2str(Cam_ID)]));
    focus_pos =  parseString_array_v2(focus_temp, '<position> ', ' </position>');

    nameBase  = [ModuleID '_foucus_pos=' num2str(focus_pos) '_sensor_temp=' num2str(sensor_temp) '_LS_<angle>' num2str(i)];
    send(h9isp, ['namebase '  nameBase ' 0']);
    send(h9isp, ['p 1 ' num2str(Cam_ID)]);
    
    fprintf(['Take image %d\n'], i);
    pause(0.5)
    
end
pause(3)

Home = Home_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(15);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

% landscape right
Home = Move_Landscape_Right_Start_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(10);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

for i=1:90
    RX=1*0.0174;
    Home = [0, 0, 0, -RX, 0, 0];
    Pose = strcat('(1,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')');
    fprintf(t, Pose);
    pause(1);
    rec = fscanf(t,'%c',t.BytesAvailable)
    pause(0.5);
    
    % record the image sensor temperature
    temp_temp = char(send(h9isp, ['getsensortemp ' num2str(Cam_ID)]));
    sensor_temp = parseString_array_v2(temp_temp, '<temperature> ', ' </temperature>');
    
    % record the focus position
    focus_temp = char(send(h9isp, ['GetFocusPos ' num2str(Cam_ID)]));
    focus_pos =  parseString_array_v2(focus_temp, '<position> ', ' </position>');

    nameBase  = [ModuleID '_foucus_pos=' num2str(focus_pos) '_sensor_temp=' num2str(sensor_temp) '_LS_<angle>' num2str(-i)];
    send(h9isp, ['namebase '  nameBase ' 0']);
    send(h9isp, ['p 1 ' num2str(Cam_ID)]);
    
    fprintf(['Take image %d\n'], i);
    pause(0.5)
end
pause(3)

Home = Home_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(15);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

send(h9isp, 'off');
send(h9isp, 'quit');

fclose(t);
fclose(scs);
delete(t);
delete(scs)