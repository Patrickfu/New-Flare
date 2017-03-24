% Created by Wei Luo@ Apple Inc.
% Copyright 2016 Apple Inc. All Rights Reserved.
% 06-02-2016
% Version 1.0

function [ files ] = FileTransfer( bufferFolder, filekeyword, removeFile )
    %FILETRANSFER Summary of this function goes here
    %   Detailed explanation goes here
    
    
    filename = 'DataTransfer.txt';

    if(exist(bufferFolder, 'dir')==0)
        mkdir(bufferFolder);
    end

    if(nargin<3)
        removeFile = 0;
    end
    
    % check if the file exist, if no, create one
    wrtiteType = 'w';
    fileID = fopen([bufferFolder filename], wrtiteType); % a+: Open or create new file for reading and writing. Append data to the end of the file;  w: Open or create new file for writing. Discard existing contents, if any.


    
    if(removeFile>0)
        fprintf(fileID, ['spawn rsync --remove-source-files rsync://root@localhost:10873/root/var/root/' filekeyword ' ' bufferFolder '\n']); % --remove-source-files
    else
        fprintf(fileID, ['spawn rsync rsync://root@localhost:10873/root/var/root/' filekeyword ' ' bufferFolder '\n']);    
    end
    fprintf(fileID, 'expect "Password:"\n');
    fprintf(fileID, 'send "alpine\\n"\n');
    fprintf(fileID, 'interact\n');    
    
    fclose(fileID);


    %% call the system command to execute the code
    shellCommand = ['expect ' bufferFolder filename];
    [status, cmdout] = system(shellCommand);

    files = dir([bufferFolder filekeyword]);
    cc = cellstr([{files(:).name}]);
    [cs,index] = sort_nat(cc,'ascend');
    files = files(index);   % now the files are sorted by name
    
end

