; Disconnect network drive
$drivemap = "P:"
DriveMapDel($drivemap)
; Get details of the mapping
MsgBox(0, "Drive $drivemap is mapped to", DriveMapGet($drivemap))
