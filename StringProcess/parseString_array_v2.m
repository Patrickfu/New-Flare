% Created by Wei Luo@ Apple Inc.
% Copyright 2017 Apple Inc. All Rights Reserved.
% 01-18-2017
% Version 1.1

function [all_values] =  parseString_array_v2(text, startPattern, endPattern)

text = char(text(:).');
%%

start_idx = strfind(text, startPattern);
end_idx = strfind(text, endPattern);

if (start_idx ~= 0 && end_idx ~= 0)
    start_idx = start_idx + length(startPattern);
    all_values = text(start_idx:end_idx-1);
    if(all_values(1) == '0' && all_values(2) == 'x')
        all_values = hex2dec(all_values(3:end));
    else
        all_values = str2num(all_values);
    end
    
        
end

end