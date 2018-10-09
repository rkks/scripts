#!/usr/bin/env python3
#!/usr/bin/env python3 -dit
#  DETAILS: bash configuration to be sourced.
#  CREATED: 07/01/06 15:24:33 IST
# MODIFIED: 08/Oct/2018 20:24:37 IST
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
from utils import SwitchConnect

#global g_logger

def sigwinch_passthrough (sig, data):
    # Check for buggy platforms (see pexpect.setwinsize()).
    if 'TIOCGWINSZ' in dir(termios):
        TIOCGWINSZ = termios.TIOCGWINSZ
    else:
        TIOCGWINSZ = 1074295912 # assume
    s = struct.pack ("HHHH", 0, 0, 0, 0)
    a = struct.unpack ('HHHH', fcntl.ioctl(sys.stdout.fileno(), TIOCGWINSZ , s))
    global global_pexpect_instance
    global_pexpect_instance.setwinsize(a[0],a[1])

def log_conf_init():
    conf_path = os.getenv('CUST_CONFS', default=os.getcwd()) + "/logging.conf"
    print ("conf_path: ", conf_path)
    if (not os.path.exists(conf_path)):
        print ("conf file not found. exit")
        sys.exit(0)
    config.fileConfig(conf_path)        # read from log-file conf
    g_logger = logging.getLogger('genericLogger')
    g_logger.log(logging.CRITICAL, "===============Init logs. path: %s=================", conf_path)

def parse_args():
    global g_args

    # Parse input arguments
    parser = argparse.ArgumentParser(usage=__doc__)

    parser.add_argument("-l", "--log", default="DEBUG",
                        help="logging level of the script")
    parser.add_argument("-m", "--method", default="ssh",
                        help="method used to connect ssh/telnet")
    parser.add_argument("-u", "--user", default=None,
                        help="username on switch")
    parser.add_argument("-p", "--passwd", default=None,
                        help="password for given user")
    parser.add_argument("-o", "--port", type=int,
                        help="port number when telnet to console")
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

def connect():
    global g_args

    globs.g_conn_hdl = SwitchConnect(host = g_args.switch,
                                     user = g_args.user,
                                     passwd = g_args.passwd)
    if not globs.g_conn_hdl.is_up():
        die("Error connecting to switch %s" % (g_args.switch))

    globs.g_conn_hdl.send_exp('ls -l')
    #print(globs.g_conn_hdl.cli_out)
    #globs.g_conn_hdl.handle.interact()
    #time.sleep(10)
    sys.exit(0)
""""
    if (g_args.method == "ssh"):
        #spawncmd = 'ssh ' + g_args.user + '@' + g_args.switch
        spawncmd = 'ssh -l ' + g_args.user + ' ' + g_args.switch
    else:
        spawncmd = 'telnet ' + g_args.switch
    print (spawncmd)

    try:
        #conn = pexpect.spawn(g_args.method, [g_args.user, '@', g_args.switch])
        #conn = pexpect.spawn(spawncmd)
        s = pxssh.pxssh()
        s.login(g_args.switch, g_args.user, g_args.passwd)
        #conn = pexpect.spawn('ssh ravikks@127.0.0.1')
    except Exception as err:
        print ("Unexpected error: ", sys.exc_info()[0], type(err), err.g_args, err)
        sys.exit(0)

    pdb.set_trace()
    s.sendline('uptime')
    s.prompt()
    s.logout()
"""

#    query = 'Are you sure you want to continue'
#    while True:
#        try:
#            index = conn.expect(['[pP]assword:', query])
#            if index == 0:
#                conn.sendline('yes')
#                continue
#            if index == 1:
#                conn.sendline(g_args.passwd)
#                break
#        except Exception as err:    # pexpect.EOF/EOF, pexpect.TIMEOUT/TIMEOUT
#            print "Unexpected error: ", sys.exc_info()[0], type(err), err.g_args, err
#            sys.exit(1)
#
#    conn.sendline("\r")
#    global global_pexpect_instance
#    global_pexpect_instance = conn
#    signal.signal(signal.SIGWINCH, sigwinch_passthrough)
#    try:
#        conn.interact()
#        sys.exit(0)
#    except:
#        sys.exit(1)

def main():
    global g_args

    globs.init_vars(os.path.splitext(os.path.basename(__file__))[0])
    parse_args()
    #log_init(g_args.log.upper())          #log_conf_init()
    globs.g_logger = Logger(logName = globs.g_script_name)
    if (g_args.verbose != None) and (g_args.verbose >= 2):
        print ("g_args: ", g_args)
        dump_python_details()
    connect()
    sys.exit(0)

# Standard boilerplate code to call main()
if __name__ == '__main__':
    main()
