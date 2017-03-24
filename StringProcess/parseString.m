% Created by Wei Luo@ Apple Inc.
% Copyright 2016 Apple Inc. All Rights Reserved.
% 07-07-2016
% Version 1.1

function [all_values, num_values, start_idx] =  parseString(text, startPattern, endPattern)

% fileDir = '/Users/weiluo/Documents/Data/20160525_h9fsweep/Dual_Cam_forwardscan_5/';
% FileName = 'cmdout.txt';
%%
% startPattern = '<efl (mm)>';
% endPattern = '</efl (mm)>';

start_idx = strfind(text(:).', startPattern);
end_idx = strfind(text(:).', endPattern);


num_values = numel(start_idx);
all_values = zeros(1, num_values);
for value_idx = 1:num_values
    m_value = (text((start_idx(value_idx) + length(startPattern)):(end_idx(value_idx)-1)));
    temp = str2num(m_value);
    if(isempty(temp)==1)
        warning('Invalid string!, using NaN...');
        all_values(value_idx) = NaN;
    else
        all_values(value_idx) = temp;
    end
end

end