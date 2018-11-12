#!/usr/bin/env python3
#!/usr/bin/env python3 -dit
#  DETAILS: bash configuration to be sourced.
#  CREATED: 07/01/06 15:24:33 IST
# MODIFIED: 12/Nov/2018 19:48:44 IST
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
ppath = os.getenv('UTL_SCRPTS', default = os.getenv('HOME') + "/scripts/utils")
#print(ppath)
sys.path.insert(0, ppath + "/python")
import argparse, pexpect, pdb, logging, globs, utils
from utils import Logger
from scapy.all import*

def send_arp1():
    #ether=ETHER()
    arp=ARP()
    #ether.dst='ff:ff:ff:ff:ff:ff'
    #dst=raw_input('n enter the destination ip address=')
    dst='10.40.122.22'
    arp.op=1
    arp.pdst=dst
    #sendp(ether/arp)
    sendp(arp)

def send_arp():
    # psrc='10.161.0.10', pdst='10.40.122.22',
    results, unanswered = sr(ARP(op=ARP.who_has,
                                 psrc='10.40.122.51',
                                 pdst='10.40.122.22',
                                 hwsrc='52:54:00:36:3c:9c',
                                 hwdst='01:02:03:04:05:06'))

                                 #hwdst='a0:04:60:12:8b:c3'))
                                 #hwdst='ff:ff:ff:ff:ff:ff'))
    print(results)

def send_icmp():
    # psrc='10.161.0.10', pdst='10.40.122.22',
    results, unanswered = sr(Ether(dst='ff:ff:ff:ff:ff:ff')/IP(dst='10.40.122.22')/ICMP())

    print(results)

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
    #if ((g_args.switch == None) or (g_args.user == None) or
    #    (g_args.passwd == None)):
    #    print("Unknown switch IP/FQDN or username or password. Use --help")
    #    sys.exit(1)

def main():
    global g_args

    globs.init_vars(os.path.splitext(os.path.basename(__file__))[0])
    #log_init(g_args.log.upper())          #log_conf_init()
    globs.g_logger = Logger(logName = globs.g_script_name)
    parse_args()
    if (g_args.verbose != None) and (g_args.verbose >= 2):
        print ("g_args: ", g_args)
        dump_python_details()

    print ("send arp")
    #send_arp()
    send_icmp()
    sys.exit(0)

# Standard boilerplate code to call main()
if __name__ == '__main__':
    main()
