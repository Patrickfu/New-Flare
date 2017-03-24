close all;
clear all;
clc;

SFR_Home_Joint = [4.79369e-05,-1.5708,8.39233e-05,-1.57088,-2.3667e-05,-4.79857e-05];
SFR_37cm_Joint = [1.00599,-2.18016,-1.36962,0.426723,0.556864,-1.59244];

SFR_Home_TCP = [-0.0160397,-0.215021,0.804879,-0.00614025,-2.21394,2.22317];
SFR_37cm_TCP = [0.377546,0.333056,0.368472,2.20225,0.0110629,2.23253];

%% Turning on the device terminal
% system('open -a Terminal "D11.sh"');
% pause(0.5);
% Device_log = 'Device_logs.txt';
% device_pipe = 'p_device';
% fid_device = fopen(device_pipe, 'w');
% pause(1);
% fprintf(fid_device,['mkdir SFR_Focus_Distance_Sweep \n']);
% pause(0.2);
% fprintf(fid_device,['cd SFR_Focus_Distance_Sweep \n']);
% pause(0.2);
% fprintf(fid_device,['rm *.* \n']);
% pause(0.2);
% fprintf(fid_device,['h9isp -jrx \n']);
% %fprintf(fid_device,['forget \n']);
% fprintf(fid_device,['writejpeg on \n']);
% fprintf(fid_device,['writeraw on \n']);
% fprintf(fid_device,['writemeta on \n']);
% 
% %fprintf(fid_device,['fwlog \n']);
% fprintf(fid_device,['on \n']);
% fprintf(fid_device,['start 2 121 0 \n']);
% fprintf(fid_device,['v \n']);
% fprintf(fid_device,['\n']);
% pause(5);

%% Intialize UR3
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

% create connection and Matlab is server
disp('Receiver started');
t=tcpip('192.168.1.4',30000,'NetworkRole','Server');

fprintf(scs, 'play');
pause(2);

disp('Waiting for connection');
fopen(t);
disp('connection ok');

DataReceived = fread(t,9)

fprintf(t,'(2)'); % task = 0 : reading joint position
pause(0.5);
joint_pose = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

fprintf(t,'(3)'); % task = 0 : reading tcp position
pause(0.5);
tcp_pose = fscanf(t,'%c',t.BytesAvailable)
pause(0.5);

%start to move UR3 to NH SFR 37cm
Home = SFR_Home_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(0.5);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(7);

Home = SFR_37cm_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(0.5);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(7);

%% Move the robot to 27cm
Home = [0.1, 0, 0, 0, 0, 0];    % move forward 10cm
Pose = strcat('(1,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')');
fprintf(t, Pose);
pause(0.5);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(3);

%% sweep distance from 27cm to 57cm
for i=1:20
    i
    Z = 0.01;
    % go to free drive mode and taking picture by h9isp.
    fprintf(scs,['freedrive_mode()' char(10)]);
    pause(0.5);
    
%     image_name = strcat('namebaseforchan 2 NH-D_Focus_Distance_Sweep_', num2str(i+26), 'cm');
%     fprintf(fid_device,[image_name]);
%     fprintf(fid_device,['\n']);
%     fprintf(fid_device,['p \n']);
%     pause(3);
%     
    %fprintf(scs,['end_freedrive_mode()' char(10)]);
    %pause(0.5);
    
    Home = [-Z, 0, 0, 0, 0, 0];    % move forward 10cm
    Pose = strcat('(1,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')');
    fprintf(t, Pose);
    pause(2);
    rec = fscanf(t,'%c',t.BytesAvailable)
    pause(1);
end

%% Move back to NH SFR 37cm position after sweep
Home = SFR_37cm_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(0.5);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(7);

Home = SFR_Home_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(0.5);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(7);

fprintf(scs, 'stop');
pause(2);

fclose(scs);
fclose(t);
