%% getFiles
% Gets files from device to local machine
%
% INPUTS:
% portNum				 - (integer) port number of device e.g. 11000
% localDirectoryPath	 - (string) path of your local directory that you want files to be transferred to e.g. './sample-data/'
% fileExtension          - (string) type of file extension as String e.g. '.log' or '.jpg'
%
function getFiles(varargin)

if nargin < 2 || nargin > 3
    disp('GETFILES: Wrong specification of input arguments; No files transferring!')
    return;
end

fileName = [];
fileExtension = [];

if nargin == 2
    portNum = 2000;  % hard-coded port number in python script
    localDirectoryPath = varargin{1};
    fileName = varargin{2};
    
else  % original implementation of getFiles function
    portNum = varargin{1};
    localDirectoryPath = varargin{2};
    fileExtension = varargin{3};
end

if(exist('localDirectoryPath', 'dir')==0)
    mkdir(localDirectoryPath);
end

telnetPort = portNum + 873;

if ~isempty(fileName)
    command = [sprintf('RSYNC_PASSWORD=alpine rsync -Pav rsync://root@localhost:%d', telnetPort), '/root/var/mobile/', fileName, ' ', localDirectoryPath];
    [status,cmdout] = system(command);
elseif ~isempty(fileExtension)
    command = [sprintf('RSYNC_PASSWORD=alpine rsync -Pav rsync://root@localhost:%d', telnetPort), '/root/var/mobile/*', fileExtension, ' ', localDirectoryPath];
    [status,cmdout] = system(command);
else
    disp('GETFILES: Couldn''t find files.  Nothing copied!');
end
end