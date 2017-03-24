'''
nv_ctrl.py
Lucas Koerner 
May 2015
modified from Kevin Gross' camera controller for Sphere
'''

import sys
import os
import telnetlib
import subprocess
import time
import re


VERBOSE = 0

class h9ispTerminal:

    def __init__(self, *args):       
        self.tn             = None
        self.tcprelay_proc  = None
        self.user           = 'root'
        self.pwd            = 'alpine'
        self.ispName        = 'h9isp'
        self.timeOut        = 0.1
        self.tcprelay_proc  = None
        self.log = args[0]

        # Set the RSYNC_PASSWORD environment variable
        # this eliminates the need for the password.txt file (and it's 
        # associated permissions etc). 
        os.environ['RSYNC_PASSWORD'] = self.pwd

    def __del__(self):
        print "__del__"
        if not self.tcprelay_proc == None:
            print "killing tcprelay"
            self.tcprelay_proc.kill()

    def connectToDevice(self):
        # self.tcprelay_proc    = subprocess.Popen(['tcprelay','--portoffset','2000','873','23','22'],shell=True)
        self.tcprelay_proc  = subprocess.Popen(['/usr/local/bin/tcprelay', '--portoffset', '2000', '873', '23', '22'], shell=False)
        time.sleep(1.0)
        self.tn             = telnetlib.Telnet('localhost',2023)

        if self.tn:
            # LOGIN
            self.tn.read_until("login: ", self.timeOut)
            self.tn.write("root\n")

            # PASSWORD
            self.tn.read_until("Password:", self.timeOut)
            self.tn.write(self.pwd + "\n")  

            # WAIT FOR PROMPT
            # self.tn.read_until("root# ", self.timeOut)
            self.tn.read_until("# ", self.timeOut)

            print "Connected to device"
            return 1

    def send_telnet_cmd(self, cmdString):
        # print(cmdString)
        self.tn.write(cmdString + "\n")
    
    def read_telnet_cmd(self):
        ret = self.tn.read_until("-> ", self.timeOut)
        return ret
