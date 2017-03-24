close all;
clear all;
clc;

LED_Home_Joint = [4.79369e-05,-1.5708,8.39233e-05,-1.57088,-2.3667e-05,-4.79857e-05];
LED_RCAM_Joint = [-1.40679,-0.192235,-1.93428,0.54352,1.56939,-0.162747];
LED_FCAM_Joint = [-1.4651,-1.3836,0.552169,-0.7519,-1.5672,0.103999];

LED_Home_TCP = [-0.0160397,-0.215021,0.804879,-0.00614025,-2.21394,2.22317];
LED_RCAM_TCP = [-0.157577,0.299518,0.488466,0.0157378,-0.0178552,3.13746];
LED_RCAM_TCP = [-0.124452,0.372203,0.446455,-3.13005,0.00504609,0.00861806];

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

% Home = LED_Home_Joint;
% Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
% fprintf(t, Pose);
% pause(0.5);
% rec = fscanf(t,'%c',t.BytesAvailable)
% pause(7);

Home = LED_RCAM_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(0.5);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(7);

for j=1:7
        if mod(j,2) == 0
            Y = -0.09;
        else
            Y = 0.09;
        end
        % go to free drive mode and taking picture by h9isp.
        %fprintf(scs,['freedrive_mode()' char(10)]);
        %pause(0.5);
    
        %image_name = strcat('namebaseforchan 2 NH-D_Focus_Distance_Sweep_', num2str(i+26), 'cm');
        %fprintf(fid_device,[image_name]);
        %fprintf(fid_device,['\n']);
        %fprintf(fid_device,['p \n']);
        %pause(3);
     
        %fprintf(scs,['end_freedrive_mode()' char(10)]);
        %pause(0.5);
    
        Home = [0, Y, 0, 0, 0, 0];    % move forward 10cm
        Pose = strcat('(1,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')');
        fprintf(t, Pose);
        pause(1);
        fprintf(t,['freedrive_mode()' char(10)]);
        pause(0.5);
        rec = fscanf(t,'%c',t.BytesAvailable)
        pause(0.5);
    
    Home = [-0.01, 0, 0, 0, 0, 0];    % move forward 10cm
    Pose = strcat('(1,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')');
    fprintf(t, Pose);
    pause(2);
    fprintf(t,['freedrive_mode()' char(10)]);
    pause(0.5);
    rec = fscanf(t,'%c',t.BytesAvailable)
    pause(0.5);
end

Home = LED_FCAM_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(0.5);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(7);

for j=1:13
        if mod(j,2) == 0
            Y = 0.055;
        else
            Y = -0.055;
        end
        % go to free drive mode and taking picture by h9isp.
        %fprintf(scs,['freedrive_mode()' char(10)]);
        %pause(0.5);
    
        %image_name = strcat('namebaseforchan 2 NH-D_Focus_Distance_Sweep_', num2str(i+26), 'cm');
        %fprintf(fid_device,[image_name]);
        %fprintf(fid_device,['\n']);
        %fprintf(fid_device,['p \n']);
        %pause(3);
     
        %fprintf(scs,['end_freedrive_mode()' char(10)]);
        %pause(0.5);
    
        Home = [0, Y, 0, 0, 0, 0];    % move forward 10cm
        Pose = strcat('(1,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')');
        fprintf(t, Pose);
        pause(1);
        fprintf(t,['freedrive_mode()' char(10)]);
        pause(0.5);
        rec = fscanf(t,'%c',t.BytesAvailable)
        pause(0.5);
   
    Home = [-0.003, 0, 0, 0, 0, 0];    % move forward 10cm
    Pose = strcat('(1,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')');
    fprintf(t, Pose);
    pause(2);
    fprintf(t,['freedrive_mode()' char(10)]);
    pause(0.5);
    rec = fscanf(t,'%c',t.BytesAvailable)
    pause(0.5);
end

Home = LED_Home_Joint;
Pose = strcat('(0,', num2str(Home(1), '%f'), ', ',num2str(Home(2), '%f'), ', ',num2str(Home(3), '%f'), ', ',num2str(Home(4), '%f'), ', ',num2str(Home(5), '%f'), ', ',num2str(Home(6), '%f'),')')
fprintf(t, Pose);
pause(0.5);
rec = fscanf(t,'%c',t.BytesAvailable)
pause(7);

fprintf(scs, 'stop');
pause(2);

fclose(scs);
fclose(t);
