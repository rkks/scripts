#!/usr/bin/env python3
#!/usr/bin/env python3 -dit
#  DETAILS: bash configuration to be sourced.
#  CREATED: 07/01/06 15:24:33 IST
# MODIFIED: 11/Sep/2018 17:28:32 IST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Always leave the code you're editing a little better than you found it

# Import all required modules
import struct, fcntl, glob, os, sys, signal
import argparse, pexpect, pdb, logging
import logging.handlers as hdlrs
import logging.config as config
from pexpect import pxssh

global g_logger

# global declarations. no need for %(name)s as log-name has name of script
LOG_FORMAT='%(asctime)s.%(msecs)03d :%(levelname)s %(funcName)s:%(lineno)d %(message)s'
DATE_FORMAT='%m/%d/%Y %H:%M:%S'
MAX_LOG_SIZE = 60       #10240     # 10KB
MAX_LOG_BKUP = 3

def dump_python_details():
    print ("\n", "sys.path:", sys.path)
    print ("\n", "os.__file__:", os.__file__)
    print ("\n", "sys.version:", sys.version)
    print ("\n", "sys.args:", sys.argv)

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

def check_create_path(path):
    if (os.path.exists(path)) and (not os.path.isdir(path)):
        print ("Non-directory path ", path, "already exists. Remove, retry")
        sys.exit(0)

    if (not os.path.exists(path)):
        print ("Log directory ", path, " does not exist. Create new.")
        os.mkdir(path)

def log_init(arg_log_level = "DEBUG"):
    global g_logger

    # os.environ[] array has cached/inherited values from script launch time.
    log_path = os.getenv('SCRPT_LOGS', default=os.path.join(os.getcwd(), ".logs"))
    log_level = getattr(logging, arg_log_level, logging.DEBUG)
    print ("log_path:", log_path, "log_level:", log_level)
    check_create_path(log_path)

    # aim remove .py, approach: split filename at extension and grab first half
    scrpt_name = os.path.splitext(os.path.basename(__file__))[0]
    log_file = log_path + '/' + scrpt_name + '.log'

    # Bypass basicConfig(). python supports kwargs that require keyname with value
    g_logger = logging.getLogger(scrpt_name)    # create logger. No args gives root logger
    g_logger.setLevel(logging.DEBUG)            # set log level for logger

    formats = logging.Formatter(fmt=LOG_FORMAT, datefmt=DATE_FORMAT) # create formatter

    # Instead of regular FileHandler(), create Rotating FileHandler
    filehdl = hdlrs.RotatingFileHandler(log_file, maxBytes = MAX_LOG_SIZE,
                                       backupCount = MAX_LOG_BKUP)    # create log-rotate handler
    filehdl.setLevel(logging.DEBUG)             # set log level for console

    console = logging.StreamHandler()           # create console handler
    console.setLevel(logging.ERROR)             # set log level for console

    filehdl.setFormatter(formats)               # log format for file
    console.setFormatter(formats)               # log format for console

    g_logger.addHandler(console)                # attach console handler to logger
    g_logger.addHandler(filehdl)                # attach file handler to logger

    #pdb.set_trace()
    # logging.critical() wouldn't print anything to file as it logs to root logger
    g_logger.critical("===============Init logs. path: %s=================", log_file)

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
    global args

    # Parse input arguments
    parser = argparse.ArgumentParser(usage=__doc__)

    parser.add_argument("-l", "--log", default="DEBUG",
                        help="logging level of the script")
    parser.add_argument("-m", "--method", default="ssh",
                        help="method used to connect ssh/telnet")
    parser.add_argument("-u", "--user", default="ravikks", #admin
                        help="username on switch")
    parser.add_argument("-p", "--passwd", default="$SicK$0$", #nbv_12345
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

    args = parser.parse_args()
    if (args.switch == None):
        sys.exit(1)

def connect():
    global args

    if (args.method == "ssh"):
        #spawncmd = 'ssh ' + args.user + '@' + args.switch
        spawncmd = 'ssh -l ' + args.user + ' ' + args.switch
    else:
        spawncmd = 'telnet ' + args.switch
    print (spawncmd)

    try:
        #conn = pexpect.spawn(args.method, [args.user, '@', args.switch])
        #conn = pexpect.spawn(spawncmd)
        s = pxssh.pxssh()
        s.login(args.switch, args.user, args.passwd)
        #conn = pexpect.spawn('ssh ravikks@127.0.0.1')
    except Exception as err:
        print ("Unexpected error: ", sys.exc_info()[0], type(err), err.args, err)
        sys.exit(0)

    pdb.set_trace()
    s.sendline('uptime')
    s.prompt()
    s.logout()
    sys.exit(0)

#    query = 'Are you sure you want to continue'
#    while True:
#        try:
#            index = conn.expect(['[pP]assword:', query])
#            if index == 0:
#                conn.sendline('yes')
#                continue
#            if index == 1:
#                conn.sendline(args.passwd)
#                break
#        except Exception as err:    # pexpect.EOF/EOF, pexpect.TIMEOUT/TIMEOUT
#            print "Unexpected error: ", sys.exc_info()[0], type(err), err.args, err
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
    global args
    parse_args()
    log_init(args.log.upper())          #log_conf_init()
    if (args.verbose != None) and (args.verbose >= 2):
        print ("args: ", args)
        dump_python_details()
    else:
        print ("switch: ", args.switch)
    connect()
    sys.exit(0)

# Standard boilerplate code to call main()
if __name__ == '__main__':
    main()
