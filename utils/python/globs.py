#!/usr/bin/python

import struct, fcntl, glob, time, sys, os, re, signal

def dump_python_details():
    print ("\n", "sys.path:", sys.path)
    print ("\n", "os.__file__:", os.__file__)
    print ("\n", "sys.version:", sys.version)
    print ("\n", "sys.args:", sys.argv)

def die(msg):
    print(msg)
    sys.exit(1)

def create_path(path, isdir=None):
    if (os.path.exists(path)):
        if isdir and (not os.path.isdir(path)):
            print ("Non-directory path ", path, "exists. Remove & retry")
            return False

        if not isdir and (not os.path.isfile(path)):
            print ("Non-file path ", path, "exists. Remove & retry")
            return False

        #print ("Path " + path + " already exists")
        return True

    if (isdir):
        print ("Directory ", path, " does not exist. Create new.")
        os.mkdir(path)
    else:
        print ("File ", path, " does not exist. Create new.")
        os.mkfile(path)

# global declarations.
def init_vars(script_name):
    global g_script_name
    global g_args
    global g_logger
    global g_conn_hdl
    global g_log_msg_fmt
    global g_log_date_fmt
    global g_log_max_sz
    global g_log_bkup_cnt

    # no need for %(name)s as log-name has name of script
    g_script_name = script_name if script_name != None else os.path.splitext(os.path.basename(__file__))[0]
    g_log_msg_fmt = '%(asctime)s.%(msecs)03d (%(threadName)-10s) %(funcName)s:%(lineno)d %(levelname)s %(message)s'
    g_log_date_fmt = '%m/%d/%Y %H:%M:%S'            # '%m/%d/%Y %I:%M:%S %p'
    g_log_max_sz = 10240                            # 10KB
    g_log_bkup_cnt = 1
    #print("Global variables initialized")
