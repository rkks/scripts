#!/usr/bin/python

__author__ = 'Ravikiran KS'

import struct, fcntl, glob, time, sys, os, re, signal
import argparse, pexpect, pdb, logging, globs
#import paramiko
#from pexpect import pxssh
import logging.handlers as handlers
import logging.config as config

"""
Access logger APIs as below
self.logger.info(" " + str(line))  # self.logger.log(logging.INFO, *)
self.logger.warn(line)             # self.logger.log(logging.WARNING, *)
self.logger.error(str(line))       # self.logger.log(logging.ERROR, *)
self.logger.debug(line)            # self.logger.log(logging.DEBUG, *)
"""
class Logger():
    def __init__(self, logName = None, logLvl = logging.INFO, toFile = False,
                 ttyLvl = logging.DEBUG):
        self.logPath = os.getenv('SCRPT_LOGS',
                                 default=os.path.join(os.getcwd()))
        globs.create_path(self.logPath, True)
        if logName == None:
            logName = globs.g_script_name

        #conf_path = os.getenv('CUST_CONFS', default=os.getcwd()) + "/log.conf"
        #print ("conf_path: ", conf_path)
        #if (not os.path.exists(conf_path)):
        #    print ("conf file not found. exit")
        #    sys.exit(0)
        #config.fileConfig(conf_path)        # read from log-file conf

        logFile = self.logPath + '/' + logName + '.log'
        self.logger = logging.getLogger(logName)
        self.logger.setLevel(logLvl)
        #print ("logFile:", logFile, "logLvl:", logLvl)

        try:
            self.logFmt = logging.Formatter(fmt = globs.g_log_msg_fmt,
                                               datefmt = globs.g_log_date_fmt)
            self.nilFmt = logging.Formatter(fmt = '')

            if toFile is True:
                self.fileHdl = self.create_loghandler(logLvl, logFile)
                self.logger.addHandler(self.fileHdl)

            self.ttyHdl = self.create_loghandler(ttyLvl) # create console logger
            self.logger.addHandler(self.ttyHdl)
            #self.nilHdl = self.create_loghandler(ttyLvl, fmt = '')

            self.create_aliases()
            self.info("Logger configured")          # same as self.logger.info
            #pdb.set_trace()
        except Exception as e:
            print ("ERR: Exception while adding log handlers" + str(e))
            exit(0)
        # logging.critical() wouldn't write anything as it logs to root logger.
        # Whereas the named logger is what is initialised
        #g_logger.critical("===========Init logs. path: %s=============log_file)

    def create_loghandler(self, lvl = logging.DEBUG, log = None, fmt = None):
        if (log):   # file log handler
            # Instead of regular FileHandler(), create Rotating FileHandler
            hdl = handlers.RotatingFileHandler(log,
                                               maxBytes=globs.g_log_max_sz,
                                               backupCount=globs.g_log_bkup_cnt)
        else:           # console log handler
            hdl = logging.StreamHandler()

        fmtr = self.logFmt if fmt is None else fmt
        hdl.setFormatter(fmtr)
        hdl.setLevel(lvl)
        return hdl

    def create_aliases(self):
        # short-hand for access of logger APIs. With this, does not matter
        # whether others use g_logger.logger or g_logger itself for APIs.
        self.info = self.logger.info
        self.error = self.logger.error
        self.warning = self.logger.warning
        self.debug = self.logger.debug
        self.critical = self.logger.critical

    def set_log_lvl(self, lvl = logging.DEBUG, is_tty = False):
        if is_tty is False:
            self.fileHdl.setLevel(lvl)
        else:
            self.ttyHdl.setLevel(lvl)

    def new_line(self, nlines = 1):
        self.ttyHdl.setFormatter(self.nilFmt)
        for i in range(nlines):
            self.critical('')
        self.ttyHdl.setFormatter(self.logFmt)

class SSHConnect():
    def __init__(self, host, user = 'admin', passwd = None, method = None,
                 port = None, timeout = 1500, retry = 2, logger = None):
        self.host = host
        self.user = user
        self.passwd = passwd
        self.handle = None
        self.timeout = timeout
        self.retry = retry
        self.method = 'ssh' if method is None else method
        self.port = 22 if port is None else port
        self.vsh_prompt = ".*[>|%]"
        self.prompt = "@.*[\$|\#]"
        # self.logger = globs.g_logger works due to aliases in Logger
        self.logger = logger if logger != None else globs.g_logger
        self.connect()      # no explicit call to connect()

    def connect(self, cmd = None):
        if cmd is None:
            # 'ssh %s@%s' also works, but below one works for both telnet, ssh
            cmd = '%s -l %s %s' % (self.method, self.user, self.host)
            if self.method == 'ssh':
                cmd += ' -p'
            cmd += ' %s' % (self.port)
        self.logger.info("Attempt to run cmd: " + cmd)

        try:
            self.last_cmd = cmd
            self.handle = pexpect.spawn(cmd, timeout = self.timeout,
                                        maxread = 65535, echo = False,
                                        logfile = sys.stdout.buffer)
            #self.handle.logfile = open(globs.g_script_name + ".log", "w")
        except Exception as e:
            self.logger.error("Error " + e + " connecting to host " + self.host)
            return False

        ret = self.expect()
        msg = 'successful' if ret is True else 'failed'
        self.logger.info("Running above cmd %s " % (msg))
        return ret

    def is_up(self):
        if self.handle is None:
            return False
        return True

    def expect(self, expr = None, isvsh = False, no = False):
        cprompt = self.prompt if isvsh is False else self.vsh_prompt
        pats = [pexpect.TIMEOUT, cprompt, '[\(|\[]*[Y|y]es[/|,][N|n]o[\)|\]]*',
                '[P|p]assword:', pexpect.EOF, 'admin:']
        if expr is not None:
            pats.append(expr)

#        if isvsh is True:
#            pats.append()

        self.last_expr = pats
        self.logger.new_line()
        self.logger.debug("Expect: %s" % (str(pats)[1:-1]))

        while True:
            idx = self.handle.expect(pats, timeout = self.timeout)
            if idx == 0:  # timeout
                self.exp_out = str(self.handle.after)
                self.logger.new_line()
                self.logger.info("expect timeout for cmd %s on host %s" %
                                    (self.last_cmd, self.host))
                return False

            elif idx == 1:  # prompt received
                self.cli_out = str(self.handle.after)
                self.logger.new_line()
                self.logger.debug("Bash prompt seen on host " + self.host)
                if expr is None:
                    return True
                continue

            elif idx == 2:  # yes/no question
                self.logger.new_line()
                self.logger.debug("Yes/No prompt seen on host " + self.host)
                ans = 'no' if no is True else 'yes'
                if self.send_line(ans) is False:
                    return False
                continue

            elif idx == 3 or idx == 5:  # passwd prompt
                self.logger.new_line()
                self.logger.debug("Pass prompt seen on host " + self.host)
                if self.send_line(self.passwd) == False:
                    return False
                continue

            elif idx == 4:  # EOF reached, spawned process has died
                self.logger.new_line()
                self.logger.debug("EOF reached on ssh to host " + self.host)
                return True

            else:
                if (idx == 6) and (expr is not None):  # input pattern
                    self.cli_out = str(self.handle.after)
                    self.logger.new_line()
                    self.logger.debug("Pattern %s seen on host %s" %
                                    (expr, self.host))
                    return True
                else:
                    self.cli_out = str(self.handle.before)
                    self.exp_out = str(self.handle.after)
                    self.logger.new_line()
                    self.logger.info("Unknown error for cmd %s on host %s" %
                                    (cmd, self.host))
                    return False

        return True

    def send_line(self, cmd):
        self.last_cmd = cmd
        self.logger.new_line()
        self.logger.info("Execute: %s" % (cmd))
        self.handle.before = ''
        self.handle.after = ''
        self.cli_out = ''
        try:
            self.handle.sendline(cmd)
        except Exception as e:
            self.logger.info("Exception" + e + "seen for sendline of" + cmd +
                             " on host" + self.host)
            return False

        return True

    def send_exp(self, cmd, expr = None, isvsh = False):
        self.send_line(cmd)
        # expect() does job of self.handle.read() and more
        self.expect(expr = expr, isvsh = isvsh)
        tstr = '%s %s' % (self.handle.before, self.handle.after)
        #self.logger.debug("%s" % (tstr))           # print() is primitive
        return True

    def interact(self):
        #signal.signal(signal.SIGWINCH, globs.sigwinch_passthrough)
        try:
            self.handle.interact()
            sys.exit(0)             # pass control to user and exit script now
        except:
            sys.exit(1)

class SCPConnect(SSHConnect):
    def __init__(self, host, lpath, rec = False, rpath = None, user = 'admin',
                 passwd = None, logger = None):
        self.lpath = lpath
        self.rpath = rpath
        self.recursive = rec
        super(SCPConnect, self).__init__(host, user = user, passwd = passwd,
                                         timeout = 500)

    def connect(self, c = None):
        cmd = 'scp'
        if self.recursive is True:
            cmd += ' -r'
        cmd += ' %s %s@%s:' % (self.lpath, self.user, self.host)
        if self.rpath is True:
            cmd += '%s' % (self.rpath)
        return super(SCPConnect, self).connect(cmd)

'''
~/ws/repos/test-automation/versaQaAutomation/library/vmConnection/connect.py
class ParamikoConnect(SwitchConnect):
    def connect(self):
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            self.ssh.connect(hostname = self.host,
                             port = self.port,
                             username = self.user,
                             password = self.passwd)
            self.handle = self.ssh.get_transport()
            self.handle.use_compression(True)
            self.logger.info('ssh successful to %s@%s:%d' % (self.user,
                                                             self.host,
                                                             self.port))
        except Exception as e:
            self.handle = None
            self.logger.error("Error " + e + " connecting to host " + self.host)
            return False

        return True

    def send_expect(self, cmd, exp = None):
        return False
        if self.handle is None:
            self.logger.info('no ssh session to %s@%s:%d' % (self.user,
                                                             self.host,
                                                             self.port))
            return False

        sess = self.handle.open_session()
        sess.set_combine_stderr(True)       # stdout + stderr
        sess.get_pty()
        print(cmd, sess)
        stdin, stdout = sess.exec_command(cmd)
        for line in stdout.readlines():
            print(line.strip())
'''
'''
            prompt = self.root_prompt if self.user == 'root' else self.prompt

            #idx = self.handle.expect(['yes/no', '[P|p]assword:', prompt,
            idx = self.handle.expect(['[\(|\[]*[Y|y]es[/|,][N|n]o[\)|\]]*',
                                      '[P|p]assword:', prompt,
                                      pexpect.TIMEOUT], timeout = self.timeout)
            if idx == 0:  # no public key, accept
                self.handle.sendline('yes')
                self.logger.info("Found yes prompt for host " + self.host)
                #print self.handle.before() + self.handle.after()
                self.handle.expect('[P|p]assword:')
                self.handle.sendline(self.passwd)
                self.handle.expect(prompt)
            elif idx == 1:  # passwd prompt
                self.handle.sendline(self.passwd)
                self.handle.expect(prompt)
            elif idx == 2:  # prompt received
                self.logger.debug("Bash prompt seen on host " + self.host)
            elif idx == 3:  # timeout
                self.logger.info("SSH login timedout for host " + self.host)
            else:
                self.logger.info("Unknown error during SSH login to host " +
                                 self.host)

            self.logger.info("SSH login successful to host " + self.host)
'''
