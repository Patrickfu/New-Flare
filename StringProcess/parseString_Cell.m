% Created by Wei Luo@ Apple Inc.
% Copyright 2016 Apple Inc. All Rights Reserved.
% 07-07-2016
% Version 1.1

function [all_values, num_values, start_idx, text] =  parseString_Cell(text, startPattern, endPattern)

% fileDir = '/Users/weiluo/Documents/Data/20160525_h9fsweep/Dual_Cam_forwardscan_5/';
% FileName = 'cmdout.txt';
%%
% startPattern = '<efl (mm)>';
% endPattern = '</efl (mm)>';

text = char(text(:).');
%%
% startPattern = '<efl (mm)>';
% endPattern = '</efl (mm)>';

start_idx = strfind(text, startPattern);
end_idx = strfind(text, endPattern);

num_values = min([numel(start_idx) numel(end_idx)]);
all_values = zeros(1, num_values);
for value_idx = 1:num_values
    temp_start = start_idx(value_idx);
    min_end = start_idx(value_idx) + length(startPattern);
    temp_end = min(end_idx(end_idx>=min_end));
    
    if(isempty(temp_end) == 0)
        m_value = text(temp_start:temp_end);
        if(value_idx == 1)
            all_values = {m_value};
        else
            all_values{value_idx} = m_value;
        end
    end
end

num_values = numel(all_values);

end