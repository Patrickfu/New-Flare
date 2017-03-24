
function response = readh9(h9isp)
%     clearBuffer(h9isp);
%     h9isp.send_telnet_cmd(command);
    response = h9isp.read_telnet_cmd(); % make sure buffer is empty
end

