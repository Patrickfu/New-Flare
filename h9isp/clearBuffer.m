function clearBuffer(h9isp)
    n = 1;
    while n < 200 % don't let cycle more than 100x
        response = h9isp.read_telnet_cmd();
        if isempty(response.char)
            return;
        end
        n = n +1;
    end
    disp('ERROR: Buffer not cleared');

end
