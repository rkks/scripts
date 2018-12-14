#!/usr/bin/env python3
#!/usr/bin/env python3 -dit
#  DETAILS: bash configuration to be sourced.
#  CREATED: 07/01/06 15:24:33 IST
# MODIFIED: 13/Nov/2018 21:12:27 PST
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2013, Ravikiran K.S.

# Always leave the code you're editing a little better than you found it
#https://stackoverflow.com/questions/26274524/sending-icmp-packets-in-scapy-and-choosing-the-correct-interface

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

def send_icmp_hello():
    results, unanswered = sr(IP(dst="10.40.122.22-23")/ICMP()/"Hello World")

    print(results)

def send_icmp():
    #results, unanswered = sr(Ether(dst='ff:ff:ff:ff:ff:ff')/IP(dst='10.40.122.22')/ICMP()) # malformed packet
    eth = Ether(src="52:54:00:36:3c:9c", dst="01:18:02:0a:0b:0c")
    ip = IP(dst="10.40.122.22")                # optional: src="10.40.122.51"
    pkt = eth/ip/ICMP()
    #results = sr1(pkt)          # does not work, malformed pkts. same for sr()
    #results = sendp(pkt)        # works (send only, no wait for rx), but storm of replies

    # The reason why packets crafted with sr()/sr1() result in malformed frames
    # is that sr() sends and receives packets at Layer 3 using conf.L3socket.
    # Whereas, srp() works at Layer 2 using conf.L2socket. Even though this does
    # work, it can't be used as it creates ICMP request/reply storm in network.
    # Because dest has no way of figuring out if ICMP req is a dup and eth-bcast
    # dmac leads to replication of requests within bcast domain
    results, unanswered = srp(pkt)  # works both send+recv, but storm of replies

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
    send_icmp_hello()
    sys.exit(0)

# Standard boilerplate code to call main()
if __name__ == '__main__':
    main()
