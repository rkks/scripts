#Region --- CodeWizard generated code Start ---
#include<Array.au3>
$a = ProcessGetId('firefox.exe')
For $i = 1 To UBound($a) - 1
    ConsoleWrite(ProcessGetWindow($a[$i]) & @CRLF)
Next

Func ProcessGetWindow($PId)
    If IsNumber($PId) = 0 Or ProcessExists(ProcessGetName($PId)) = 0 Then
        SetError(1)
    Else
        Local $WinList = WinList()
        Local $i = 1
        Local $WindowTitle = ""
        While $i <= $WinList[0][0] And $WindowTitle = ""
            If WinGetProcess($WinList[$i][0], "") = $PId Then
                $WindowTitle = $WinList[$i][0]
            Else
                $i += 1
            EndIf
        WEnd
        Return $WindowTitle
    EndIf
EndFunc ;==>ProcessGetWindow

Func ProcessGetId($Process)
    If IsString($Process) = 0 Then
        SetError(2)
    ElseIf ProcessExists($Process) = 0 Then
        SetError(1)
    Else
        Local $PList = ProcessList($Process)
        Local $i
        Local $PId[$PList[0][0] + 1]
        $PId[0] = $PList[0][0]
        For $i = 1 To $PList[0][0]
            $PId[$i] = $PList[$i][1]
        Next
        Return $PId
    EndIf
EndFunc ;==>ProcessGetId

Func ProcessGetName($PId)
    If IsNumber($PId) = 0 Then
        SetError(2)
    ElseIf $PId > 9999 Then
        SetError(1)
    Else
        Local $PList = ProcessList()
        Local $i = 1
        Local $ProcessName = ""

        While $i <= $PList[0][0] And $ProcessName = ""
            If $PList[$i][1] = $PId Then
                $ProcessName = $PList[$i][0]
            Else
                $i = $i + 1
            EndIf
        WEnd
        Return $ProcessName
    EndIf
EndFunc ;==>ProcessGetName

; Window to Process
; Now making Window name and executables/PIDs interchangable!
; Credit to Cynagen
Func Win2Process($wintitle)
    if isstring($wintitle) = 0 then return -1
    $wproc = WinGetProcess($wintitle)
    return _ProcessName($wproc)
endfunc

Func Process2Win($pid)
    if isstring($pid) then $pid = processexists($pid)
    if $pid = 0 then return -1
    $list = WinList()
    for $i = 1 to $list[0][0]
        if $list[$i][0] <> "" AND BitAnd(WinGetState($list[$i][1]),2) then
            $wpid = WinGetProcess($list[$i][0])
            if $wpid = $pid then return $list[$i][0]
        EndIf
    next
    return -1
endfunc

Func ProcessName($pid)
    if isstring($pid) then $pid = processexists($pid)
    if not isnumber($pid) then return -1
    $proc = ProcessList()
    for $p = 1 to $proc[0][0]
        if $proc[$p][1] = $pid then return $proc[$p][0]
    Next
    return -1
EndFunc

;==============================================================================================
Local $file = FileOpen("C:\Users\raviks\pid-autoit.txt", 0)

; Check if file opened for writing OK
If $file = -1 Then
    MsgBox(0, "Error", "Unable to open C:\pid-autoit.txt")
    Exit
EndIf

MsgBox(0, "AppStopAlert", "App stop begin!")

; Read in lines of text until the EOF is reached
While 1
    Local $pid = FileReadLine($file)
    If @error = -1 Then ExitLoop
	If ProcessExists($pid) Then
    	MsgBox(0, "AppStopAlert", "Closing process " & ProcessName($pid))
		ProcessClose($pid)
	EndIf
WEnd

FileClose($file)
FileRecycle("C:\Users\raviks\pid-autoit.txt")

MsgBox(0, "AppStopAlert", "App stop complete. Bye!")
Exit
#EndRegion --- CodeWizard generated code End ---
