#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force
 ; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%
configFile := "config.ini"

GetMostRecentFile(folder)
{
	mostRecentTime = 20000101
	file := ""
	Loop, Files, %folder%\*.txt
	{
		If (A_LoopFileTimeModified > mostRecentTime)
		{
			mostRecentTime := A_LoopFileTimeModified
			file := A_LoopFileName
		}
	}
	
	return file
}

GetMostRecentMostXP(folder)
{
	file := ""
	mostXP := 0
	Loop, Files, %folder%\*.txt
	{
		GetCharacterInfoFromFile(folder "\" A_LoopFileName, acc, lvl, xp, gold, sg, cl)
		If (xp > mostXP)
		{
			mostXP := xp
			file := A_LoopFileName
		}
	}
	
	return file
}

GetCharacterInfoFromFile(filePath, ByRef charAccountName, ByRef charLevel, ByRef charXP, ByRef charGold, ByRef charSG, ByRef charClass)
{
	if (filePath = "")
	{
		return
	}
	accountFound := 0
	levelFound := 0
	XPFound := 0
	goldFound := 0
	SGFound := 0
	charClassFound := 0
	Loop, read, %filePath%
	{
		if (accountFound = 0)
		{
			accountFound := RegExMatch(A_LoopReadLine, "(?<="" Name: )[^""]*", charAccountName)
		}
		if (levelFound = 0)
		{
			levelFound := RegExMatch(A_LoopReadLine, "(?<="" Level: )[^""]*", charLevel)
		}
		if (XPFound = 0)
		{
			XPFound := RegExMatch(A_LoopReadLine, "(?<="" EXP: )[^""]*", charXP)
		}
		if (goldFound = 0)
		{
			goldFound := RegExMatch(A_LoopReadLine, "(?<="" Gold: )[^""]*", charGold)
		}
		if (SGFound = 0)
		{
			SGFound := RegExMatch(A_LoopReadLine, "(?<="" Star Glass: )[^""]*", charSG)
		}
		if (charClassFound = 0)
		{
			charClassFound := RegExMatch(A_LoopReadLine, "(?<="" Hero: )[^""]*", charClass)
		}
	}
}

GetAccountInfoFromFile(filePath, ByRef name, ByRef apt, ByRef dedi)
{
	if (filePath = "")
	{
		return
	}
	nameFound := 0
	aptFound := 0
	dediFound := 0
	Loop, read, %filePath%
	{
		if (nameFound = 0)
		{
			nameFound := RegExMatch(A_LoopReadLine, "(?<=Name: )[^""]*", name)
		}
		if (aptFound = 0)
		{
			aptFound := RegExMatch(A_LoopReadLine, "(?<=APT: )[^""]*", apt)
		}
		if (dediFound = 0)
		{
			dediFound := RegExMatch(A_LoopReadLine, "(?<=DEDI PTS: )[^""]*", dedi)
		}
	}
}

GetLastAccountCode()
{
	Global ;
	accountFilename := GetMostRecentFile(savedFilesPath)
	if (accountFilename = "")
	{
		MsgBox Aborting: no account file found. Please check save path.
	}
	
	accountCode := ""
	GetAccountCode(savedFilesPath "\" accountFilename, accountCode)
}

GetAccountCode(file, ByRef code)
{
	code := ""
	Loop, read, %file%
	{
		CodeFound := RegExMatch(A_LoopReadLine, "^-la.*", code)
		if (CodeFound != 0)
		{
			break ; code found
		}
	}
	if (code = "")
	{
		MsgBox Aborting: could not find account code in %file%. Please check save path.
	}
}

InitGUI()
{
	Global ;
	
 ; --- Account selection UI ---
	Gui, Add, Text, y8, Account filter: 
	Gui, Add, DropDownList, x80 y4 vAccountFilterChoice gAccountFilterEvent, None
	Gui, Add, ListView, x10 y30 w290 h450 vAccountListView gAccountListViewEvent AltSubmit, Name|APT|Dedi|Last Modified|hiddendate|Filename
	LV_ModifyCol(1, "100")
	LV_ModifyCol(2, "50 Integer")
	LV_ModifyCol(3, "50 Integer")
	LV_ModifyCol(4, "70 NoSort")
	LV_ModifyCol(5, "0")
	LV_ModifyCol(6, "80")
	
	accountDateSorting := "SortDesc"
	
 ; --- Hero selection UI ---
	Gui, Add, ListBox, x310 y30 w150 h400 vHeroChoice gHeroSelected Sort
	Gui, Add, Button, x310 y429 gMostRecentButton, Load Most Recent
	Gui, Add, Button, x310 y+m gMostXPButton, Load Most XP
	
	Gui, Add, CheckBox, x470 y6 vPioneerFilter gPioneerFilterChanged, Pioneer only 
	Gui, Add, CheckBox, x570 y6 vEmpTowerFilter gEmpTowerChanged, Empowered Tower only
	
	Gui, Add, ListView, x470 y30 h450 w510 vHeroListView gHeroListViewEvent AltSubmit, Level|XP|Gold|SG|WL|Last Modified|hiddendate|Class|Account|Filename
	LV_ModifyCol(1, "40 Integer")
	LV_ModifyCol(2, "70 Integer SortDesc")
	LV_ModifyCol(3, "70 Integer")
	LV_ModifyCol(4, "40 Integer")
	LV_ModifyCol(5, "40 Integer")
	LV_ModifyCol(6, "70 NoSort")
	LV_ModifyCol(7, "0")
	LV_ModifyCol(8, "90")
	LV_ModifyCol(9, "90")
	LV_ModifyCol(10, "80")
	
	heroDateSorting := "SortDesc"
	
	Menu, FileMenu, Add, &Settings`tCtrl+S, FileMenuSettings
	Menu, FileMenu, Add, &Help`tCtrl+H, FileMenuHelp
	Menu, FileMenu, Add, &Quit`tCtrl+Q, FileMenuQuit
	
	Menu, AccountMenu, Add, &Select Account`tCtrl+A, AccountMenuSelect
	
	Menu, MenuBar, Add, &File, :FileMenu
	Menu, MenuBar, Add, &Account, :AccountMenu
	Gui, Menu, MenuBar
	
	Menu, Tray, Add
	Menu, Tray, Add, Show hero selection, ShowHeroSelection
	Menu, Tray, Default, Show hero selection
	Menu, Tray, Click, 1
	
 ; --- Settings UI ---
	Local yPosG := 10
	Local yPosL := 20
	Gui, 2:Add, GroupBox, xm y%yPosG% w510 h260 Section, Hotkeys
	yPosL := yPosL + 10
	Gui, 2:Add, Text, xs10 ys%yPosL%, Load hero: 
	Gui, 2:Add, Hotkey, xs180 ys%yPosL% vLoadHeroHotkey
	Gui, 2:Add, Button, xs300 ys%yPosL% gLoadHeroHotkeyClear, X
	Gui, 2:Add, Button, xs320 ys%yPosL% gLoadHeroHotkeyHelp, ?
	yPosL := yPosL + 25
	Gui, 2:Add, Text, xs10 ys%yPosL%, Load account: 
	Gui, 2:Add, Hotkey, xs180 ys%yPosL% vLoadAccountHotkey
	Gui, 2:Add, Button, xs300 ys%yPosL% gLoadAccountHotkeyClear, X
	Gui, 2:Add, Button, xs320 ys%yPosL% gLoadAccountHotkeyHelp, ?
	yPosL := yPosL + 25
	Gui, 2:Add, Text, xs10 ys%yPosL%, Refresh codes (most recent): 
	Gui, 2:Add, Hotkey, xs180 ys%yPosL% vRefreshCodesHotkey
	Gui, 2:Add, Button, xs300 ys%yPosL% gRefreshCodesHotkeyClear, X
	Gui, 2:Add, Button, xs320 ys%yPosL% gRefreshCodesHotkeyHelp, ?
	yPosL := yPosL + 25
	Gui, 2:Add, Text, xs10 ys%yPosL%, Refresh codes (hero only): 
	Gui, 2:Add, Hotkey, xs180 ys%yPosL% vRefreshCodesHeroHotkey
	Gui, 2:Add, Button, xs300 ys%yPosL% gRefreshCodesHeroHotkeyClear, X
	Gui, 2:Add, Button, xs320 ys%yPosL% gRefreshCodesHeroHotkeyHelp, ?
	yPosL := yPosL + 25
	Gui, 2:Add, Text, xs10 ys%yPosL%, Show hero selection: 
	Gui, 2:Add, Hotkey, xs180 ys%yPosL% vShowHeroSelectionHotkey
	Gui, 2:Add, Button, xs300 ys%yPosL% gShowHeroSelectionHotkeyClear, X
	Gui, 2:Add, Button, xs320 ys%yPosL% gShowHeroSelectionHotkeyHelp, ?
	yPosL := yPosL + 25
	Gui, 2:Add, Text, xs10 ys%yPosL%, Avnos puzzle: 
	Gui, 2:Add, Hotkey, xs180 ys%yPosL% vAvnosPuzzleHotkey
	Gui, 2:Add, Button, xs300 ys%yPosL% gAvnosPuzzleHotkeyClear, X
	Gui, 2:Add, Button, xs320 ys%yPosL% gAvnosPuzzleHotkeyHelp, ?
	yPosL := yPosL + 25
	Gui, 2:Add, Text, xs10 ys%yPosL%, Trials portals: 
	Gui, 2:Add, Hotkey, xs180 ys%yPosL% vTrialsPortalsHotkey
	Gui, 2:Add, Button, xs300 ys%yPosL% gTrialsPortalsHotkeyClear, X
	Gui, 2:Add, Button, xs320 ys%yPosL% gTrialsPortalsHotkeyHelp, ?
	yPosL := yPosL + 25
	Gui, 2:Add, Text, xs10 ys%yPosL%, Clear text (z): 
	Gui, 2:Add, Hotkey, xs180 ys%yPosL% vClearTextHotkey
	Gui, 2:Add, Button, xs300 ys%yPosL% gClearTextHotkeyClear, X
	Gui, 2:Add, Button, xs320 ys%yPosL% gClearTextHotkeyHelp, ?
	yPosL := yPosL + 25
	Gui, 2:Add, Text, xs10 ys%yPosL%, Inventory (-inv): 
	Gui, 2:Add, Hotkey, xs180 ys%yPosL% vInventoryHotkey
	Gui, 2:Add, Button, xs300 ys%yPosL% gInventoryHotkeyClear, X
	Gui, 2:Add, Button, xs320 ys%yPosL% gInventoryHotkeyHelp, ?
	
	yPosG := yPosG + 260
	yPosL := 20
	Gui, 2:Add, GroupBox, xm y%yPosG% w510 h140 Section, Other
	Gui, 2:Add, Text, xs10 ys%yPosL%, Camera distance (0 to not use): 
	Gui, 2:Add, Edit, xs180 ys%yPosL% w50 number vCameraDistanceEdit
	yPosL := yPosL + 25
	Gui, 2:Add, Button, xs10 ys%yPosL% gChangePathButtonClicked, Change save files path
	Gui, 2:Add, Edit, xs180 ys%yPosL% w320 vChangePathValue ReadOnly
	yPosL := yPosL + 40
	Gui, 2:Add, Text, xs10 ys%yPosL%, Delay between inputs (in ms)
	Gui, 2:Add, Edit, xs180 ys%yPosL% w50 number vInputDelayValue
	yPosL := yPosL + 25
	Gui, 2:Add, Text, xs10 ys%yPosL%, Enable sounds: 
	Gui, 2:Add, CheckBox, xs180 ys%yPosL% vEnableSoundsValue
	GuiControl,, EnableSoundsValue
	
	yPosG := yPosG + 145
	Gui, 2:Add, Button, xm y%yPosG% gSettingsCancelButton, Cancel
	Gui, 2:Add, Button, x+m gSettingsSaveButton, Save
}

ShowCharacterUI()
{
	Global ;
	
	Local heroList := ""
	Loop, Files, %savedFilesPath%\*, D
	{
		heroList .= "|" A_LoopFileName 
	}
	GuiControl,, HeroChoice, % heroList
	GuiControl,, PioneerFilter, % pioneerOnly
	GuiControl,, EmpTowerFilter, % empTowerOnly
	
	if (not WinActive("TKoK Loader Character selection"))
	{
		Gui, Show,, TKoK Loader Character selection
	}
}

ShowSettingsUI()
{
	Global ;
	
	GuiControl, 2:, LoadHeroHotkey, % loadHeroKey
	GuiControl, 2:, LoadAccountHotkey, % loadAccountKey
	GuiControl, 2:, RefreshCodesHotkey, % refreshCodesKey
	GuiControl, 2:, RefreshCodesHeroHotkey, % refreshCodesHeroKey
	GuiControl, 2:, ShowHeroSelectionHotkey, % showSelectionKey
	GuiControl, 2:, AvnosPuzzleHotkey, % avnosPuzzleKey
	GuiControl, 2:, TrialsPortalsHotkey, % trialsPortalsKey
	GuiControl, 2:, ClearTextHotkey, % clearTextKey
	GuiControl, 2:, InventoryHotkey, % inventoryKey
	GuiControl, 2:, CameraDistanceEdit, % cameraDistance
	GuiControl, 2:, ChangePathValue, % savedFilesPath
	GuiControl, 2:, InputDelayValue, % inputDelay
	GuiControl, 2:, EnableSoundsValue, % enableSounds
	
	Gui, 2:Show,, TKoK Loader Settings
}

HideAllGUI()
{
	Gui, Hide
	Gui, 2:Hide
}
 
PopulateHeroListView(characterDirectory)
{
	Gui, ListView, HeroListView

	Global savedFilesPath
	Global accountFilter
	Global pioneerOnly
	Global empTowerOnly
	
	maxWL := 9999
	minWL := 0
	if (pioneerOnly = 1)
	{
		maxWL := 0
	}
	else if (empTowerOnly = 1)
	{
		minWL := 7
	}
	
	LV_Delete()
	absoluteDir = %savedFilesPath%\%characterDirectory%
	Loop, Files, %absoluteDir%\*.txt
	{
		currentFilename := absoluteDir "\" A_LoopFileName
		RegExMatch(currentFilename, "(?<=_WL)[^.]*", worldLevel)
		if (worldLevel >= minWL and worldLevel <= maxWL)
		{
			GetCharacterInfoFromFile(currentFilename, currentAccount, currentLevel, currentXP, currentGold, currentSG, currentClass)
			if (currentAccount = "") ; couldn't get info from file, skip it
			{
				continue
			}
			if (accountFilter = "" or accountFilter = currentAccount)
			{
				FormatTime, currentDate, %A_LoopFileTimeModified%, ShortDate
				LV_Add("", currentLevel, currentXP, currentGold, currentSG, worldLevel, currentDate, A_LoopFileTimeModified, currentClass, currentAccount, currentFilename)
			}
		}
	}
	
	LV_ModifyCol(2, "SortDesc")
}

PopulateAccountListView(populateFilter)
{
	Gui, ListView, AccountListView
	LV_Delete()
	Global savedFilesPath
	Global accountFilter
	accountList := "|None||"
	Loop, Files, %savedFilesPath%\*.txt
	{
		currentFilename := savedFilesPath "\" A_LoopFileName
		GetAccountInfoFromFile(currentFilename, currentName, currentAPT, currentDedi)
		if (currentName  = "") ; couldn't get info from file, skip it
		{
			continue
		}
		if (InStr(accountList, currentName "|") = 0)
		{
			accountList .= currentName "|"
		}
		if (accountFilter = "" or accountFilter = currentName)
		{
			FormatTime, currentDate, %A_LoopFileTimeModified%, ShortDate
			LV_Add("", currentName, currentAPT, currentDedi, currentDate, A_LoopFileTimeModified, currentFilename)
		}
	}
	
	if (populateFilter = 1)
	{
		GuiControl,, AccountFilterChoice, % accountList
	}
}

GetCharacterCodes(file)
{
	Global ;
	if (file = "")
	{
		return
	}
	Code1Found := 0
	Code2Found := 0
	accountFound := 0
	characterCode1 := ""
	characterCode2 := ""
	accountName := ""
	Loop, read, %file%
	{
		if (Code1Found = 0)
		{
			Code1Found := RegExMatch(A_LoopReadLine, "-l [^""]*", characterCode1)
		}
		if (Code2Found = 0)
		{
			Code2Found := RegExMatch(A_LoopReadLine, "-l2 [^""]*", characterCode2)
		}
		if (accountFound = 0)
		{
			accountFound := RegExMatch(A_LoopReadLine, "(?<="" Name: )[^""]*", accountName)
		}
	}
	if (characterCode1 = "" || characterCode2 = "")
	{
		if (enableSounds = 1)
		{
			SoundPlay, %A_ScriptDir%\sounds\failure.wav
		}
		return
	}
	
	if (enableSounds = 1)
	{
		SoundPlay, %A_ScriptDir%\sounds\success.wav
	}	
}

LoadSettings()
{
	Global ;
	IniRead, cameraDistance, %configFile%, OTHER, cdist, ERROR
	IniRead, savedFilesPath, %configFile%, OTHER, savePath, ERROR
	IniRead, inputDelay, %configFile%, OTHER, inputDelay, ERROR
	IniRead, enableSounds, %configFile%, OTHER, enableSounds, ERROR

	IniRead, loadHeroKey, %configFile%, HOTKEYS, loadHero, ERROR
	IniRead, loadAccountKey, %configFile%, HOTKEYS, loadAccount, ERROR
	IniRead, refreshCodesKey, %configFile%, HOTKEYS, refreshCodes, ERROR
	IniRead, refreshCodesHeroKey, %configFile%, HOTKEYS, refreshCodesHero, ERROR
	IniRead, showSelectionKey, %configFile%, HOTKEYS, showHeroSelection, ERROR
	IniRead, avnosPuzzleKey, %configFile%, HOTKEYS, avnosPuzzle, ERROR
	IniRead, trialsPortalsKey, %configFile%, HOTKEYS, trialsPortals, ERROR
	IniRead, clearTextKey, %configFile%, HOTKEYS, clearText, ERROR
	IniRead, inventoryKey, %configFile%, HOTKEYS, inventory, ERROR
	if (savedFilesPath = "ERROR")
	{
		savedFilesPath := ""
	}
	if (cameraDistance = "ERROR")
	{
		cameraDistance := 0
	}
	if (inputDelay = "ERROR")
	{
		inputDelay := 0
	}
	if (enableSounds = "ERROR")
	{
		enableSounds := 1
	}
	Hotkey, IfWinActive, Warcraft III
	if (loadHeroKey != "ERROR" and loadHeroKey != "")
	{
		Hotkey, % loadHeroKey, LoadHero
	}
	if (loadAccountKey != "ERROR" and loadAccountKey != "")
	{
		Hotkey, % loadAccountKey, LoadAccount
	}
	if (avnosPuzzleKey != "ERROR" and avnosPuzzleKey != "")
	{
		Hotkey, % avnosPuzzleKey, AvnosPuzzle
	}
	if (trialsPortalsKey != "ERROR" and TrialsPortalsKey != "")
	{
		Hotkey, % trialsPortalsKey, TrialsPortals
	}
	if (clearTextKey != "ERROR" and clearTextKey != "")
	{
		Hotkey, % clearTextKey, ClearText
	}
	if (inventoryKey != "ERROR" and inventoryKey != "")
	{
		Hotkey, % inventoryKey, Inventory
	}
	Hotkey, IfWinActive
	Hotkey, IfWinNotActive, TKoK Loader Settings
	if (refreshCodesKey != "ERROR" and refreshCodesKey != "")
	{
		Hotkey, % refreshCodesKey, RefreshCodes
	}
	if (refreshCodesHeroKey != "ERROR" and refreshCodesHeroKey != "")
	{
		Hotkey, % refreshCodesHeroKey, RefreshCodesHero
	}
	Hotkey, IfWinNotActive, TKoK Loader
	if (showSelectionKey != "ERROR" and showSelectionKey != "")
	{
		Hotkey, % showSelectionKey, ShowHeroSelection
	}
	Hotkey, IfWinNotActive
}

 ; ----- AUTOEXEC -----
LoadSettings()
InitGUI()
if (savedFilesPath = "")
{
	MsgBox, No save folder detected!`nThis is normal for a first launch.`nPress OK and select your TKoK save folder (it is the folder containing your account files and character folders).
	FileSelectFolder, savedFilesPath,,, Select TKoK save folder
	IniWrite, %savedFilesPath%, %configFile%, OTHER, savePath
}
pioneerOnly := 0
empTowerOnly := 0
accountFilter := ""
reloadAccountsOnSave := 0
GetLastAccountCode()
ShowCharacterUI()
PopulateAccountListView(1)
return ; end of auto execute

 ; ----- MACRO -----
LoadHero:
	Send, {Raw}`n-loadwith %accountName%`n
	Sleep, % inputDelay
	Send, {Raw}`n%characterCode1%`n
	Sleep, % inputDelay
	Send, {Raw}`n%characterCode2%`n
	if (cameraDistance != 0)
	{
		Sleep, % inputDelay
		Send, `n-cdist %cameraDistance%`n
	}
return

LoadAccount:
	Send, {Raw}`n%accountCode%`n
return

RefreshCodes:
	if (currentDir = "")
	{
		if (enableSounds = 1)
		{
			SoundPlay, %A_ScriptDir%\sounds\failure.wav
		}
		return
	}
	GetLastAccountCode()
	characterFile := currentDir . "\" . GetMostRecentFile(currentDir)
	GetCharacterCodes(characterFile)
return
 
RefreshCodesHero:
	if (currentDir = "")
	{
		if (enableSounds = 1)
		{
			SoundPlay, %A_ScriptDir%\sounds\failure.wav
		}
		return
	}
	characterFile := currentDir . "\" . GetMostRecentFile(currentDir)
	GetCharacterCodes(characterFile)
return
 
ShowHeroSelection:
	ShowCharacterUI()
return

AvnosPuzzle:
	Input, avnosPuzzleChoice, L1
	switch avnosPuzzleChoice
	{
		case "1", "Numpad1":
			Send, `n164235`n
			return
		case "2", "Numpad2":
			Send, `n241563`n
			return
		case "3", "Numpad3":
			Send, `n312645`n
			return
		case "5", "Numpad5":
			Send, `n541632`n
			return
		case "6", "Numpad6":
			Send, `n651324`n
			return
		default: ; any other input falls through
			Send % avnosPuzzleChoice
	}
return

TrialsPortals:
	Send, `nRRRLRLLL`n`nRRLRLRLL`n`nLRLRLRRL`n`nLRLRRLLR`n
return

ClearText:
	Send, `nz`n
return

Inventory:
	Send, `n-inv`n
return

 ; ----- GUI Callback -----
HeroSelected:
	GuiControlGet, charDir,, HeroChoice
	PopulateHeroListView(charDir)
	currentDir = %savedFilesPath%\%charDir%
return

MostRecentButton:
	GuiControlGet, charDir,, HeroChoice
	if (charDir = "")
	{
		MsgBox, Please select a hero to load first.
		return
	}
	currentDir = %savedFilesPath%\%charDir%
	characterFile := currentDir . "\" . GetMostRecentFile(currentDir)
	GetCharacterCodes(characterFile)
	HideAllGUI()
return

MostXPButton:
	GuiControlGet, charDir,, HeroChoice
	if (charDir = "")
	{
		MsgBox, Please select a hero to load first.
		return
	}
	currentDir = %savedFilesPath%\%charDir%
	characterFile := currentDir . "\" . GetMostRecentMostXP(currentDir)
	GetCharacterCodes(characterFile)
	HideAllGUI()
return

AccountListViewEvent:
	Gui, ListView, AccountListView
	if (A_GuiEvent = "Normal" or A_GuiEvent = "DoubleClick")
	{
		LV_GetText(clickedFile, A_EventInfo, 6)
		LV_GetText(accountFilter, A_EventInfo, 1)
		GetAccountCode(clickedFile, accountCode)
		PopulateHeroListView(charDir)
	}
	else if (A_GuiEvent = "ColClick" and A_EventInfo = 4) ; date sorting hack
	{
		accountDateSorting := (accountDateSorting = "Sort") ? "SortDesc" : "Sort"
		LV_ModifyCol(5, accountDateSorting)
	}
return

AccountFilterEvent:
	GuiControlGet, accountFilter,, AccountFilterChoice
	if (accountFilter = "None")
	{
		accountFilter := ""
	}
	PopulateAccountListView(0)
	PopulateHeroListView(charDir)
return

HeroListViewEvent:
	Gui, ListView, HeroListView
	if (A_GuiEvent = "Normal" or A_GuiEvent = "DoubleClick")
	{
		LV_GetText(clickedFile, A_EventInfo, 10)
		GetCharacterCodes(clickedFile)
		HideAllGUI()
	}
	else if (A_GuiEvent = "ColClick" and A_EventInfo = 6) ; date sorting hack
	{
		heroDateSorting := (heroDateSorting = "Sort") ? "SortDesc" : "Sort"
		LV_ModifyCol(7, heroDateSorting)
	}
return

PioneerFilterChanged:
	GuiControlGet, pioneerOnly,, PioneerFilter
	if (pioneerOnly = 1)
	{
		GuiControl,, EmpTowerFilter, 0
		empTowerOnly := 0
	}
	PopulateHeroListView(charDir)
return

EmpTowerChanged:
	GuiControlGet, empTowerOnly,, EmpTowerFilter
	if (empTowerOnly = 1)
	{
		GuiControl,, PioneerFilter, 0
		pioneerOnly := 0
	}
	PopulateHeroListView(charDir)
return

FileMenuSettings:
	ShowSettingsUI()
return

FileMenuHelp:
	MsgBox, TKoK Loader version 3`nIf you need help, have questions, or found a bug, please contact Irydion#0427 on discord.
return

FileMenuQuit:
ExitApp

AccountMenuSelect:
	FileSelectFile, accountFilename, 3, %savedFilesPath%, Account file, Text Documents (*.txt)
	GetAccountCode(accountFilename, accountCode)
return

LoadHeroHotkeyClear:
	GuiControl, 2:, LoadHeroHotkey, None
return

LoadAccountHotkeyClear:
	GuiControl, 2:, LoadAccountHotkey, None
return

RefreshCodesHotkeyClear:
	GuiControl, 2:, RefreshCodesHotkey, None
return

RefreshCodesHeroHotkeyClear:
	GuiControl, 2:, RefreshCodesHeroHotkey, None
return

ShowHeroSelectionHotkeyClear:
	GuiControl, 2:, ShowHeroSelectionHotkey, None
return

AvnosPuzzleHotkeyClear:
	GuiControl, 2:, AvnosPuzzleHotkey, None
return

TrialsPortalsHotkeyClear:
	GuiControl, 2:, TrialsPortalsHotkey, None
return

ClearTextHotkeyClear:
	GuiControl, 2:, ClearTextHotkey, None
return

InventoryHotkeyClear:
	GuiControl, 2:, InventoryHotkey, None
return

LoadHeroHotkeyHelp:
	MsgBox,, Load hero help, Use this hotkey to load the selected hero in game. It will automatically use the according -loadwith, -l, -l2, and -cdist if needed.
return

LoadAccountHotkeyHelp:
	MsgBox,, Load account help, Use this hotkey to load the selected account in game (or the most recent account if none has been selected). It will automatically use the according -la command.
return

RefreshCodesHotkeyHelp:
	MsgBox,, Refresh codes help, Use this hotkey to get the most recent hero and account codes from the currently selected hero. This can be used to load the new codes after saving in game (useful for rmk).
return

RefreshCodesHeroHotkeyHelp:
	MsgBox,, Refresh codes hero help, Use this hotkey to get the most recent hero codes from the currently selected hero. This will not try to change the currently selected account code.
return

ShowHeroSelectionHotkeyHelp:
	MsgBox,, Show hero selection help, Use this hotkey to show the main TKoK Loader window.
return

AvnosPuzzleHotkeyHelp:
	MsgBox,, Avnos puzzle help, Press this hotkey followed by 1, 2, 3, 5, or 6 to display the corresponding avnos puzzle sequence in chat. Pressing anything else after this hotkey will cancel it without showing anything in chat.
return

TrialsPortalsHotkeyHelp:
	MsgBox,, Trials portals help, Press this hotkey to display Grom Gol's trials portal sequences in chat. Will display all 4 possible sequences.
return

ClearTextHotkeyHelp:
	MsgBox,, Clear text help, Use this hotkey to clear any displayed text in game. It sends the z command in chat.
return

InventoryHotkeyHelp:
	MsgBox,, Inventory help, Use this hotkey to show your inventory. It sends the -inv command in chat.
return

SettingsCancelButton:
	Gui, 2:Hide
	reloadAccountsOnSave = 0
return

SettingsSaveButton:
	Gui, 2:Submit
	GuiControlGet, loadHeroHotkey,, LoadHeroHotkey
	GuiControlGet, loadAccountHotkey,, LoadAccountHotkey
	GuiControlGet, refreshCodesHotkey,, RefreshCodesHotkey
	GuiControlGet, refreshCodesHeroHotkey,, RefreshCodesHeroHotkey
	GuiControlGet, showHeroSelectionHotkey,, ShowHeroSelectionHotkey
	GuiControlGet, avnosPuzzleHotkey,, AvnosPuzzleHotkey
	GuiControlGet, trialsPortalsHotkey,, TrialsPortalsHotkey
	GuiControlGet, clearTextHotkey,, ClearTextHotkey
	GuiControlGet, inventoryHotkey,, InventoryHotkey
	GuiControlGet, cameraDistance,, CameraDistanceEdit
	GuiControlGet, savedFilesPath,, ChangePathValue
	GuiControlGet, inputDelay,, InputDelayValue
	GuiControlGet, enableSounds,, EnableSoundsValue
	
	IniWrite, %loadHeroHotkey%, %configFile%, HOTKEYS, loadHero
	IniWrite, %loadAccountHotkey%, %configFile%, HOTKEYS, loadAccount
	IniWrite, %refreshCodesHotkey%, %configFile%, HOTKEYS, refreshCodes
	IniWrite, %refreshCodesHeroHotkey%, %configFile%, HOTKEYS, refreshCodesHero
	IniWrite, %showHeroSelectionHotkey%, %configFile%, HOTKEYS, showHeroSelection
	IniWrite, %avnosPuzzleHotkey%, %configFile%, HOTKEYS, avnosPuzzle
	IniWrite, %trialsPortalsHotkey%, %configFile%, HOTKEYS, trialsPortals
	IniWrite, %clearTextHotkey%, %configFile%, HOTKEYS, clearText
	IniWrite, %inventoryHotkey%, %configFile%, HOTKEYS, inventory
	
	IniWrite, %cameraDistance%, %configFile%, OTHER, cdist
	IniWrite, %savedFilesPath%, %configFile%, OTHER, savePath
	IniWrite, %inputDelay%, %configFile%, OTHER, inputDelay
	IniWrite, %enableSounds%, %configFile%, OTHER, enableSounds
	
	LoadSettings()
	
	if (reloadAccountsOnSave = 1)
	{
		SetTimer, RefreshListsOnPathChanged, -100 ; delay the list refresh or it doesn't work...
		reloadAccountsOnSave = 0
	}
return

RefreshListsOnPathChanged:
	PopulateAccountListView(1)
	ShowCharacterUI()
	Gui, ListView, HeroListView
	LV_Delete()
return

ChangePathButtonClicked:
	FileSelectFolder, savedFilesPath,,, Select TKoK save folder
	if (ErrorLevel = 0)
	{
		GuiControl,, ChangePathValue, %savedFilesPath%
		reloadAccountsOnSave = 1
	}
return