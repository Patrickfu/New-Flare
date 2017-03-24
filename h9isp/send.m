
function [response, sent] = send(h9isp, command, readflag)

    if(nargin<3)
    	readflag = 1;
    end

    if(readflag > 0)
    	clearBuffer(h9isp);
	end

    h9isp.send_telnet_cmd(command);

    sent = command;

    if(readflag > 0)
    	response = h9isp.read_telnet_cmd(); % make sure buffer is empty
    else
    	response = '';
	end
end

