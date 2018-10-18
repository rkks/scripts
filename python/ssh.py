#!/usr/bin/env python3
#!/usr/bin/env python3 -dit
#  DETAILS: bash configuration to be sourced.
#  CREATED: 07/01/06 15:24:33 IST
# MODIFIED: 18/Oct/2018 20:27:44 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Always leave the code you're editing a little better than you found it

# Debugging import issues
# $ python3 -m site         // place where packages are installed
# print (sys.path)          // path from where modules are picked-up
# sys.path.insert(0, "/path/to/scripts/dir")   // add module to path at runtime

# Import all required modules
import struct, fcntl, glob, time, os, sys, re, signal
import argparse, pexpect, pdb, logging, globs, utils
import logging.handlers as hdlrs
import logging.config as config
from pexpect import pxssh
from utils import Logger
from utils import SSHConnect
from utils import SCPConnect

def parse_args():
    global g_args

    # Parse input arguments
    parser = argparse.ArgumentParser(usage=__doc__)

    parser.add_argument("-l", "--log", default = "DEBUG",
                        help="logging level of the script")
    parser.add_argument("-m", "--method", default = "ssh",
                        help="method used to connect ssh/telnet")
    parser.add_argument("-u", "--user", default = None,
                        help="username on switch")
    parser.add_argument("-p", "--passwd", default = None,
                        help="password for given user")
    parser.add_argument("-o", "--port", type = int,
                        help="port number when telnet to console")
    parser.add_argument("-f", "--fpath", default = None,
                        help="file/dir path to be copied to switch (recursive)")
    parser.add_argument("-r", "--rpath", default = None,
                        help="remote path where to copy (use with -f/-d)")
    # choices=[0, 1, 2, 3, 4, 5, 6, 7] is -v=0..7, count is -v, -vv, -vvv
    parser.add_argument("-v", "--verbose", action="count",
                        help="increase script output verbosity")
    parser.add_argument("-t", "--trace", action="store_true",
                        help="enable trace mode for script")

    mandatory = parser.add_argument_group('mandatory arguments')

    mandatory.add_argument("-s", "--switch", default=None,
                        help="switch name/ip to connect")

    g_args = parser.parse_args()
    if ((g_args.switch == None) or (g_args.user == None) or
        (g_args.passwd == None)):
        print("Unknown switch IP/FQDN or username or password. Use --help")
        sys.exit(1)

def copy():
    global g_args

    recursive = True if os.path.isdir(g_args.fpath) else False
    globs.g_conn_hdl = SCPConnect(host = g_args.switch,
                                  user = g_args.user,
                                  passwd = g_args.passwd,
                                  lpath = g_args.fpath,
                                  rec = recursive,
                                  rpath = g_args.rpath)

    #print(globs.g_conn_hdl.cli_out)

def connect():
    global g_args

    #pdb.set_trace()
    globs.g_conn_hdl = SSHConnect(host = g_args.switch,
                                  user = g_args.user,
                                  passwd = g_args.passwd)
    if not globs.g_conn_hdl.is_up():
        die("Error connecting to switch %s" % (g_args.switch))

    #print(globs.g_conn_hdl.cli_out)

"""
    try:
        s = pxssh.pxssh()
        s.login(g_args.switch, g_args.user, g_args.passwd)
    except Exception as err:
        print ("Unexpected error: ", sys.exc_info()[0], type(err), err.g_args, err)
        sys.exit(0)

    s.sendline('uptime')
"""

def main():
    global g_args

    globs.init_vars(os.path.splitext(os.path.basename(__file__))[0])
    parse_args()
    #log_init(g_args.log.upper())          #log_conf_init()
    globs.g_logger = Logger(logName = globs.g_script_name)
    if (g_args.verbose != None) and (g_args.verbose >= 2):
        print ("g_args: ", g_args)
        dump_python_details()
    copy()
    connect()
    globs.g_conn_hdl.interact()         # globs.g_conn_hdl.handle.interact()
    sys.exit(0)                         # time.sleep(10)

# Standard boilerplate code to call main()
if __name__ == '__main__':
    main()
