% Created by Wei Luo@ Apple Inc.
% Copyright 2016 Apple Inc. All Rights Reserved.
% 04-12-2016
% Version 1.0

% this function crops out the sub string between two sub strings specified by the two variables: left_str and right_str

function [output_str, left_str_idx, right_str_idx] = stripString(orignal_str, left_str, right_str)

	temp_idx = strfind(orignal_str, left_str);
    
    if(isempty(temp_idx)==1)
        output_str = '';
        left_str_idx = NaN;
        right_str_idx = NaN;
        return;
    else
        temp_idx = temp_idx(1);
    end
    
    left_str_idx = temp_idx;
    
	temp_idx2 = strfind(orignal_str, right_str);
	
    temp_idx2 = temp_idx2((temp_idx2>temp_idx));
%     temp_idx2 = temp_idx2(1);
    
    if(isempty(temp_idx2) == 0)&&(isempty(temp_idx)==0)
        temp_idx = temp_idx(1);
        temp_idx2 = temp_idx2(1);
        right_str_idx = temp_idx2;
        if(temp_idx2 > temp_idx)
            output_str = orignal_str((temp_idx+length(left_str)):(temp_idx2-1));
        else
            output_str = [];
        end
    else
        right_str_idx = NaN;
        output_str = [];
    end
    
    

end