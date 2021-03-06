${SegmentFile}

Function _FileWrite_ReplaceCommon_Replace
	${WordReplace} $2 %Paths% $R1 + $R1
	${WordReplace} $2 %Paths% $R2 + $R2
	${If} $5 == UTF-16LE
		${ReplaceInFileUTF16LE} $1 $R1 $R2
	${Else}
		${ReplaceInFile} $1 $R1 $R2
	${EndIf}
FunctionEnd
!macro _FileWrite_ReplaceCommon_Replace last_name current_name
	ReadEnvStr $R1 ${last_name}$3
	ReadEnvStr $R2 ${current_name}$3
	Call _FileWrite_ReplaceCommon_Replace
!macroend

${SegmentPrePrimary}
	StrCpy $R0 0
	${Do}
		; This time we ++ at the start so we can use Continue
		IntOp $R0 $R0 + 1
		ClearErrors
		${ReadLauncherConfig} $0 FileWrite$R0 Type
		${ReadLauncherConfig} $7 FileWrite$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $7

		; Read the remaining items from the config
		${If} $0 == ConfigWrite
			${ReadLauncherConfig} $2 FileWrite$R0 Entry
			${ReadLauncherConfig} $3 FileWrite$R0 Value
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${ParseLocations} $3
			ClearErrors
			${ReadLauncherConfig} $4 FileWrite$R0 CaseSensitive
			${If} $4 != true
			${AndIf} $4 != false
			${AndIfNot} ${Errors}
				${InvalidValueError} [FileWrite$R0]:CaseSensitive $4
				${Continue}
			${EndIf}
		${ElseIf} $0 == INI
			${ReadLauncherConfig} $2 FileWrite$R0 Section
			${ReadLauncherConfig} $3 FileWrite$R0 Key
			${ReadLauncherConfig} $4 FileWrite$R0 Value
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${ParseLocations} $4
!ifdef XML_ENABLED
		${ElseIf} $0 == "XML attribute"
			${ReadLauncherConfig} $2 FileWrite$R0 XPath
			${ReadLauncherConfig} $3 FileWrite$R0 Attribute
			${ReadLauncherConfig} $4 FileWrite$R0 Value
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${ParseLocations} $4
		${ElseIf} $0 == "XML text"
			${ReadLauncherConfig} $2 FileWrite$R0 XPath
			${ReadLauncherConfig} $3 FileWrite$R0 Value
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${ParseLocations} $3
!else
		${ElseIf} $0 == "XML attribute"
		${OrIf} $0 == "XML text"
			!insertmacro XML_WarnNotActivated [FileWrite$R0]
			${Continue}
!endif
		${ElseIf} $0 == Replace
			${ReadLauncherConfig} $2 FileWrite$R0 Find
			${ReadLauncherConfig} $3 FileWrite$R0 Replace
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${ParseLocations} $2
			${ParseLocations} $3

			ClearErrors
			${ReadLauncherConfig} $4 FileWrite$R0 CaseSensitive

			StrCpy $5 skip ; $5 = "Do we need to replace?"
			${If} $4 == true   ; case sensitive
				${If} $2 S!= $3 ; find != replace?
					StrCpy $5 replace
				${EndIf}
			${Else} ; case insensitive
				${If} $4 != false     ; "false" is valid
				${AndIfNot} ${Errors} ; not set is valid
					${InvalidValueError} [FileWrite$R0]:CaseSensitive $4
					; default to case insensitive and continue on
				${EndIf}
				${If} $2 != $3 ; find != replace?
					StrCpy $5 replace
				${EndIf}
			${EndIf}
			${If} $5 == skip
				${Continue}
			${EndIf}
			; With Replace we actually leave Encoding calculation till later.
			; Generally this will be more efficient as it's probably auto.
		${ElseIf} $0 == ReplaceCommon
		${OrIf} $0 == ReplaceAll
			${ReadLauncherConfig} $2 FileWrite$R0 Context
			${IfThen} ${Errors} ${|} StrCpy $2 %Paths% ${|}
			${ReadLauncherConfig} $3 FileWrite$R0 PathForm
			${If} ${Errors} ; not present
				Nop
			${ElseIf} $3 == ForwardSlash
			${OrIf}   $3 == DoubleBackslash
			${OrIf}   $3 == java.util.prefs ; valid values
				StrCpy $3 :$3
			${Else} ; invalid value
				${InvalidValueError} [FileWrite$R0]:PathForm $3
			${EndIf}
		${Else}
			${InvalidValueError} [FileWrite$R0]:Type $0
			${Continue}
		${EndIf}

		; Now actually do it, for each file match.
		; We have all the info and everything is valid.
		${ForEachFile} $1 $R4 $7
			${If} $0 == ConfigWrite
				${If} $4 == true
					${DebugMsg} "Writing configuration to a file with ConfigWriteS.$\r$\nFile: $1$\r$\nEntry: `$2`$\r$\nValue: `$3`"
					${ConfigWriteS} $1 $2 $3 $R9
				${Else} ; false or empty
					${DebugMsg} "Writing configuration to a file with ConfigWrite.$\r$\nFile: $1$\r$\nEntry: `$2`$\r$\nValue: `$3`"
					${ConfigWrite} $1 $2 $3 $R9
				${EndIf}
			${ElseIf} $0 == INI
				${DebugMsg} "Writing INI configuration to a file.$\r$\nFile: $1$\r$\nSection: `$2`$\r$\nKey: `$3`$\r$\nValue: `$4`"
				WriteINIStr $1 $2 $3 $4
!ifdef XML_ENABLED
			${ElseIf} $0 == "XML attribute"
				${DebugMsg} "Writing configuration to a file with XMLWriteAttrib.$\r$\nFile: $1$\r$\nXPath: `$2`$\r$\nAttrib: `$3`$\r$\nValue: `$4`"
				${XMLWriteAttrib} $1 $2 $3 $4
;				${IfThen} ${Errors} ${|} ${DebugMsg} "XMLWriteAttrib XPath error" ${|}
			${ElseIf} $0 == "XML text"
				${ParseLocations} $3
				${DebugMsg} "Writing configuration to a file with XMLWriteText.$\r$\nFile: $1$\r$\nXPath: `$2`$\r$\n$\r$\nValue: `$3`"
				${XMLWriteText} $1 $2 $3
;				${IfThen} ${Errors} ${|} ${DebugMsg} "XMLWriteText XPath error" ${|}
!endif
			${ElseIf} $0 == Replace
			${OrIf} $0 == ReplaceCommon
			${OrIf} $0 == ReplaceAll
				ClearErrors
				${ReadLauncherConfig} $5 FileWrite$R0 Encoding
				${If} ${Errors}
					FileOpen $9 $1 r
					FileReadWord $9 $5
					${IfThen} $5 = 0xFEFF ${|} StrCpy $5 UTF-16LE ${|}
					FileClose $9
				${ElseIf} $5 != UTF-16LE
				${AndIf} $5 != ANSI
					${InvalidValueError} [FileWrite$R0]:Encoding $5
				${EndIf}
				${If} $0 == Replace
${!getdebug}
!ifdef DEBUG
					${IfThen} $5 == UTF-16LE ${|} StrCpy $R8 "a UTF-16LE" ${|}
					${IfThen} $5 != UTF-16LE ${|} StrCpy $R8 "an ANSI" ${|}
					StrCpy $R9 ``
					${IfThen} $4 != true ${|} StrCpy $R9 in ${|}
					${DebugMsg} "Finding and replacing in $R8 file (case $R9sensitive).$\r$\nFile: $1$\r$\nFind: `$2`$\r$\nReplace: `$3`"
!endif
					${If} $5 == UTF-16LE
						${If} $4 == true
							${ReplaceInFileUTF16LECS} $1 $2 $3
						${Else}
							${ReplaceInFileUTF16LE} $1 $2 $3
						${EndIf}
					${Else}
						${If} $4 == true
							${ReplaceInFileCS} $1 $2 $3
						${Else}
							${ReplaceInFile} $1 $2 $3
						${EndIf}
					${EndIf}
				${Else}
${!getdebug}
!ifdef DEBUG
					${IfThen} $5 != UTF-16LE ${|} StrCpy $5 "ANSI" ${|}
					${DebugMsg} "Finding and replacing common paths in the $5-encoded file $1 (format: $2)"
!endif
					${If} $0 == ReplaceAll
						!insertmacro _FileWrite_ReplaceCommon_Replace PAL:LastPortableAppsDirectory              PAL:PortableAppsDir
						!insertmacro _FileWrite_ReplaceCommon_Replace PAL:LastPortableApps.comDocumentsDirectory PortableApps.comDocuments
						!insertmacro _FileWrite_ReplaceCommon_Replace PAL:LastPortableApps.comPicturesDirectory  PortableApps.comPictures
						!insertmacro _FileWrite_ReplaceCommon_Replace PAL:LastPortableApps.comMusicDirectory     PortableApps.comMusic
						!insertmacro _FileWrite_ReplaceCommon_Replace PAL:LastPortableApps.comVideosDirectory    PortableApps.comVideos
					${EndIf}
					!insertmacro _FileWrite_ReplaceCommon_Replace PAL:LastDataDirectory PAL:DataDir
					!insertmacro _FileWrite_ReplaceCommon_Replace PAL:LastAppDirectory  PAL:AppDir
					!insertmacro _FileWrite_ReplaceCommon_Replace PAL:LastDrivePath     PAL:DrivePath
				${EndIf}
			${EndIf}
		${NextFile}
		;${If} ${Errors}
		;${AndIf} $0 == Replace
			;${DebugMsg} File didn't exist
		;${EndIf}
	${Loop}
!macroend

