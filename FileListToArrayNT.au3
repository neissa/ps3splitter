; Version du 03/07/2009
; http://www.autoitscript.com/forum/index.php?showtopic=96952&view=findpost&p=702862
; #FUNCTION# ===========================================================================================
; Name:             _FileListToArrayNT  (Revision 7)
; Description:      Lists files and\or folders in specified path(s) (Similar to using Dir with the /B Switch)
;                    additional features: multi-path, multi-filter, multi-exclude-filter, path format options, recursive search
; Syntax:           _FileListToArrayNT([$sPath = @ScriptDir, [$sFilter = "*", [$iSearchType, [$bRecursive = False, [$sExclude = "", [$iRetFormat = 1]]]]]])
; Parameter(s):     $sPath = optional: Search path(s), semicolon delimited (default: @ScriptDir)
;                            (Example: "C:\Tmp;D:\Temp")
;                   $sFilter = optional: Search filter(s), semicolon delimited . Wildcards allowed. (default: "*")
;                              (Example: "*.exe;*.txt")
;                   $iSearchType = Include in search: 0 = Files and Folder, 1 = Files Only, 2 = Folders Only
;                   $iPathType = Returned element format: 0 = file/folder name only, 1 = relative path, 2 = full path
;                   $bRecursive = optional: True: recursive search including all subdirectories
;                                           False (default): search only in specified folder
;                   $sExclude = optional: Exclude filter(s), semicolon delimited. Wildcards allowed.
;                               (Example: "Unins*" will remove all files/folders that begin with "Unins")
;                   $iRetFormat =  optional: return format
;                                  0 = one-dimensional array, 0-based
;                                  1 = one-dimensional array, 1-based (default)
;                                  2 = String ( "|" delimited)
;                   $sWorkPath =   *** internal use only (do not use) ***
; Requirement(s):   none
; Return Value(s):  on success: 1-based or 0-based array or string (dependent on $iRetFormat)
;                   If no path is found, @error and @extended are set to 1, returns empty string
;                   If no filter is found, @error and @extended are set to 2, returns empty string
;                   If no data is found, @error and @extended are set to 4, returns empty string
; Author(s):        Half the AutoIt Community
; ====================================================================================================
Func _FileListToArrayNT($sPath = @ScriptDir, $sFilter = "*", $iSearchType = 0, $iPathType = 0, $bRecursive = True, $sExclude = "", $iRetFormat = 1, $sWorkPath = "(-:>firstcall<:-)")
  Local $hSearch, $iPCount, $iFCount, $sFile, $sFileList, $sTWorkPath

  If $sWorkPath == "(-:>firstcall<:-)" Then
    If $sPath = -1 Or $sPath = Default Then $sPath = @ScriptDir
    ;strip leading/trailing spaces and semi-colons, all adjacent semi-colons, and spaces surrounding semi-colons
    $sPath = StringRegExpReplace(StringRegExpReplace($sPath, "(\s*;\s*)+", ";"), "\A;|;\z", "")
    ;check that at least one path is set
    If $sPath = "" Then Return SetError(1, 1, "")
    ;-----
    If $sFilter = -1 Or $sFilter = Default Then $sFilter = "*"
    ;strip leading/trailing spaces and semi-colons, all adjacent semi-colons, and spaces surrounding semi-colons
    $sFilter = StringRegExpReplace(StringRegExpReplace($sFilter, "(\s*;\s*)+", ";"), "\A;|;\z", "")
    ;check that at least one filter is set
    If $sFilter = "" Then Return SetError(2, 2, "")
    ;-----
    If $iSearchType <> "1" and $iSearchType <> "2" Then $iSearchType = "0"
    ;-----
    If $iPathType <> "1" And $iPathType <> "2" Then $iPathType = "0"
    ;-----
    $bRecursive = ($bRecursive = "1")
    ;-----
    If $sExclude = -1 Or $sExclude = Default Then $sExclude = ""
    If $sExclude Then
      ;prepare $sExclude
      ;strip leading/trailing spaces and semi-colons, all adjacent semi-colons, and spaces surrounding semi-colons
      $sExclude = StringRegExpReplace(StringRegExpReplace($sExclude, "(\s*;\s*)+", ";"), "\A;|;\z", "")
      ;convert $sExclude to fit StringRegExp (not perfect but useable)
      $sExclude = StringRegExpReplace($sExclude, '([\Q\.+[^]$(){}=!\E])', '\\$1')
      $sExclude = StringReplace($sExclude, "?", ".")
      $sExclude = StringReplace($sExclude, "*", ".*?")
      $sExclude = "(?i)\A" & StringReplace($sExclude, ";", "|") & "\z"
    EndIf
    ;-----
    If $iRetFormat <> "0" And $iRetFormat <> "2" Then $iRetFormat = "1"

    $sWorkPath = ""
  EndIf

  Local $aPath = StringSplit($sPath, ';', 1) ;paths array
  Local $aFilter = StringSplit($sFilter, ';', 1) ;filters array

  If $sExclude Then

    For $iPCount = 1 To $aPath[0] ;Path loop
      Local $sDelim = "|" ;reset $sDelim

      If StringRight($aPath[$iPCount], 1) <> "\" Then $aPath[$iPCount] &= "\" ;ensure trailing slash
      If $iPathType = 2 Then $sDelim &= $aPath[$iPCount] ;return full-path

      For $iFCount = 1 To $aFilter[0] ;filter loop
        If StringRegExp($aFilter[$iFCount], "[\\/:<>|]") Then ContinueLoop ;bypass filters with invalid chars
        $hSearch = FileFindFirstFile($aPath[$iPCount] & $aFilter[$iFCount])
        If @error Then ContinueLoop
        Switch $iSearchType
          Case 1 ;files Only
            While True
              $sFile = FileFindNextFile($hSearch)
              If @error Then ExitLoop
              If @extended Then ContinueLoop ;bypass folder
              ;check for exclude files
              If StringRegExp($sFile, $sExclude) Then ContinueLoop
              $sFileList &= $sDelim & $sWorkPath & $sFile
            WEnd
          Case 2 ;folders Only
            While True
              $sFile = FileFindNextFile($hSearch)
              If @error Then ExitLoop
              If @extended Then ;bypass file
                ;check for exclude folder
                If StringRegExp($sFile, $sExclude) Then ContinueLoop
                $sFileList &= $sDelim & $sWorkPath & $sFile
              EndIf
            WEnd
          Case Else ;files and folders
            While True
              $sFile = FileFindNextFile($hSearch)
              If @error Then ExitLoop
              ;check for exclude files/folder
              If StringRegExp($sFile, $sExclude) Then ContinueLoop
              $sFileList &= $sDelim & $sWorkPath & $sFile
            WEnd
        EndSwitch
        FileClose($hSearch)
      Next ;$iFCount - next filter

      ;---------------

      ;optional do a recursive search
      If $bRecursive Then
        $hSearch = FileFindFirstFile($aPath[$iPCount] & "*.*")
        If Not @error Then
          While True
            $sFile = FileFindNextFile($hSearch)
            If @error Then ExitLoop
            If @extended Then ;bypass file
              ;check for exclude folder
              If StringRegExp($sFile, $sExclude) Then ContinueLoop
              ;call recursive search
              If $iPathType = 1 Then $sTWorkPath = $sWorkPath & $sFile & "\"
              $sFileList &= _FileListToArrayNT($aPath[$iPCount] & $sFile & "\", $sFilter, $iSearchType, $iPathType, $bRecursive, $sExclude, 2, $sTWorkPath)
            EndIf
          WEnd
          FileClose($hSearch)
        EndIf
      EndIf

    Next ;$iPCount - next path

  Else ;If Not $sExclude

    For $iPCount = 1 To $aPath[0] ;path loop
      Local $sDelim = "|" ;reset $sDelim

      If StringRight($aPath[$iPCount], 1) <> "\" Then $aPath[$iPCount] &= "\" ;ensure trailing slash
      If $iPathType = 2 Then $sDelim &= $aPath[$iPCount] ;return full-path

      For $iFCount = 1 To $aFilter[0] ;filter loop
        If StringRegExp($aFilter[$iFCount], "[\\/:<>|]") Then ContinueLoop ;bypass filters with invalid chars
        $hSearch = FileFindFirstFile($aPath[$iPCount] & $aFilter[$iFCount])
        If @error Then ContinueLoop
        Switch $iSearchType
          Case 1 ;files Only
            While True
              $sFile = FileFindNextFile($hSearch)
              If @error Then ExitLoop
              If @extended Then ContinueLoop ;bypass folder
              $sFileList &= $sDelim & $sWorkPath & $sFile
            WEnd
          Case 2 ;folders Only
            While True
              $sFile = FileFindNextFile($hSearch)
              If @error Then ExitLoop
              If @extended Then ;bypass file
                $sFileList &= $sDelim & $sWorkPath & $sFile
              EndIf
            WEnd
          Case Else ;files and folders
            While True
              $sFile = FileFindNextFile($hSearch)
              If @error Then ExitLoop
              $sFileList &= $sDelim & $sWorkPath & $sFile
            WEnd
        EndSwitch
        FileClose($hSearch)
      Next ;$iFCount - next filter

      ;---------------

      ;optional do a recursive search
      If $bRecursive Then
        $hSearch = FileFindFirstFile($aPath[$iPCount] & "*.*")
        If Not @error Then
          While True
            $sFile = FileFindNextFile($hSearch)
            If @error Then ExitLoop
            If @extended Then ;bypass file
              ;call recursive search
              If $iPathType = 1 Then $sTWorkPath = $sWorkPath & $sFile & "\"
              $sFileList &= _FileListToArrayNT($aPath[$iPCount] & $sFile & "\", $sFilter, $iSearchType, $iPathType, $bRecursive, $sExclude, 2, $sTWorkPath)
            EndIf
          WEnd
          FileClose($hSearch)
        EndIf
      EndIf

    Next ;$iPCount - next path

  EndIf ;If $sExclude

  ;---------------

  ;set according return value
  If $sFileList Then
    Switch $iRetFormat
      Case 2 ;return a delimited string
        Return $sFileList
      Case 0 ;return a 0-based array
        Return StringSplit(StringTrimLeft($sFileList, 1), "|", 2)
      Case Else ;return a 1-based array
        Return StringSplit(StringTrimLeft($sFileList, 1), "|", 1)
    EndSwitch
  Else
    Return SetError(4, 4, "")
  EndIf

EndFunc   ;==>_FileListToArrayNT