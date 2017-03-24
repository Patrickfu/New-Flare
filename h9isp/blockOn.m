function blockOn(h9isp, blockString)
    n = 1;
    while n < 100 % dont let it cycle forever
        response = h9isp.read_telnet_cmd();
        if strfind(response.char, blockString) ~= 0
            h9isp.read_telnet_cmd();
            return
        end
        n = n + 1;
    end
    disp(['ERROR: Did not find string ' blockString, '.  Stopping blocking action']);

end