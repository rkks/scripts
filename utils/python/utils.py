#!/usr/bin/python

__author__ = 'Ravikiran KS'

import struct, fcntl, glob, time, sys, os, re, signal
import argparse, pexpect, pdb, logging, globs, paramiko
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
    def __init__(self, logName = None, logLvl = logging.DEBUG, toFile = False,
                 ttyLvl = logging.DEBUG):
        self.logPath = os.getenv('SCRPT_LOGS',
                                 default=os.path.join(os.getcwd()))
        globs.create_path(self.logPath, True)
        if logName == None:
            logName = globs.g_script_name

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
        # logging.critical() would not print anything to file as it logs to the
        # root logger. Whereas the named logger is what is initialised
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
        #self.logger.removeHandler(self.ttyHdl)
        #self.logger.addHandler(self.nilHdl)
        self.ttyHdl.setFormatter(self.nilFmt)
        for i in range(nlines):
            self.critical('')
        self.ttyHdl.setFormatter(self.logFmt)
        #self.logger.removeHandler(self.nilHdl)
        #self.logger.addHandler(self.ttyHdl)

class SwitchConnect():
    def __init__(self, host = None, user = 'admin', passwd = None,
                 timeout = 15, retry = 2, logger = None):
        self.host = host
        self.user = user
        self.passwd = passwd
        self.handle = None
        self.timeout = timeout
        self.retry = retry
        self.method = None
        self.port = 22
        self.vsh_prompt = ".*[>|%]"
        self.prompt = "@.*[\$|\#]"
        # self.logger = globs.g_logger also works due to aliases in Logger
        self.logger = logger if logger != None else globs.g_logger.logger
        self.connect()  # no explicit globs.g_conn_hdl.connect(g_args.method)

    def connect(self):
        self.logger.info("Attempt SSH login to host " + self.host)
        cmd = 'ssh %s@%s' % (self.user, self.host)  # 'ssh -l %s %s' also works
        try:
            self.last_cmd = cmd
            self.handle = pexpect.spawn(cmd, timeout = self.timeout,
                                        maxread = 65535, echo = False,
                                        logfile = sys.stdout.buffer)
            #self.handle.logfile = open(globs.g_script_name + ".log", "w")
        except Exception as e:
            #self.setErrorFlag(False)
            self.logger.error("Error " + e + " connecting to host " + self.host)
            return False

        ret = self.expect()
        msg = 'successful' if ret is True else 'failed'
        self.logger.info("SSH login to host %s %s, ttyout: %s" %
                         (self.host, msg, globs.g_script_name + ".log"))
        return ret

    def is_up(self):
        if self.handle is None:
            return False
        return True

    def expect(self, expr = None, isvsh = False, no = False):
        cprompt = self.prompt if isvsh is False else self.vsh_prompt
        pats = [pexpect.TIMEOUT, cprompt, '[\(|\[]*[Y|y]es[/|,][N|n]o[\)|\]]*',
                '[P|p]assword:', pexpect.EOF]
        if expr is not None:
            pats.append(expr)
            self.last_expr = expr

#        if isvsh is True:
#            pats.append()

        self.logger.debug("Expect: %s" % (str(pats)[1:-1]))

        while True:
            idx = self.handle.expect(pats, timeout = self.timeout)
            if idx == 0:  # timeout
                self.cli_out = str(self.handle.after)
                self.logger.info("\n")
                self.logger.info("expect %s timeout for cmd %s on host %s" %
                                    (self.last_expr, self.last_cmd, self.host))
                return False

            elif idx == 1:  # prompt received
                self.cli_out = str(self.handle.after)
                self.logger.debug("\n")
                self.logger.debug("Bash prompt seen on host " + self.host)
                return True

            elif idx == 2:  # yes/no question
                self.logger.debug("\n")
                self.logger.debug("Yes/No prompt seen on host " + self.host)
                ans = 'no' if no is True else 'yes'
                if self.send_line(ans) is False:
                    return False
                continue

            elif idx == 3:  # passwd prompt
                self.logger.debug("\n")
                self.logger.debug("Pass prompt seen on host " + self.host)
                if self.send_line(self.passwd) == False:
                    return False
                continue

            elif idx == 4:  # EOF reached, spawned process has died
                self.logger.debug("EOF reached on ssh to host " + self.host)
                return True

            else:
                if (idx == 5) and (expr is not None):  # input pattern
                    self.cli_out = str(self.handle.after)
                    self.logger.debug("\n")
                    self.logger.debug("Pattern %s seen on host %s" %
                                    (expr, self.host))
                    return True
                else:
                    self.logger.debug("\n")
                    self.logger.info("Unknown error for cmd %s on host %s" %
                                    (cmd, self.host))
                    return False

        return True

    def send_line(self, cmd):
        self.last_cmd = cmd
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

    def send_exp(self, cmd, expr = None):
        self.send_line(cmd)
        self.expect(expr)
        tstr = '%s %s' % (self.handle.before, self.handle.after)
        #print(tstr)        # expect() does job of self.handle.read() and more
        #self.logger.debug("%s" % (tstr))
        return True

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
