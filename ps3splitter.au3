#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#Include <File.au3>
#include <Array.au3>
#include <FileListToArrayNT.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>

Func searchBigFile()
	Local $files, $c_file=0, $c_big_file=0
	global $bigfiles[1], $dir
	
	$files = _FileListToArrayNT($dir,"*.*", 1, 1)
	For $i = 0 to UBound($files,1) - 1
		$file_name = $dir & "/"& $files[$i]
		$size = FileGetSize($file_name)
		$c_file = $c_file + 1
		If $size > 4294967296-10 Then
			$c_big_file = $c_big_file + 1
			_ArrayAdd($bigfiles, $file_name)
		EndIf
	Next
	GUICtrlSetData($mylist, $c_file & " fichier(s) dont "&$c_big_file&" >4Go"& @CRLF, 1)
	return $bigfiles
EndFunc

Func splitBigFile()
	$files = searchBigFile();
	For $i = 0 to UBound($files,1) - 1
		$file_name = $files[$i]
		if $file_name <> "" Then
			$size = FileGetSize($file_name)
			GUICtrlSetData($mylist, "Découpage de "&$file_name&"  ("&Round($size/1024/1024,0)&"Mo)"& @CRLF, 1)
			split($file_name);
		endif
	Next
EndFunc

Func split($filename)
	if $filename == "" then return
		
	$base_filename = $filename;
	$piecesize = 3*1024; MO
	$buffer = 1024;
	$piece = 1024*1024*$piecesize;
	$current = 0;
	$splitnum = 1;

	$piece_name = $filename&'.first';
	
	$part = FileOpen($piece_name,10)
	$file = FileOpen($filename,0)
	GUICtrlSetData($mylist, "partie 1"& @CRLF, 1)
	while 1
		if $current < $piece then
			$content = FileRead($file, $buffer)
			
			If @error = -1 Then ExitLoop
				
			FileWrite($part, $content)
			$current += $buffer;
		else
			GUICtrlSetData($mylist, "partie "&$splitnum+1& @CRLF, 1)
			fileclose($part);
			$current = 0;
			$piece_name = $filename&'.'&$splitnum&'.part';
			$splitnum = $splitnum + 1;
			$part = fileopen($piece_name,10);
		EndIf
	WEnd
	fileclose($part);
	fileclose($file);
	;FileMove($filename, $filename&".bak", 1)
	FileMove($filename&'.first', $filename, 1)
	
	GUICtrlSetData($mylist, "Fin de découpage de "&$filename& @CRLF, 1)
EndFunc


;GUI

Func ps3splitter()
	global $gui, $msg, $mylist, $dir
	$gui = GUICreate("PS3Splitter", 800, 125)
	GUISetState(@SW_SHOW)
	Opt("GUICoordMode", 1)
	$Button_1 = GUICtrlCreateButton("Choisir le dossier", 10, 10, 150,35)
	$Button_2 = GUICtrlCreateButton("Lancer le découpage", 10, 50, 150,35)
	
	$label = GUICtrlCreateLabel("Veuillez choisir un dossier",10,100,780,20)
	
	GUICtrlSetState($Button_2, $GUI_DISABLE)
	GUICtrlSetState($label, $GUI_DISABLE)
	$mylist = GUICtrlCreateEdit("", 170, 5, 800-170-5, 95, $ES_AUTOVSCROLL + $WS_VSCROLL)
	;GUICtrlSetState($mylist, $GUI_DISABLE)
	;GUICtrlCreateList("", 170, 5, 800-170-5, 95)
	GUISetState()      ; will display an  dialog box with 2 button

	; Run the GUI until the dialog is closed
	While 1
		$msg = GUIGetMsg()
		Select
			Case $msg = $GUI_EVENT_CLOSE
				ExitLoop
			Case $msg = $Button_2
				GUICtrlSetState($Button_2, $GUI_DISABLE)
				splitBigFile()
				sleep(300)
				GUICtrlSetState($Button_2, $GUI_ENABLE)
			Case $msg = $Button_1
				$dir = FileSelectFolder("Veuillez choisir le dossier", "", 2)
				If @error then
				   GUICtrlSetState($Button_2, $GUI_DISABLE)
				   GUICtrlSetData($label, "Veuillez choisir un dossier")
			    Else
				   GUICtrlSetState($Button_2, $GUI_ENABLE)
				   GUICtrlSetData($label, $dir)
				endif
		EndSelect
	WEnd
EndFunc

ps3splitter();