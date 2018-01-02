;
; AutoIt Version: 3.0
; Language:       English
; Platform:       Win9x/NT
; Author:         Ravikiran K.S. (ravikiran.ks@ccpu.com)
;
; Script Function:
;   Opens startup applications, initializes apps.
;

; Prompt the user to run the script - use a Yes/No prompt (4 - see help file)
$answer = MsgBox(4, "AutoStart Assistant", "Good Day Ravi, shall I startup routine applications for you?")

; Check the user's answer to the prompt (see the help file for MsgBox return values)
; If "No" was clicked (7) then exit the script
If $answer = 7 Then
    MsgBox(0, "AutoStart Assistant", "Alright Ravi.  Bye!")
    Exit
EndIf

;-----------------------------------------------------------------------------------------
; Run FindAndRunRobot
Func FindAndRunRobot()
	Run("C:\Users\rkks\Documents\Most Basic\Search Tools\FindAndRunRobot\FindAndRunRobot.exe")
	Sleep(500)
EndFunc 

;-----------------------------------------------------------------------------------------
; Run Outlook
Func Outlook()
Run("C:\Program Files\Microsoft Office\Office12\outlook.exe")

; Wait for the Outlook become active - it is titled "Inbox - Microsoft Outlook" on English systems
WinWaitActive("[Inbox - Microsoft Outlook]")

Sleep(15000)
EndFunc 

;-----------------------------------------------------------------------------------------
; Run Putty
Func Putty()
Run("C:\Users\rkks\Documents\Most Basic\Connectivity Tools\Putty\putty.exe")

; Wait for the Putty become active - it is titled "PuTTY Configuration" on English systems
WinWaitActive("[PuTTY Configuration]")

Send("{TAB}{TAB}{TAB}")
Send("in-fuchsia")
Send("{TAB}{ENTER}")

Sleep(500)
EndFunc 

;-----------------------------------------------------------------------------------------
; Run Notepad2 - Identify Tasks for day
Func TasksTable()
;MsgBox(0, "AutoStart Assistant", "Kindly enter today's tasks!")
;Run("C:\Users\rkks\Documents\Most Basic\Devel Tools\notepad2\Notepad2.exe")
Run("notepad.exe")

; Wait for the Notepad2 become active - it is titled "Untitled - Notepad2" on English systems
;WinWaitActive("[Untitled - Notepad2]")
WinWaitActive("[Untitled - Notepad]")

Send("{TAB}{TAB}{TAB}{TAB}{TAB}")
;Send("{TAB}{TAB}{TAB}{TAB}{TAB}")
;Send("Daily Task List - ^{F5}")
Send("Daily Task List - {F5}")
Sleep(500)

; Now wait for Notepad to close before continuing
;WinWaitClose("[* Untitled - Notepad2]")
;WinWaitClose("[Untitled - Notepad]")
EndFunc 

;-----------------------------------------------------------------------------------------
; Run Internet Explorer
Func Gmail()
Run("C:\Program Files\Internet Explorer\iexplore.exe")

; Wait for the Internet Explorer become active
WinWaitActive("[Google - Windows Internet Explorer]", "", 30)

Sleep(500)
EndFunc 

;-----------------------------------------------------------------------------------------
Func PlayMusic()
; plays back a beep noise, at the frequency 500 for 1 second
;Beep(500, 1000)
SoundPlay(@WindowsDir & "\media\flourish.mid",1)
EndFunc 

Func StartApps()
FindAndRunRobot()
Outlook()
Putty()
;TasksTable()
;Gmail()
EndFunc 

StartApps()

; Now quit by pressing Alt-f and then x (File menu -> Exit)
;Send("!f")
;Send("x")

; Finished!
