% Created by Wei Luo@ Apple Inc.
% Copyright 2016 Apple Inc. All Rights Reserved.
% 07-11-2016
% Version 1.0

function [section] = grabSections(original, start_pattern, start_pattern_idx, end_pattern, end_pattern_idx, end_symbol, end_symbol_idx)
% 	
% 	original: the original string
% 	start_pattern: the starting substring of the desired section
% 	start_pattern_idx: if there are multiple match for the start_pattern, which substring the user needs
% 	Notice that using the negative value means get the Nth from the end
% 	end_pattern: the ending substring of the desired section
% 	end_pattern_idx: if there are multiple match for the end_pattern, which substring the user needs
% 	end_symbol: the last character that needs to be cropped from the original string 

% Example:
% 	original = 'abc abcajkhfaiufhaief hahaha ccv b';
% 	start_pattern = 'abc';
% 	start_pattern_idx = -1; % --> find the last 'abc'
% 	end_pattern = 'ha';
% 	end_pattern_idx = 1; % find the first 'ha'
% 	end_symbol = ' ';
% 	end_symbol_idx = 2;
    section = [];

	start_idx = strfind(original, start_pattern);
    if(isempty(start_idx))
        section = [];
		return;
    end
    
	if(start_pattern_idx>0)
		select_idx = start_pattern_idx;
	else
		select_idx = length(start_idx) + start_pattern_idx + 1;
	end

	if(select_idx<1) || (select_idx>length(start_idx))
		warning('Index out of range: check start_pattern_idx')
		section = [];
		return;
	else
		cut_start_idx = start_idx(select_idx);
	end



	end_idx = strfind(original, end_pattern);
    if(isempty(end_idx))
        section = [];
		return;
    end
    
	if(end_pattern_idx>0)
		select_idx = end_pattern_idx;
	else
		select_idx = length(end_idx) + end_pattern_idx + 1;
	end

	if(select_idx<1) || (select_idx>length(end_idx))
		warning('Index out of range: check end_pattern_idx')
		section = [];
		return;
	else
		end_pattern_idx = end_idx(select_idx);
	end

	% search for the last symbol we need to cut
	all_end_symbol_idx = strfind(original, end_symbol);
    if(isempty(all_end_symbol_idx))
        section = [];
		return;
    end
    
	all_end_symbol_idx = all_end_symbol_idx(all_end_symbol_idx>=end_pattern_idx);
    if(isempty(all_end_symbol_idx))
        section = [];
		return;
    end
    
	if(end_symbol_idx>0)
		select_idx = end_symbol_idx;
	else
		select_idx = length(all_end_symbol_idx) + end_symbol_idx + 1;
	end

	if(select_idx<1) || (select_idx>length(all_end_symbol_idx))
		warning('Index out of range: check end_symbol_idx');
		section = [];
		return;
	else
		cut_end_idx = all_end_symbol_idx(select_idx) + length(end_symbol) - 1;
    end
    
    if(cut_start_idx<=cut_end_idx)
        section = original(cut_start_idx:cut_end_idx);
    end

end