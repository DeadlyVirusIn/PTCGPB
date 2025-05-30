#Include %A_ScriptDir%\Scripts\Include\
#Include Logging.ahk
#Include ADB.ahk
#Include Dictionary.ahk

version = Arturos PTCGP Bot
#SingleInstance, force
CoordMode, Mouse, Screen
SetTitleMatchMode, 3

OnError("ErrorHandler")  ; Add this line here

global STATIC_BRUSH := 0

githubUser := "mixman208"
repoName := "PTCGPB"
localVersion := "v6.4.7"
scriptFolder := A_ScriptDir
zipPath := A_Temp . "\update.zip"
extractPath := A_Temp . "\update"
intro := "New GUI Update!/EC Added"

; GUI dimensions constants
global GUI_WIDTH := 377 ; Adjusted from 510 to 480
global GUI_HEIGHT := 677 ; Adjusted from 850 to 750

; Image scaling and ratio constants for 720p compatibility
global IMG_SCALE_RATIO := 0.5625 ; 720/1280 for aspect ratio preservation
global UI_ELEMENT_SCALE := 0.85 ; Scale UI elements to fit smaller dimensions

; Added new global variable for background image toggle
global useBackgroundImage := true

global scriptName, winTitle, FriendID, Instances, instanceStartDelay, jsonFileName, PacksText, runMain, Mains, AccountName, scaleParam
global CurrentVisibleSection
global FriendID_Divider, Instance_Divider3
global System_Divider1, System_Divider2, System_Divider3, System_Divider4
global Pack_Divider1, Pack_Divider2, Pack_Divider3
global SaveForTradeDivider_1, SaveForTradeDivider_2
global Discord_Divider3
global tesseractPath, applyRoleFilters, debugMode, statusMessage
global tesseractOption
global spendHourGlass
global rowGap
global injectSortMethodCreated := false
global injectSortMethod := "ModifiedAsc" ; Default sort method
global SortMethodLabel, InjectSortMethodDropdown
global sortByCreated := false
global SortByText, SortByDropdown
global showcaseLikes, showcaseURL, skipMissionsInjectMissions
global minStarsA1Mewtwo, minStarsA1Charizard, minStarsA1Pikachu, minStarsA1a
global minStarsA2Dialga, minStarsA2Palkia, minStarsA2a, minStarsA2b
global minStarsA3Solgaleo, minStarsA3Lunala, minStarsA3a
global waitForEligibleAccounts, maxWaitHours
global finishSignalFile := A_ScriptDir "\Scripts\Include\finish.signal"

if not A_IsAdmin
{
    ; Relaunch script with admin rights
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

;; Language Selections
; ========== language Selection ==========
global IsLanguageSet, defaultBotLanguage
IniRead, IsLanguageSet, Settings.ini, UserSettings, IsLanguageSet, 0
IniRead, defaultBotLanguage, Settings.ini, UserSettings, defaultBotLanguage, 0
IniRead, BotLanguage, Settings.ini, UserSettings, BotLanguage, English

if (!IsLanguageSet) {
    ; build language select
    Gui, Add, Text,, Select Language
    BotLanguagelist := "English|中文|日本語|Deutsch"
    if (BotLanguage != "")
    {
        index := 0
        Loop, Parse, BotLanguagelist, |
        {
            index++
            if (A_LoopField = BotLanguage)
            {
                defaultChooseLang := index
                break
            }
        }
    }
    Gui, Add, DropDownList, vBotLanguage w200 choose%defaultChooseLang%, %BotLanguagelist%
    Gui, Add, Button, Default gNextStep, Next
    Gui, Show,, Language Selection
    Return
}

; Next be clicked
NextStep:
    Gui, Submit
    
    if (BotLanguage = "English")
        defaultBotLanguage := 1
    else if (BotLanguage = "中文")
        defaultBotLanguage := 2
    else if (BotLanguage = "日本語")
        defaultBotLanguage := 3
    else if (BotLanguage = "Deutsch")
        defaultBotLanguage := 4
    
    IniWrite, 1, Settings.ini, UserSettings, IsLanguageSet
    IniWrite, %defaultBotLanguage%, Settings.ini, UserSettings, defaultBotLanguage
    IniWrite, %BotLanguage%, Settings.ini, UserSettings, BotLanguage
    Gui, Destroy
    
    ; Define Language Dictionary
    global LicenseDictionary, ProxyDictionary, currentDictionary, SetUpDictionary, HelpDictionary
    LicenseDictionary := CreateLicenseNoteLanguage(defaultBotLanguage)
    ProxyDictionary := CreateProxyLanguage(defaultBotLanguage)
    currentDictionary := CreateGUITextByLanguage(defaultBotLanguage, localVersion)
    SetUpDictionary := CreateSetUpByLanguage(defaultBotLanguage)
    HelpDictionary := CreateHelpByLanguage(defaultBotLanguage)
    
    RegRead, proxyEnabled, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings, ProxyEnable
    
    ; Check for debugMode and display license notification if not in debug mode
    IniRead, debugMode, Settings.ini, UserSettings, debugMode, 0
    if (!debugMode) ; <------------- New modify
    {
        title := LicenseDictionary.Title
        content := LicenseDictionary.Content
        MsgBox, 64, %title%, %content%
        
        if (proxyEnabled){
            notice := ProxyDictionary.Notice
            MsgBox, 64,, %notice%
        }
    }
    
    ;; Color Decide
    ; Define refined global color variables for consistent theming
    global DARK_BG := "3d3d3d" ; Deeper blue-gray background
    global DARK_CONTROL_BG := "7C8590" ; Slightly lighter panel background
    global DARK_ACCENT := "81A1C1" ; Lighter blue accent (changed to match section colors)
    global DARK_TEXT := "FDFDFD" ; Crisp white text with slight blue tint
    global DARK_TEXT_SECONDARY := "FDFDFD" ; Slightly dimmed secondary text
    
    global LIGHT_BG := "e9f1f7" ; Soft light background with blue hint
    global LIGHT_CONTROL_BG := "7C8590" ; Pure white for controls
    global LIGHT_ACCENT := "2E5984" ; Darker accent (changed to match section colors)
    global LIGHT_TEXT := "717F94" ; Dark text that matches dark mode background
    global LIGHT_TEXT_SECONDARY := "717F94" ; Medium gray with blue tint
    
    ; Define input field colors for light and dark themes
    global DARK_INPUT_BG := "7C8590" ; Slightly lighter than control background
    global DARK_INPUT_TEXT := "FDFDFD" ; Same as main text
    global LIGHT_INPUT_BG := "7C8590" ; Light gray with blue tint
    global LIGHT_INPUT_TEXT := "FDFDFD" ; Dark text
    
    ; Define Pages' colors for light and dark themes
    global DARK_BTN_TEXT := "000000"
    global DARK_PAGE_BTN_TEXT := "E9F3F7"
    global DARK_PAGE_TEXT := "FDFDFD"
    global LIGHT_BTN_TEXT := "717F94"
    global LIGHT_PAGE_BTN_TEXT := "E9F3F7"
    global LIGHT_PAGE_TEXT := "292929"
    
    ; Section colors - Dark theme
    global DARK_SECTION_COLORS := {}
    DARK_SECTION_COLORS["RerollSettings"] := "FDFDFD" ; Lighter Blue for better visibility on dark background
    DARK_SECTION_COLORS["FriendID"] := "FDFDFD" ; Lighter Blue
    DARK_SECTION_COLORS["InstanceSettings"] := "FDFDFD" ; Lighter Blue
    DARK_SECTION_COLORS["TimeSettings"] := "FDFDFD" ; Lighter Blue
    DARK_SECTION_COLORS["SystemSettings"] := "FDFDFD" ; Lighter Teal for dark background
    DARK_SECTION_COLORS["PackSettings"] := "FDFDFD" ; Lighter Purple for visibility
    DARK_SECTION_COLORS["SaveForTrade"] := "FDFDFD" ; Lighter Orange
    DARK_SECTION_COLORS["DiscordSettings"] := "FDFDFD" ; Lighter Discord Blue
    DARK_SECTION_COLORS["DownloadSettings"] := "FDFDFD" ; Light Green
    
    ; Section colors - Light theme
    global LIGHT_SECTION_COLORS := {}
    LIGHT_SECTION_COLORS["RerollSettings"] := "3E4756" ; Dark Blue for contrast on light background
    LIGHT_SECTION_COLORS["FriendID"] := "3E4756" ; Dark Blue
    LIGHT_SECTION_COLORS["InstanceSettings"] := "3E4756" ; Dark Blue
    LIGHT_SECTION_COLORS["TimeSettings"] := "3E4756" ; Dark Blue
    LIGHT_SECTION_COLORS["SystemSettings"] := "3E4756" ; Dark Teal
    LIGHT_SECTION_COLORS["PackSettings"] := "3E4756" ; Dark Purple
    LIGHT_SECTION_COLORS["SaveForTrade"] := "3E4756" ; Dark Orange
    LIGHT_SECTION_COLORS["DiscordSettings"] := "3E4756" ; Darker Discord Blue
    LIGHT_SECTION_COLORS["DownloadSettings"] := "3E4756" ; Darker Green
    
    IsNumeric(var) {
        if var is number
            return true
        return false
    }
    
    ;; Font Setting
    ; Improved font functions with better hierarchy and reduced sizes
    SetPageTitleFont() {
        global isDarkTheme, DARK_PAGE_TEXT, LIGHT_PAGE_TEXT
        
        if (isDarkTheme)
            Gui, Font, norm s12 c%DARK_PAGE_TEXT%, Segoe UI
        else
            Gui, Font, norm s12 c%LIGHT_PAGE_TEXT%, Segoe UI
    }
    
    SetSmallBtnFont() { ;For toolbar e.g. background,theme
        global isDarkTheme, DARK_PAGE_TEXT, LIGHT_PAGE_TEXT
        
        if (isDarkTheme)
            Gui, Font, underline s8 c%DARK_PAGE_TEXT%, Verdana
        else
            Gui, Font, underline s8 c%LIGHT_PAGE_TEXT%, Verdana
    }
    
    SetSmallBtnText() {
        global isDarkTheme, useBackgroundImage, currentDictionary
        
        if (isDarkTheme) {
            controlName := currentDictionary.btn_theme_Light
            GuiControl,, ThemeToggle, %controlName%
        } else {
            controlName := currentDictionary.btn_theme_Dark
            GuiControl,, ThemeToggle, %controlName%
        }
        
        if (useBackgroundImage) {
            controlName := currentDictionary.btn_bg_Off
            GuiControl,, BackgroundToggle, %controlName%
        } else {
            controlName := currentDictionary.btn_bg_On
            GuiControl,, BackgroundToggle, %controlName%
        }
    }
    
    SetLicenseFont() { ; For cc licence message
        global isDarkTheme, DARK_PAGE_TEXT, LIGHT_PAGE_TEXT
        if (isDarkTheme)
            Gui, Font, norm s7 c%DARK_PAGE_TEXT%, Segoe UI
        else
            Gui, Font, norm s7 c%LIGHT_PAGE_TEXT%, Segoe UI
    }
    
    SetPanelBtnFont() { ; For button on the panel e.g. Start Bot, Arrange Windows
        global isDarkTheme, DARK_BTN_TEXT, LIGHT_PAGE_TEXT, defaultBotLanguage
        if (isDarkTheme)
            if(defaultBotLanguage = 2 || defaultBotLanguage = 3)
                Gui, Font, norm s11 c%DARK_BTN_TEXT%, Segoe UI
            else
                Gui, Font, norm s13 c%DARK_BTN_TEXT%, Segoe UI
        else
            if(defaultBotLanguage = 2 || defaultBotLanguage = 3)
                Gui, Font, norm s11 c%LIGHT_BTN_TEXT%, Segoe UI
            else
                Gui, Font, norm s13 c%LIGHT_BTN_TEXT%, Segoe UI
    }
    
    SetPageBtnFont() { ; For the Button at the bottom e.g. Main Page
        global isDarkTheme, DARK_PAGE_BTN_TEXT, LIGHT_PAGE_BTN_TEXT
        if (isDarkTheme)
            if(defaultBotLanguage = 2 || defaultBotLanguage = 3)
                Gui, Font, norm s12 c%DARK_PAGE_BTN_TEXT%, Segoe UI
            else
                Gui, Font, norm s15 c%DARK_PAGE_BTN_TEXT%, Segoe UI
        else
            if(defaultBotLanguage = 2 || defaultBotLanguage = 3)
                Gui, Font, norm s12 c%LIGHT_PAGE_BTN_TEXT%, Segoe UI
            else
                Gui, Font, norm s15 c%LIGHT_PAGE_BTN_TEXT%, Segoe UI
    }
    
    SetArturoFont() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT
        if (isDarkTheme)
            Gui, Font, s12 bold c%DARK_TEXT%, Segoe UI
        else
            Gui, Font, s12 bold c%LIGHT_TEXT%, Segoe UI
    }
    
    SetTitleFont() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT
        if (isDarkTheme)
            Gui, Font, s10 bold c%DARK_TEXT%, Segoe UI
        else
            Gui, Font, s10 bold c%LIGHT_TEXT%, Segoe UI
    }
    
    SetSectionFont() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT
        if (isDarkTheme)
            Gui, Font, norm s10 bold c%DARK_TEXT%, Segoe UI ; Reduced from s12
        else
            Gui, Font, norm s10 bold c%LIGHT_TEXT%, Segoe UI
    }
    
    SetHeaderFont() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT
        if (isDarkTheme)
            Gui, Font, s9 bold c%DARK_TEXT%, Segoe UI ; Reduced from s10
        else
            Gui, Font, s9 bold c%LIGHT_TEXT%, Segoe UI
    }
    
    SetNormalFont() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT
        if (isDarkTheme)
            Gui, Font, norm s9 c%DARK_TEXT%, Segoe UI ; Reduced from s9
        else
            Gui, Font, norm s9 c%LIGHT_TEXT%, Segoe UI
    }
    
    SetSmallFont() {
        global isDarkTheme, DARK_TEXT_SECONDARY, LIGHT_TEXT_SECONDARY
        if (isDarkTheme)
            Gui, Font, norm s7 c%DARK_TEXT_SECONDARY%, Segoe UI ; Reduced from s8
        else
            Gui, Font, norm s7 c%LIGHT_TEXT_SECONDARY%, Segoe UI
    }
    
    SetInputFont() {
        global isDarkTheme, DARK_INPUT_TEXT, LIGHT_INPUT_TEXT
        if (isDarkTheme)
            Gui, Font, norm s9 c%DARK_INPUT_TEXT%, Segoe UI ; Reduced from s9
        else
            Gui, Font, norm s9 c%LIGHT_INPUT_TEXT%, Segoe UI
    }
    
    ; ===== NEW: Helper Functions for Code Optimization =====
    
    ;; ApplyTheme Functions
    ;Function to apply Page Text based on current theme
    ApplyPageTextColor(controlName) {
        global isDarkTheme, Dark_PAGE_TEXT, LIGHT_PAGE_TEXT
        
        pageTextColor := isDarkTheme ? DARK_PAGE_TEXT : LIGHT_PAGE_TEXT
        GuiControl, +c%pageTxetColor% , %controlName%
    }
    
    ApplyPageTextColorToMutiple(controlList) {
        Loop, Parse, controlList, `,
        {
            if (A_LoopField){
                ApplyPageTextColor(A_LoopField)
            }
        }
    }
    
    ;Function to apply Btn Text based on current theme
    ApplyBtnTextColor(controlName) {
        global isDarkTheme, DARK_BTN_TEXT, LIGHT_BTN_TEXT
        
        btnTextColor := isDarkTheme ? DARK_BTN_TEXT : LIGHT_BTN_TEXT
        GuiControl, +c%btnTextColor% , %controlName%
    }
    
    ApplyBtnTextColorToMutiple(controlList) {
        Loop, Parse, controlList, `,
        {
            if (A_LoopField) {
                ApplyBtnTextColor(A_LoopField)
            }
        }
    }
    
    ApplyPageBtnTextColor(controlName) {
        global isDarkTheme, Dark_PAGE_BTN_TEXT, LIGHT_PAGE_BTN_TEXT
        
        pageBtnTextColor := isDarkTheme ? DARK_PAGE_BTN_TEXT : LIGHT_PAGE_BTN_TEXT
        GuiControl, +c%pageBtnTxetColor% , %controlName%
    }
    
    ApplyPageBtnTextColorToMutiple(controlList) {
        Loop, Parse, controlList, `,
        {
            if (A_LoopField){
                ApplyPageBtnTextColor(A_LoopField)
            }
        }
    }
    
    ; Function to apply text color based on current theme
    ApplyTextColor(controlName) {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT
        
        textColor := isDarkTheme ? DARK_TEXT : LIGHT_TEXT
        GuiControl, +c%textColor%, %controlName%
    }
    
    ; Function to apply input field styling based on current theme
    ApplyInputStyle(controlName) {
        global isDarkTheme, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
        
        inputBgColor := isDarkTheme ? DARK_INPUT_BG : LIGHT_INPUT_BG
        inputTextColor := isDarkTheme ? DARK_INPUT_TEXT : LIGHT_INPUT_TEXT
        GuiControl, +Background%inputBgColor% +c%inputTextColor%, %controlName%
    }
    
    ; Function to apply style to multiple text controls at once
    ApplyTextColorToMultiple(controlList) {
        Loop, Parse, controlList, `,
        {
            if (A_LoopField){
                ApplyTextColor(A_LoopField)
            }
        }
    }
    
    ; Function to apply style to multiple input fields at once
    ApplyInputStyleToMultiple(controlList) {
        Loop, Parse, controlList, `,
        {
            if (A_LoopField){
                ApplyInputStyle(A_LoopField)
        } }
    }
    
    ; Unified function to save all settings to INI file - FIXED VERSION
    SaveAllSettings() {
        global FriendID, AccountName, waitTime, Delay, folderPath, discordWebhookURL, discordUserId, Columns, godPack
        global Instances, instanceStartDelay, defaultLanguage, SelectedMonitorIndex, swipeSpeed, deleteMethod
        global runMain, Mains, heartBeat, heartBeatWebhookURL, heartBeatName, nukeAccount, packMethod
        global CheckShinyPackOnly, TrainerCheck, FullArtCheck, RainbowCheck, ShinyCheck, CrownCheck
        global InvalidCheck, ImmersiveCheck, PseudoGodPack, minStars, Palkia, Dialga, Arceus, Shining
        global Mew, Pikachu, Charizard, Mewtwo, Solgaleo, Lunala, Buzzwole, slowMotion, ocrLanguage, clientLanguage, autoLaunchMonitor
        global CurrentVisibleSection, heartBeatDelay, sendAccountXml, showcaseEnabled, showcaseURL, isDarkTheme
        global useBackgroundImage, tesseractPath, applyRoleFilters, debugMode, tesseractOption, statusMessage
        global s4tEnabled, s4tSilent, s4t3Dmnd, s4t4Dmnd, s4t1Star, s4tGholdengo, s4tWP, s4tWPMinCards
        global s4tDiscordUserId, s4tDiscordWebhookURL, s4tSendAccountXml, minStarsShiny, instanceLaunchDelay, mainIdsURL, vipIdsURL
        global spendHourGlass, injectSortMethod, rowGap, SortByDropdown
        global waitForEligibleAccounts, maxWaitHours, skipMissionsInjectMissions
        
        ; === MISSING ADVANCED SETTINGS VARIABLES ===
        global minStarsA1Mewtwo, minStarsA1Charizard, minStarsA1Pikachu, minStarsA1a
        global minStarsA2Dialga, minStarsA2Palkia, minStarsA2a, minStarsA2b
        global minStarsA3Solgaleo, minStarsA3Lunala, minStarsA3a
        
        ; FIXED: Make sure all values are properly synced from GUI before saving
        Gui, Submit, NoHide
        
        ; FIXED: Explicitly get the deleteMethod from the dropdown control with validation
        GuiControlGet, currentDeleteMethod,, deleteMethod
        if (currentDeleteMethod != "" && currentDeleteMethod != "ERROR") {
            deleteMethod := currentDeleteMethod
        } else if (deleteMethod = "" || deleteMethod = "ERROR") {
            ; Set default if empty or invalid
            deleteMethod := "13 Pack"
        }
        
        ; FIXED: Validate deleteMethod against known valid options
        validMethods := "13 Pack|Inject|Inject Missions|Inject for Reroll"
        if (!InStr(validMethods, deleteMethod)) {
            deleteMethod := "13 Pack" ; Reset to default if invalid
        }
        
        ; Update injectSortMethod based on dropdown if available
        if (sortByCreated) {
            GuiControlGet, selectedOption,, SortByDropdown
            if (selectedOption = "Oldest First")
                injectSortMethod := "ModifiedAsc"
            else if (selectedOption = "Newest First")
                injectSortMethod := "ModifiedDesc"
            else if (selectedOption = "Fewest Packs First")
                injectSortMethod := "PacksAsc"
            else if (selectedOption = "Most Packs First")
                injectSortMethod := "PacksDesc"
        }
        
        ; FIXED: Save deleteMethod first with validation
        IniWrite, %deleteMethod%, Settings.ini, UserSettings, deleteMethod
        
        ; Save pack selections directly without resetting them
        IniWrite, %Palkia%, Settings.ini, UserSettings, Palkia
        IniWrite, %Dialga%, Settings.ini, UserSettings, Dialga
        IniWrite, %Arceus%, Settings.ini, UserSettings, Arceus
        IniWrite, %Shining%, Settings.ini, UserSettings, Shining
        IniWrite, %Mew%, Settings.ini, UserSettings, Mew
        IniWrite, %Pikachu%, Settings.ini, UserSettings, Pikachu
        IniWrite, %Charizard%, Settings.ini, UserSettings, Charizard
        IniWrite, %Mewtwo%, Settings.ini, UserSettings, Mewtwo
        IniWrite, %Solgaleo%, Settings.ini, UserSettings, Solgaleo
        IniWrite, %Lunala%, Settings.ini, UserSettings, Lunala
        IniWrite, %Buzzwole%, Settings.ini, UserSettings, Buzzwole
        
        ; Save basic settings
        IniRead, deleteMethod, Settings.ini, UserSettings, deleteMethod
        if (deleteMethod = "Inject for Reroll") {
            IniWrite, %FriendID%, Settings.ini, UserSettings, FriendID
        } else {
            IniWrite, "", Settings.ini, UserSettings, FriendID
        }
        IniWrite, %AccountName%, Settings.ini, UserSettings, AccountName
        IniWrite, %waitTime%, Settings.ini, UserSettings, waitTime
        IniWrite, %Delay%, Settings.ini, UserSettings, Delay
        IniWrite, %folderPath%, Settings.ini, UserSettings, folderPath
        IniWrite, %discordWebhookURL%, Settings.ini, UserSettings, discordWebhookURL
        IniWrite, %discordUserId%, Settings.ini, UserSettings, discordUserId
        IniWrite, %Columns%, Settings.ini, UserSettings, Columns
        IniWrite, %godPack%, Settings.ini, UserSettings, godPack
        IniWrite, %Instances%, Settings.ini, UserSettings, Instances
        IniWrite, %instanceStartDelay%, Settings.ini, UserSettings, instanceStartDelay
        IniWrite, %defaultLanguage%, Settings.ini, UserSettings, defaultLanguage
        IniWrite, %rowGap%, Settings.ini, UserSettings, rowGap
        IniWrite, %SelectedMonitorIndex%, Settings.ini, UserSettings, SelectedMonitorIndex
        IniWrite, %swipeSpeed%, Settings.ini, UserSettings, swipeSpeed
        IniWrite, %runMain%, Settings.ini, UserSettings, runMain
        IniWrite, %Mains%, Settings.ini, UserSettings, Mains
        IniWrite, %heartBeat%, Settings.ini, UserSettings, heartBeat
        IniWrite, %heartBeatWebhookURL%, Settings.ini, UserSettings, heartBeatWebhookURL
        IniWrite, %heartBeatName%, Settings.ini, UserSettings, heartBeatName
        IniWrite, %heartBeatDelay%, Settings.ini, UserSettings, heartBeatDelay
        IniWrite, %nukeAccount%, Settings.ini, UserSettings, nukeAccount
        IniWrite, %packMethod%, Settings.ini, UserSettings, packMethod
        IniWrite, %CheckShinyPackOnly%, Settings.ini, UserSettings, CheckShinyPackOnly
        IniWrite, %TrainerCheck%, Settings.ini, UserSettings, TrainerCheck
        IniWrite, %FullArtCheck%, Settings.ini, UserSettings, FullArtCheck
        IniWrite, %RainbowCheck%, Settings.ini, UserSettings, RainbowCheck
        IniWrite, %ShinyCheck%, Settings.ini, UserSettings, ShinyCheck
        IniWrite, %CrownCheck%, Settings.ini, UserSettings, CrownCheck
        IniWrite, %InvalidCheck%, Settings.ini, UserSettings, InvalidCheck
        IniWrite, %ImmersiveCheck%, Settings.ini, UserSettings, ImmersiveCheck
        IniWrite, %PseudoGodPack%, Settings.ini, UserSettings, PseudoGodPack
        IniWrite, %minStars%, Settings.ini, UserSettings, minStars
        IniWrite, %slowMotion%, Settings.ini, UserSettings, slowMotion
        IniWrite, %ocrLanguage%, Settings.ini, UserSettings, ocrLanguage
        IniWrite, %clientLanguage%, Settings.ini, UserSettings, clientLanguage
        IniWrite, %mainIdsURL%, Settings.ini, UserSettings, mainIdsURL
        IniWrite, %vipIdsURL%, Settings.ini, UserSettings, vipIdsURL
        IniWrite, %autoLaunchMonitor%, Settings.ini, UserSettings, autoLaunchMonitor
        IniWrite, %instanceLaunchDelay%, Settings.ini, UserSettings, instanceLaunchDelay
        IniWrite, %spendHourGlass%, Settings.ini, UserSettings, spendHourGlass
        IniWrite, %injectSortMethod%, Settings.ini, UserSettings, injectSortMethod
        IniWrite, %waitForEligibleAccounts%, Settings.ini, UserSettings, waitForEligibleAccounts
        IniWrite, %maxWaitHours%, Settings.ini, UserSettings, maxWaitHours
        
        IniWrite, %showcaseURL%, Settings.ini, UserSettings, showcaseURL
        IniWrite, %skipMissionsInjectMissions%, Settings.ini, UserSettings, skipMissionsInjectMissions
        
        ; Save showcase settings
        IniWrite, %showcaseEnabled%, Settings.ini, UserSettings, showcaseEnabled
        IniWrite, 5, Settings.ini, UserSettings, showcaseLikes
        
        IniWrite, %minStarsA1Mewtwo%, Settings.ini, UserSettings, minStarsA1Mewtwo
        IniWrite, %minStarsA1Charizard%, Settings.ini, UserSettings, minStarsA1Charizard
        IniWrite, %minStarsA1Pikachu%, Settings.ini, UserSettings, minStarsA1Pikachu
        IniWrite, %minStarsA1a%, Settings.ini, UserSettings, minStarsA1a
        IniWrite, %minStarsA2Dialga%, Settings.ini, UserSettings, minStarsA2Dialga
        IniWrite, %minStarsA2Palkia%, Settings.ini, UserSettings, minStarsA2Palkia
        IniWrite, %minStarsA2a%, Settings.ini, UserSettings, minStarsA2a
        IniWrite, %minStarsA2b%, Settings.ini, UserSettings, minStarsA2b
        IniWrite, %minStarsA3Solgaleo%, Settings.ini, UserSettings, minStarsA3Solgaleo
        IniWrite, %minStarsA3Lunala%, Settings.ini, UserSettings, minStarsA3Lunala
        IniWrite, %minStarsA3a%, Settings.ini, UserSettings, minStarsA3a
        
        IniWrite, %sendAccountXml%, Settings.ini, UserSettings, sendAccountXml
        
        ; Save S4T settings
        IniWrite, %s4tEnabled%, Settings.ini, UserSettings, s4tEnabled
        IniWrite, %s4tSilent%, Settings.ini, UserSettings, s4tSilent
        IniWrite, %s4t3Dmnd%, Settings.ini, UserSettings, s4t3Dmnd
        IniWrite, %s4t4Dmnd%, Settings.ini, UserSettings, s4t4Dmnd
        IniWrite, %s4t1Star%, Settings.ini, UserSettings, s4t1Star
        IniWrite, %s4tGholdengo%, Settings.ini, UserSettings, s4tGholdengo
        IniWrite, %s4tWP%, Settings.ini, UserSettings, s4tWP
        IniWrite, %s4tWPMinCards%, Settings.ini, UserSettings, s4tWPMinCards
        IniWrite, %s4tDiscordUserId%, Settings.ini, UserSettings, s4tDiscordUserId
        IniWrite, %s4tDiscordWebhookURL%, Settings.ini, UserSettings, s4tDiscordWebhookURL
        IniWrite, %s4tSendAccountXml%, Settings.ini, UserSettings, s4tSendAccountXml
        IniWrite, %minStarsShiny%, Settings.ini, UserSettings, minStarsShiny
        
        ; Save extra settings
        IniWrite, %tesseractPath%, Settings.ini, UserSettings, tesseractPath
        IniWrite, %applyRoleFilters%, Settings.ini, UserSettings, applyRoleFilters
        IniWrite, %debugMode%, Settings.ini, UserSettings, debugMode
        IniWrite, %tesseractOption%, Settings.ini, UserSettings, tesseractOption
        IniWrite, %statusMessage%, Settings.ini, UserSettings, statusMessage
        
        ; Save theme settings
        IniWrite, %isDarkTheme%, Settings.ini, UserSettings, isDarkTheme
        IniWrite, %useBackgroundImage%, Settings.ini, UserSettings, useBackgroundImage
        
        ; FIXED: Debug logging if enabled
        if (debugMode) {
            FileAppend, % A_Now . " - Settings saved. DeleteMethod: " . deleteMethod . "`n", %A_ScriptDir%\debug_settings.log
        }
    }
    
    ; Function to update ALL text controls with appropriate color
    SetAllTextColors(textColor) {
        ; Create a string with all control names separated by commas
        controlList := "Txt_Instances,Txt_InstanceStartDelay,Txt_Columns,Txt_runMain,Txt_AccountName,"
        controlList .= "Txt_Delay,Txt_WaitTime,Txt_SwipeSpeed,Txt_slowMotion,"
        controlList .= "Txt_Monitor,Txt_Scale,Txt_FolderPath,Txt_OcrLanguage,Txt_ClientLanguage,"
        controlList .= "Txt_RowGap,Txt_InstanceLaunchDelay,Txt_autoLaunchMonitor,"
        controlList .= "Txt_MinStars,Txt_ShinyMinStars,Txt_DeleteMethod,Txt_packMethod,Txt_nukeAccount,"
        controlList .= "Txt_VariablePackCount,Txt_spendHourGlass,SortByText,"
        controlList .= "Txt_Buzzwole,Txt_Solgaleo,Txt_Lunala,Txt_Shining,Txt_Arceus,Txt_Palkia,Txt_Dialga,Txt_Pikachu,Txt_Charizard,Txt_Mewtwo,Txt_Mew,"
        controlList .= "AllPackSelection,Txt_PackHeading,Txt_PageBuzzwole,Txt_PageSolgaleo,Txt_PageLunala,Txt_PageShining,"
        controlList .= "Txt_FullArtCheck,Txt_TrainerCheck,Txt_RainbowCheck,Txt_PseudoGodPack,"
        controlList .= "Txt_CrownCheck,Txt_ShinyCheck,Txt_ImmersiveCheck,Txt_CheckShiningPackOnly,Txt_InvalidCheck,"
        controlList .= "Txt_s4tEnabled,Txt_s4tSilent,Txt_s4t3Dmnd,Txt_s4t4Dmnd,Txt_s4t1Star,Txt_s4tWP,"
        controlList .= "s4tWPMinCardsLabel,s4tGholdengoArrow,"
        controlList .= "Txt_DiscordID,Txt_DiscordWebhook,Txt_sendAccountXml,"
        controlList .= "Txt_heartBeat,hbName,hbURL,hbDelay,"
        controlList .= "Txt_S4T_DiscordID,Txt_S4T_DiscordWebhook,Txt_s4tSendAccountXml,S4TDiscordSettingsSubHeading,"
        controlList .= "Txt_MainIdsURL,Txt_VipIdsURL,Txt_showcaseEnabled,"
        controlList .= "VersionInfo,HeaderTitle,"
        controlList .= "FriendIDLabel,InstanceSettingsLabel,TimeSettingsLabel,SystemSettingsLabel,"
        controlList .= "SaveForTradeLabel,DiscordSettingsLabel,DownloadSettingsLabel,"
        controlList .= "ExtraSettingsHeading,Txt_TesseractPath,"
        controlList .= "Txt_tesseractOption,Txt_applyRoleFilters,Txt_debugMode,Txt_statusMessage"
        
        ; Apply color to all controls in the list
        Loop, Parse, controlList, `,
        {
            if (A_LoopField)
                GuiControl, +c%textColor%, %A_LoopField%
        }
    }
    
    SetAllPagesColor(btnTxetColor, textColor, pageBtnTextColor) {
        TextControl := "Txt_title_set,Txt_title_main,Txt_license,Btn_ToolTip,Btn_Language,Btn_reload,BackgroundToggle,ThemeToggle,"
        TextControl .= "title_download,title_discord,title_trade,title_pack,title_system,title_reroll"
        
        BtnControl := "Txt_Btn_Arrange,Txt_Btn_Coffee,Txt_Btn_Join,Txt_Btn_Mumu,"
        BtnControl .= "Txt_Btn_BalanceXMLs,Txt_Btn_Start,Txt_Btn_Update,"
        BtnControl .= "Txt_Btn_RerollSettings,Txt_Btn_SystemSettings,Txt_Btn_PackSettings,"
        BtnControl .= "Txt_Btn_SaveForTrade,Txt_Btn_DiscordSettings,Txt_Btn_DownloadSettings"
        
        pageBtnControl := "Txt_Btn_main, Txt_Btn_Setting, Txt_Btn_inset, Txt_Btn_returnPack"
        ; Apply color to all controls in the list
        Loop, Parse, TextControl, `,
        {
            if (A_LoopField)
                GuiControl, +c%textColor%, %A_LoopField%
        }
        
        ; Apply color to all controls in the list
        ApplyBtnTextColorToMutiple(BtnControl)
        
        ; Apply color to all controls in the list
        ApplyPageBtnTextColorToMutiple(pageBtnControl)
    }
    
    ; Function to apply theme colors to the GUI
    ApplyTheme() {
        global isDarkTheme, DARK_BG, DARK_CONTROL_BG, DARK_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT
        global LIGHT_BG, LIGHT_CONTROL_BG, LIGHT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
        global CurrentVisibleSection, DARK_SECTION_COLORS, LIGHT_SECTION_COLORS
        global DARK_BTN_TEXT, DARK_PAGE_TEXT, DARK_PAGE_BTN_TEXT,LIGHT_BTN_TEXT, LIGHT_PAGE_TEXT, LIGHT_PAGE_BTN_TEXT
        
        if (isDarkTheme) {
            ; Dark theme with better contrast
            Gui, Color, %DARK_BG%, %DARK_CONTROL_BG%
            
            ; Update input fields for dark theme
            SetInputBackgrounds(DARK_INPUT_BG, DARK_INPUT_TEXT)
            
            ; Update all text labels with dark theme colors
            SetAllTextColors(DARK_TEXT)
            
            ; Update all btn texts and titles
            SetAllPagesColor(DARK_BTN_TEXT, DARK_PAGE_TEXT, DARK_PAGE_BTN_TEXT)
        } else {
            ; Light theme with better contrast
            Gui, Color, %LIGHT_BG%, %LIGHT_CONTROL_BG%
            
            ; Update input fields for light theme
            SetInputBackgrounds(LIGHT_INPUT_BG, LIGHT_INPUT_TEXT)
            
            ; Update all text labels with light theme colors
            SetAllTextColors(LIGHT_TEXT)
            
            ; Update all btn texts and titles
            SetAllPagesColor(LIGHT_BTN_TEXT, LIGHT_PAGE_TEXT, LIGHT_PAGE_BTN_TEXT)
        }
        
        ; Update small btn text
        SetSmallBtnText()
        
        ; Update section headers with appropriate colors
        UpdateSectionHeaders()
        
        ; Force a redraw of the GUI to apply colors immediately
        WinSet, Redraw,, A
    }
    
    ; Helper function to reset button colors to default
    ResetButtonColors() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT
        
        defaultColor := isDarkTheme ? DARK_TEXT : LIGHT_TEXT
        
        GuiControl, +c%defaultColor%, Btn_RerollSettings
        GuiControl, +c%defaultColor%, Btn_SystemSettings
        GuiControl, +c%defaultColor%, Btn_PackSettings
        GuiControl, +c%defaultColor%, Btn_SaveForTrade
        GuiControl, +c%defaultColor%, Btn_DiscordSettings
        GuiControl, +c%defaultColor%, Btn_DownloadSettings
    }
    
    ; Helper function to update all input field backgrounds
    SetInputBackgrounds(bgColor, textColor) {
        ; Create a list of all input controls
        inputList := "FriendID,Instances,instanceStartDelay,Columns,Mains,"
        inputList .= "Delay,waitTime,swipeSpeed,folderPath,instanceLaunchDelay,"
        inputList .= "minStars,minStarsShiny,discordUserId,discordWebhookURL,"
        inputList .= "heartBeatName,heartBeatWebhookURL,heartBeatDelay,"
        inputList .= "mainIdsURL,vipIdsURL,s4tWPMinCards,"
        inputList .= "s4tDiscordUserId,s4tDiscordWebhookURL,SelectedMonitorIndex,"
        inputList .= "defaultLanguage,ocrLanguage,clientLanguage,deleteMethod,tesseractPath,"
        inputList .= "rowGap,injectRange,injectMaxValue,injectMinValue" ; Removed variablePackCount
        
        ; Apply style to all inputs
        Loop, Parse, inputList, `,
        {
            if (A_LoopField)
                GuiControl, +Background%bgColor% +c%textColor%, %A_LoopField%
        }
    }
    
    ;; Special GUI Controls
    ; Add this function near other GUI helper functions
    AddSectionDivider(x, y, w, vName) {
        ; Create a subtle divider line with a variable name for showing/hiding
        Gui, Add, Text, x%x% y%y% w%w% h1 +0x10 v%vName% Hidden, ; Horizontal line divider
    }
    
    AddBtn(type, x, y, w, h, vName, gName, Text := "", imagePath := "", vTextName := "", textX := "", textY := "") {
        type := Trim(type)
        
        if (type = "Picture") {
            if (FileExist(imagePath))
                content := imagePath
            else
                content := ""
        } else {
            content := Text
        }
        
        setWidth := (w != "") ? True : False
        setHeight := (h != "") ? True : False
        gLabel := (gName != "") ? True : False
        
        GuiOptions := ""
        if (x != "")
            GuiOptions .= "x" . x . " "
        if (y != "")
            GuiOptions .= "y" . y . " "
        if (setWidth)
            GuiOptions .= "w" . w . " "
        if (setHeight)
            GuiOptions .= "h" . h . " "
        GuiOptions .= "v" . vName . " "
        if (gLabel)
            GuiOptions .= "g" . gName . " "
        GuiOptions .= "hwndMainHwnd Hidden BackgroundTrans"
        
        Gui, Add, %type%, %GuiOptions%, %content%
        
        textHwnd := ""
        
        if (vTextName != "") {
            TextOptions := ""
            if (textX != "")
                TextOptions .= "x" . textX . " "
            if (textY != "")
                TextOptions .= "y" . textY . " "
            TextOptions .= "v" . vTextName . " hwndTextHwnd Hidden BackgroundTrans"
            Gui, Add, Text, %TextOptions%, %Text%
        }
        
        return { hwnd: MainHwnd, textHwnd: textHwnd }
    }
    
    AddCheckBox(x, y, w, h, vName, gName, checkedImagePath, uncheckedImagePath, isChecked := False, vTextName := "", text := "", textX := "", textY := "") {
        ; decide which picture to show
        imagePath := isChecked ? checkedImagePath : uncheckedImagePath
        
        gName := (gName = "") ? "CheckBoxToggle" : gName
        
        ; Create a btn not only use Gui, add, checkBox
        Gui, Add, Picture
            , % "x" x " y" y " w" w " h" h " v" vName
            . " g" gName
            . " Hidden BackgroundTrans"
            , %imagePath%
        
        ; Create text for checkBox
        if (vTextName != "" && textX != "" && textY != "") {
            Gui, Add, Text, x%textX% y%textY% v%vTextName% Hidden BackgroundTrans, %text%
        }
    }
    
    ;; Hover Class
    ; Fix the flickering when the mouse is over the text controls
    class ToggleImageOnHover {
        static Pairs := []
        static TextToPicture := {}
        static LastHoverTime := {}
        static DEBOUNCE_DELAY := 20 ; milliseconds to prevent rapid switching
        
        RegisterTextControl(hText, hPicture) {
            this.TextToPicture[hText] := hPicture
        }
        
        CreateImagePair(hPic1, hPic2) {
            Pair := {1: hPic1, 2: hPic2, hover: false, debouncing: false}
            this.Pairs[hPic1] := Pair
            this.LastHoverTime[hPic1] := 0
            this.Api.PreparePair(Pair)
            
            if this.Pairs.Count() = 1 {
                this.Api.Pairs := this.Pairs
                this.Api.SetOnHover()
            }
        }
        
        RemovePair(hPic1) {
            this.Pairs.Delete(hPic1)
            this.LastHoverTime.Delete(hPic1)
            if !this.Pairs.Count()
                this.Api.RemoveOnHover()
        }
        
        CheckIfHover() {
            MouseGetPos,,,, hCtrl, 2
            this.Api.CheckIfHover(hCtrl)
        }
        
        ResetHoverState(hPicture) {
            if (this.Pairs.HasKey(hPicture)) {
                Pair := this.Pairs[hPicture]
                if (Pair.hover) {
                    Pair.hover := false
                    this.Api.Switch(Pair)
                    Timer := ObjBindMethod(this.Api, "OnMouseLeavePair", Pair)
                    SetTimer, % Timer, Delete
                }
            }
        }
        
        ResetAllHoverStates() {
            for k, Pair in this.Pairs {
                if (Pair.hover) {
                    Pair.hover := false
                    this.Api.Switch(Pair)
                    Timer := ObjBindMethod(this.Api, "OnMouseLeavePair", Pair)
                    SetTimer, % Timer, Delete
                }
            }
        }
        
        ForceRecheck() {
            RerecheckTimer := ObjBindMethod(this, "DelayedRecheck")
            SetTimer, % RerecheckTimer, -50
        }
        
        class Api {
            static WM_MOUSEMOVE := 0x200
            
            PreparePair(Pair) {
                static SS_NOTIFY := 0x100
                Loop 2 {
                    GuiControl, +%SS_NOTIFY%, % Pair[A_Index]
                }
                this.Switch(Pair)
            }
            
            SetOnHover() {
                this.OnHover := ObjBindMethod(this, "ON_WM_MOUSEMOVE")
                OnMessage(this.WM_MOUSEMOVE, this.OnHover)
            }
            
            RemoveOnHover() {
                OnMessage(this.WM_MOUSEMOVE, this.OnHover, 0)
            }
            
            ON_WM_MOUSEMOVE(wp, lp, msg, hwnd) {
                this.CheckIfHover(hwnd)
            }
            
            CheckIfHover(hwnd) {
                ; Map text control to picture control
                if (ToggleImageOnHover.TextToPicture.HasKey(hwnd)) {
                    hwnd := ToggleImageOnHover.TextToPicture[hwnd]
                }
                
                currentTime := A_TickCount
                
                for k, Pair in this.Pairs {
                    ; Check if mouse is over this pair
                    isOverPair := (hwnd = Pair[1] || hwnd = Pair[2])
                    
                    ; Also check if mouse is over associated text
                    isOverText := false
                    for textHandle, pictureHandle in ToggleImageOnHover.TextToPicture {
                        if (hwnd = textHandle && (pictureHandle = Pair[1] || pictureHandle = Pair[2])) {
                            isOverText := true
                            isOverPair := true
                            break
                        }
                    }
                    
                    if isOverPair {
                        ; Debounce rapid hover changes
                        if (currentTime - ToggleImageOnHover.LastHoverTime[k] < ToggleImageOnHover.DEBOUNCE_DELAY) {
                            continue
                        }
                        
                        if !Pair.hover && !Pair.debouncing {
                            Pair.hover := true
                            Pair.debouncing := true
                            ToggleImageOnHover.LastHoverTime[k] := currentTime
                            this.Switch(Pair, true)
                            
                            ; Clear debouncing after a short delay
                            DebounceTimer := ObjBindMethod(this, "ClearDebouncing", Pair)
                            SetTimer, % DebounceTimer, -20
                            
                            ; Set up leave detection
                            Timer := ObjBindMethod(this, "OnMouseLeavePair", Pair)
                            SetTimer, % Timer, 50 ; Reduced frequency for smoother detection
                            break
                        }
                    }
                }
            }
            
            ClearDebouncing(Pair) {
                Pair.debouncing := false
            }
            
            OnMouseLeavePair(Pair) {
                MouseGetPos,,,, hCtrl, 2
                
                ; Check if mouse is still over the picture pair
                isOnPicture := (hCtrl = Pair[1] || hCtrl = Pair[2])
                
                ; Check if mouse is over associated text
                isOnText := false
                for textHandle, pictureHandle in ToggleImageOnHover.TextToPicture {
                    if (hCtrl = textHandle && (pictureHandle = Pair[1] || pictureHandle = Pair[2])) {
                        isOnText := true
                        break
                    }
                }
                
                ; Also check mouse position to prevent edge cases
                MouseGetPos, mx, my
                isInBounds := this.IsMouseInControlBounds(Pair, mx, my)
                
                if !(isOnPicture || isOnText || isInBounds) {
                    Pair.hover := false
                    Pair.debouncing := false
                    SetTimer,, Delete
                    this.Switch(Pair)
                }
            }
            
            IsMouseInControlBounds(Pair, mx, my) {
                ; Get bounds of the first picture control
                ControlGetPos, x, y, w, h,, % "ahk_id " . Pair[1]
                
                ; Add small tolerance to prevent edge flickering
                tolerance := 2
                return (mx >= x - tolerance && mx <= x + w + tolerance && my >= y - tolerance && my <= y + h + tolerance)
            }
            
            Switch(Pair, mode := false) {
                ; Simple switch without redraw control to avoid errors
                for k, v in ["Show", "Hide"]
                    GuiControl, % v, % Pair[mode ? 3 - k : k]
            }
        }
    }
    
    DisableImageButton(PicName, HoverName) {
        GuiControl, Disable, %PicName%
        GuiControl, Hide, %PicName%
        GuiControl, Disable, %HoverName%
        GuiControl, Hide, %HoverName%
    }
    
    EnableImageButton(PicName, HoverName) {
        GuiControl, Enable, %PicName%
        GuiControl, Hide, %PicName%
        GuiControl, Enable, %HoverName%
        GuiControl, Hide, %HoverName%
    }
    
    DisableImageButtonToMultiple(pictureList, hoverList) {
        Loop, Parse, pictureList, `,
        {
            if (A_LoopField)
                GuiControl, Disable, %A_LoopField%
        }
        
        Loop, Parse, hoverList, `,
        {
            if (A_LoopField)
                GuiControl, Disable, %A_LoopField%
        }
    }
    
    EnableImageButtonToMultiple(pictureList, hoverList) {
        Loop, Parse, pictureList, `,
        {
            if (A_LoopField)
                GuiControl, Enable, %A_LoopField%
        }
        
        Loop, Parse, hoverList, `,
        {
            if (A_LoopField)
                GuiControl, Enable, %A_LoopField%
        }
    }
    
    DisableAllImageButton() {
        buttonList := "Btn_RerollSettings,Btn_SystemSettings,Btn_PackSettings,Btn_SaveForTrade,Btn_DiscordSettings,Btn_DownloadSettings,"
        buttonList .= "Btn_Arrange, Btn_Coffee, Btn_Join, Btn_Mumu, Btn_BalanceXMLs, Btn_Start, Btn_Update,"
        buttonList .= "Btn_previous, Btn_next"
        hoverList := "Hover_RerollSettings,Hover_SystemSettings,Hover_PackSettings,Hover_SaveForTrade,Hover_DiscordSettings,Hover_DownloadSettings,"
        hoverList .= "Hover_Arrange, Hover_Coffee, Hover_Join, Hover_Mumu, Hover_BalanceXMLs, Hover_Start, Hover_Update,"
        hoverList .= "Hover_previous, Hover_next"
        
        DisableImageButtonToMultiple(buttonList, hoverList)
    }
    
    ; Add this function to apply section-specific colors to section headers
    UpdateSectionHeaders() {
        global isDarkTheme, CurrentVisibleSection
        global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS
        
        if (CurrentVisibleSection = "")
            return
        
        ; Get the appropriate color for the current section
        sectionColor := isDarkTheme ? DARK_SECTION_COLORS[CurrentVisibleSection] : LIGHT_SECTION_COLORS[CurrentVisibleSection]
        
        ; Apply color to section headers based on current section
        if (CurrentVisibleSection = "InstanceSettings") {
            GuiControl, +c%sectionColor%, Txt_Instances
        }
        else if (CurrentVisibleSection = "TimeSettings") {
            GuiControl, +c%sectionColor%, Txt_Delay
        }
        else if (CurrentVisibleSection = "SaveForTrade") {
            GuiControl, +c%sectionColor%, Txt_s4tEnabled
        }
    }
    
    ; Function to toggle checkbox image and v Value
    ToggleCheckbox(varName) {
        global
        
        newValue := !%varName%
        %varName% := newValue
        
        GuiControl,, %varName%, % newValue ? "Gui_checked.png" : "Gui_unchecked.png"
        IniWrite, %newValue%, Settings.ini, UserSettings, %varName% ; Added to fix Gholdengo not displaying correctly
    }
    
    ; Function to toggle background image visibility
    ToggleBackgroundImage() {
        global useBackgroundImage, isDarkTheme
        
        ; Toggle the setting
        useBackgroundImage := !useBackgroundImage
        
        ; Save the setting
        IniWrite, %useBackgroundImage%, Settings.ini, UserSettings, useBackgroundImage
        
        ; Update the GUI
        if (useBackgroundImage) {
            ; Update button text
            GuiControl,, BackgroundToggle, currentDictionary.btn_bg_Off
            ; Show background image if it exists
            GuiControl, Show, BackgroundPic
        } else {
            ; Update button text
            GuiControl,, BackgroundToggle, currentDictionary.btn_bg_On
            ; Hide background image
            GuiControl, Hide, BackgroundPic
        }
        
        ; Update the solid background color to ensure it shows through
        bgColor := isDarkTheme ? DARK_BG : LIGHT_BG
        Gui, Color, %bgColor%
    }
    
    ; Ensure fade.ahk is not launched multiple times while allowing the current instance to continue running.global fadeStartflag := False
    global fadeStartflag := False
    fadeStart() {
        FileAppend,, %A_ScriptDir%\Scripts\Include\stop.signal
        Sleep, 30
        FileDelete, %A_ScriptDir%\Scripts\Include\stop.signal
        DetectHiddenWindows, On
        SetTitleMatchMode, 2
        
        if !WinExist("fade_in.ahk ahk_class AutoHotkey") {
            Run, %A_ScriptDir%\Scripts\Include\fade.ahk
        } else {
            return
        }
        
        Loop {
            if FileExist(fadeInFinish)
                break
        }
    }
    
    ;; Hide&Show
    ; Function to show multiple controls at once
    ShowControls(controlList) {
        Loop, Parse, controlList, `,
        {
            if (A_LoopField)
                GuiControl, Show, %A_LoopField%
        }
    }
    
    ; Function to hide multiple controls at once
    HideControls(controlList) {
        Loop, Parse, controlList, `,
        {
            if (A_LoopField)
                GuiControl, Hide, %A_LoopField%
        }
    }
    
    ; Trace hide and show
    global CurrentVisibleSection := ""
    
    ; ========== hide all section ==========
    HideAllSections() {
        ; OPTIMIZED: Using control lists and helper function
        
        ; Create control lists grouped by sections
        chooseSettingsPage := "Bg_set,title_set,Btn_RerollSettings,Btn_SystemSettings,Btn_PackSettings,Btn_SaveForTrade,Btn_DiscordSettings,Btn_DownloadSettings,Btn_main,"
        chooseSettingsPage .= "Txt_title_set,Txt_Btn_RerollSettings,Txt_Btn_SystemSettings,Txt_Btn_PackSettings,Txt_Btn_SaveForTrade,Txt_Btn_DiscordSettings,Txt_Btn_DownloadSettings,Txt_Btn_main,"
        chooseSettingsPage .= "Hover_RerollSettings,Hover_SystemSettings,Hover_PackSettings,Hover_SaveForTrade,Hover_DiscordSettings,Hover_DownloadSettings"
        mainPage := "Bg_main,title_main,Btn_Arrange,Btn_Coffee,Btn_Join,Btn_Mumu,Btn_BalanceXMLs,Btn_Start,Btn_Update,Btn_Setting,"
        mainPage .= "Txt_title_main,Txt_Btn_Arrange,Txt_Btn_Coffee,Txt_Btn_Join,Txt_Btn_Mumu,Txt_Btn_BalanceXMLs,Txt_Btn_Start,Txt_Btn_Update,Txt_Btn_Setting,"
        mainPage .= "Hover_Arrange,Hover_Coffee,Hover_Join,Hover_Mumu,Hover_BalanceXMLs,Hover_Start,Hover_Update"
        inSettingPage := "Bg_inset,Btn_previous,Btn_next,Btn_inset,Txt_Btn_inset,title_box,title_download,title_discord,title_trade,title_pack,title_system,title_reroll,"
        inSettingPage .= "Hover_previous,Hover_next"
        friendIDControls := "FriendID,FriendIDLabel,FriendIDSeparator"
        instanceControls := "Txt_Instances,Instances,Txt_InstanceStartDelay,instanceStartDelay,"
        instanceControls .= "Txt_Columns,Columns,Txt_runMain,runMain,Mains,Txt_AccountName,AccountName"
        timeControls := "Txt_Delay,Delay,Txt_WaitTime,waitTime,Txt_SwipeSpeed,swipeSpeed,"
        timeControls .= "slowMotion,Txt_slowMotion,TimeSettingsSeparator"
        systemControls := "Txt_Monitor,SelectedMonitorIndex,Txt_Scale,defaultLanguage,"
        systemControls .= "Txt_FolderPath,folderPath,Txt_OcrLanguage,ocrLanguage,Txt_ClientLanguage,clientLanguage,"
        systemControls .= "Txt_RowGap,rowGap,Txt_InstanceLaunchDelay,instanceLaunchDelay,autoLaunchMonitor,Txt_autoLaunchMonitor,SystemSettingsSeparator"
        extraControls := "ExtraSettingsHeading,tesseractOption,Txt_TesseractPath,tesseractPath,"
        extraControls .= "applyRoleFilters,debugMode,statusMessage,Txt_tesseractOption,Txt_applyRoleFilters,Txt_debugMode,Txt_statusMessage"
        packControls := "PackSettingsHeading,Txt_MinStars,minStars,"
        packControls .= "Txt_ShinyMinStars,minStarsShiny,Txt_DeleteMethod,deleteMethod,packMethod,Txt_packMethod,nukeAccount,Txt_nukeAccount,"
        packControls .= "SortByText,SortByDropdown,"
        packControls .= "Pack_Divider1,Buzzwole,Solgaleo,Lunala,Shining,Arceus,Palkia,Dialga,Pikachu,"
        packControls .= "Txt_Shining,Txt_Arceus,Txt_Palkia,Txt_Dialga,Txt_Pikachu,Txt_Charizard,Txt_Mewtwo,Txt_Mew,Txt_Solgaleo,Txt_Lunala,Txt_Buzzwole,"
        packControls .= "Charizard,Mewtwo,Mew,Pack_Divider2,ShinyCheck,"
        packControls .= "AllPackSelection,Txt_PackHeading,Page_Buzzwole,Page_Solgaleo,Page_Lunala,Page_Shining,"
        packControls .= "Txt_PageBuzzwole,Txt_PageSolgaleo,Txt_PageLunala,Txt_PageShining,Btn_returnPack,Txt_Btn_returnPack,"
        packControls .= "FullArtCheck,TrainerCheck,RainbowCheck,PseudoGodPack,InvalidCheck,"
        packControls .= "Txt_FullArtCheck,Txt_TrainerCheck,Txt_RainbowCheck,Txt_PseudoGodPack,Txt_CrownCheck,Txt_ShinyCheck,Txt_ImmersiveCheck,Txt_CheckShiningPackOnly,Txt_InvalidCheck,"
        packControls .= "CheckShiningPackOnly,CrownCheck,ImmersiveCheck,Pack_Divider3,"
        packControls .= "spendHourGlass,Txt_spendHourGlass"
        s4tControls := "s4tEnabled,s4tSilent,s4t3Dmnd,s4t4Dmnd,s4t1Star,"
        s4tControls .= "Txt_s4tEnabled,Txt_s4tSilent,Txt_s4t3Dmnd,Txt_s4t4Dmnd,Txt_s4t1Star,Txt_s4tWP,Txt_s4tSendAccountXml,"
        s4tControls .= "s4tGholdengo,s4tGholdengoEmblem,s4tGholdengoArrow,Txt_S4TSeparator,s4tWP,"
        s4tControls .= "s4tWPMinCardsLabel,s4tWPMinCards,S4TDiscordSettingsSubHeading,Txt_S4T_DiscordID,"
        s4tControls .= "s4tDiscordUserId,Txt_S4T_DiscordWebhook,s4tDiscordWebhookURL,s4tSendAccountXml,"
        s4tControls .= "SaveForTradeDivider_1,SaveForTradeDivider_2"
        discordControls := "DiscordSettingsHeading,Txt_DiscordID,discordUserId,Txt_DiscordWebhook,"
        discordControls .= "discordWebhookURL,sendAccountXml,Txt_sendAccountXml,HeartbeatSettingsSubHeading,heartBeat,Txt_heartBeat,"
        discordControls .= "hbName,heartBeatName,hbURL,heartBeatWebhookURL,hbDelay,heartBeatDelay,"
        discordControls .= "DiscordSettingsSeparator,Discord_Divider3"
        downloadControls := "Txt_MainIdsURL,mainIdsURL,Txt_VipIdsURL,vipIdsURL,"
        downloadControls .= "showcaseEnabled,Txt_showcaseEnabled,Txt_ShowcaseURL,showcaseURL"
        
        ; Hide all controls by section using helper function
        HideControls(chooseSettingsPage)
        HideControls(mainPage)
        HideControls(inSettingPage)
        HideControls(friendIDControls)
        HideControls(instanceControls)
        HideControls(timeControls)
        HideControls(systemControls)
        HideControls(extraControls)
        HideControls(packControls)
        HideControls(s4tControls)
        HideControls(discordControls)
        HideControls(downloadControls)
        
        ; Explicitly hide these checkboxes to ensure they don't appear in wrong sections
        GuiControl, Hide, spendHourGlass
        GuiControl, Hide, claimSpecialMissions
        GuiControl, Hide, Txt_spendHourGlass
        GuiControl, Hide, Txt_claimSpecialMissions
        
        ; Hide separators
        GuiControl, Hide, RerollSettingsSeparator
        
        ; Hide Sort By controls if they exist
        global sortByCreated
        if (sortByCreated) {
            GuiControl, Hide, SortByText
            GuiControl, Hide, SortByDropdown
        }
        
        ; Hide ALL divider elements
        dividerList := "FriendID_Divider,Instance_Divider3,System_Divider1,System_Divider2,System_Divider3,"
        dividerList .= "System_Divider4,Pack_Divider1,Pack_Divider2,Pack_Divider3,Discord_Divider3,"
        dividerList .= "SaveForTrade_Divider1,SaveForTrade_Divider2"
        HideControls(dividerList)
    }
    
    global fadeInFinish := A_ScriptDir "\Scripts\Include\finish.signal"
    ; ========== show choose settings page ==========
    ShowInitail() {
        global isDarkTheme, useBackgroundImage
        fadeStartflag := True
        fadeStart()
        Loop {
            if FileExist(finishSignalFile)
                break
            Sleep, 10
        }
        FileDelete, %finishSignalFile% ; delete signal
        
        BarControls := "Ot_license,Txt_license,Btn_ToolTip,Btn_Language,Btn_reload,BackgroundToggle,ThemeToggle"
        mainPageControl := "Bg_main,Btn_Arrange,Btn_Coffee,Btn_Join,Btn_Mumu,"
        mainPageControl .= "Btn_BalanceXMLs,Btn_Start,Btn_Update,Btn_Setting,"
        mainPageControl .= "Txt_title_main,Txt_Btn_Arrange,Txt_Btn_Coffee,Txt_Btn_Join,Txt_Btn_Mumu,"
        mainPageControl .= "Txt_Btn_BalanceXMLs,Txt_Btn_Start,Txt_Btn_Update,Txt_Btn_Setting"
        
        ShowControls(BarControls)
        ShowControls(mainPageControl)
        
        if (!isDarkTheme && useBackgroundImage)
            GuiControl, Show, title_main
        
        FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
        fadeStartflag := False
    }
    
    Showsettingpage() {
        global isDarkTheme, useBackgroundImage
        
        ; Ensure the fade-in is finished before calling HideAllSection()
        if(fadeStartflag = False){
            fadeStart()
            Loop {
                if FileExist(finishSignalFile)
                    break
                Sleep, 10
            }
            FileDelete, %finishSignalFile% ; delete signal
        }
        
        DisableAllImageButton()
        picList := "Btn_RerollSettings,Btn_SystemSettings,Btn_PackSettings,Btn_SaveForTrade,Btn_DiscordSettings,Btn_DownloadSettings"
        hoverList := "Hover_RerollSettings,Hover_SystemSettings,Hover_PackSettings,Hover_SaveForTrade,Hover_DiscordSettings,Hover_DownloadSettings"
        EnableImageButtonToMultiple(picList, hoverList)
        
        HideAllSections()
        
        SettingsPageControl := "Bg_set,Btn_RerollSettings,Btn_SystemSettings,Btn_PackSettings,"
        SettingsPageControl .= "Btn_SaveForTrade,Btn_DiscordSettings,Btn_DownloadSettings,Btn_main,"
        SettingsPageControl .= "Txt_title_set,Txt_Btn_RerollSettings,Txt_Btn_SystemSettings,Txt_Btn_PackSettings,"
        SettingsPageControl .= "Txt_Btn_SaveForTrade,Txt_Btn_DiscordSettings,Txt_Btn_DownloadSettings,Txt_Btn_main"
        
        ShowControls(SettingsPageControl)
        
        if(!isDarkTheme && useBackgroundImage) {
            GuiControl, Show, title_set
        }
        
        TextControl := "Txt_title_set,Txt_license"
        BtnControl := "Txt_Btn_RerollSettings,Txt_Btn_SystemSettings,Txt_Btn_PackSettings,"
        BtnControl .= "Txt_Btn_SaveForTrade,Txt_Btn_DiscordSettings,Txt_Btn_DownloadSettings"
        
        ApplyPageTextColorToMutiple(TextControl)
        ApplyBtnTextColorToMutiple(BtnControl)
        ApplyPageBtnTextColor("Txt_Btn_main")
        if(fadeStartflag = False)
            FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
    }
    
    ShowInsettingpage() {
        global isDarkTheme, useBackgroundImage
        
        inSettingsPageControl := "Bg_inset,Btn_previous,Btn_next,Btn_inset,Txt_Btn_inset"
        
        ShowControls(inSettingsPageControl)
        ApplyPageBtnTextColor("Txt_Btn_inset")
    }
    
    Showmainpage() {
        global isDarkTheme
        
        ; Ensure the fade-in is finished before calling HideAllSection()
        if(fadeStartflag = False){
            fadeStart()
            Loop {
                if FileExist(finishSignalFile)
                    break
                Sleep, 10
            }
            FileDelete, %finishSignalFile% ; delete signal
        }
        DisableAllImageButton()
        picList := "Btn_Arrange, Btn_Coffee, Btn_Join, Btn_Mumu, Btn_BalanceXMLs, Btn_Start, Btn_Update"
        hoverList := "Hover_Arrange, Hover_Coffee, Hover_Join, Hover_Mumu, Hover_BalanceXMLs, Hover_Start, Hover_Update"
        EnableImageButtonToMultiple(picList, hoverList)
        
        HideAllSections()
        
        mainPageControl := "Bg_main,Btn_Arrange,Btn_Coffee,Btn_Join,Btn_Mumu,"
        mainPageControl .= "Btn_BalanceXMLs,Btn_Start,Btn_Update,Btn_Setting,"
        mainPageControl .= "Txt_title_main,Txt_Btn_Arrange,Txt_Btn_Coffee,Txt_Btn_Join,Txt_Btn_Mumu,"
        mainPageControl .= "Txt_Btn_BalanceXMLs,Txt_Btn_Start,Txt_Btn_Update,Txt_Btn_Setting"
        
        ShowControls(mainPageControl)
        
        if(!isDarkTheme && useBackgroundImage) {
            GuiControl, Show, title_main
        }
        
        TextControl := "Txt_title_main,Txt_license"
        BtnControl := "Txt_Btn_Arrange,Txt_Btn_Coffee,Txt_Btn_Join,Txt_Btn_Mumu,"
        BtnControl .= "Txt_Btn_BalanceXMLs,Txt_Btn_Start,Txt_Btn_Update"
        
        ApplyPageTextColorToMutiple(TextControl)
        ApplyBtnTextColorToMutiple(BtnControl)
        ApplyPageBtnTextColor("Txt_Btn_Setting")
        
        if(fadeStartflag = False)
            FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
    }
    
    ; ========== show Reroll Settings section (Updated) ==========
    ShowRerollSettingsSection() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT
        global DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
        global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS
        ToggleImageOnHover.ResetAllHoverStates()
        ; Ensure the fade-in is finished before calling HideAllSection()
        if(fadeStartflag = False){
            fadeStart()
            Loop {
                if FileExist(finishSignalFile)
                    break
                Sleep, 10
            }
            FileDelete, %finishSignalFile% ; delete signal
        }
        
        DisableAllImageButton()
        ; First, make sure all other sections are hidden
        HideAllSections()
        ShowInsettingpage()
        
        ; Get the section color
        sectionColor := isDarkTheme ? DARK_SECTION_COLORS["RerollSettings"] : LIGHT_SECTION_COLORS["RerollSettings"]
        
        ; === Friend ID Section with Heading ===
        ; Define lists of controls to show
        friendIDControls := "title_reroll,FriendIDLabel,FriendID_Divider"
        instanceControls := "Txt_Instances,Instances,Txt_Columns,Columns,"
        instanceControls .= "Txt_InstanceStartDelay,instanceStartDelay,runMain,Txt_runMain,Txt_AccountName,AccountName,Instance_Divider3"
        timeControls := "Txt_Delay,Delay,Txt_WaitTime,waitTime,Txt_SwipeSpeed,swipeSpeed,slowMotion,Txt_slowMotion"
        
        ; Show controls using helper function
        ShowControls(friendIDControls)
        ShowControls(instanceControls)
        ShowControls(timeControls)
        
        ; Check if deleteMethod is "inject for reroll" and show FriendID
        GuiControlGet, deleteMethod
        if (deleteMethod = "Inject for Reroll" || deleteMethod = "13 Pack") {
            GuiControl, show, FriendID
        }
        
        if(!isDarkTheme && useBackgroundImage) {
            GuiControl, Show, title_box
        }
        
        ; Show Mains if runMain is checked
        IniRead, runMain, Settings.ini, UserSettings, runMain
        if (runMain) {
            GuiControl, Show, Mains
        }
        
        ; Apply styling based on theme
        textColor := isDarkTheme ? DARK_TEXT : LIGHT_TEXT
        inputBgColor := isDarkTheme ? DARK_INPUT_BG : LIGHT_INPUT_BG
        inputTextColor := isDarkTheme ? DARK_INPUT_TEXT : LIGHT_INPUT_TEXT
        
        ; Text controls
        textControls := "FriendIDLabel,Txt_Instances,Txt_InstanceStartDelay,Txt_Columns,Txt_runMain,"
        textControls .= "Txt_AccountName,Txt_Delay,Txt_WaitTime,Txt_SwipeSpeed,Txt_slowMotion"
        
        ; Input controls
        inputControls := "FriendID,Instances,instanceStartDelay,Columns,AccountName,Delay,waitTime,swipeSpeed"
        
        ; Apply text styling
        ApplyPageTextColor("title_reroll")
        
        Loop, Parse, textControls, `,
        {
            if (A_LoopField)
                GuiControl, +c%textColor%, %A_LoopField%
        }
        
        ; Apply input styling
        Loop, Parse, inputControls, `,
        {
            if (A_LoopField)
                GuiControl, +Background%inputBgColor% +c%inputTextColor%, %A_LoopField%
        }
        
        ; Apply styling to Mains if shown
        if (runMain)
            GuiControl, +Background%inputBgColor% +c%inputTextColor%, Mains
        
        ; Update section headers with appropriate colors
        UpdateSectionHeaders()
        
        if(fadeStartflag = False || )
            FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
        
        picList := "Btn_previous,Btn_next"
        hovList := "Hover_previous,Hover_next"
        EnableImageButtonToMultiple(picList, hovList)
        
        CurrentVisibleSection := "RerollSettings"
    }
    
    ; ========== show System Settings Section (updated with dividers) ==========
    ShowSystemSettingsSection() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
        global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS
        ToggleImageOnHover.ResetAllHoverStates()
        ; Ensure the fade-in is finished before calling HideAllSection()
        if(fadeStartflag = False){
            fadeStart()
            Loop {
                if FileExist(finishSignalFile)
                    break
                Sleep, 10
            }
            FileDelete, %finishSignalFile% ; delete signal
        }
        
        DisableAllImageButton()
        ; First, make sure all other sections are hidden
        HideAllSections()
        ShowInsettingpage()
        
        ; Get the section color
        sectionColor := isDarkTheme ? DARK_SECTION_COLORS["SystemSettings"] : LIGHT_SECTION_COLORS["SystemSettings"]
        
        ; Define control lists
        monitorControls := "title_system,Txt_Monitor,SelectedMonitorIndex,Txt_Scale,defaultLanguage"
        pathControls := "Txt_FolderPath,folderPath,Txt_OcrLanguage,ocrLanguage,Txt_ClientLanguage,clientLanguage"
        instanceControls .= "Txt_RowGap,rowGap,Txt_InstanceLaunchDelay,instanceLaunchDelay,autoLaunchMonitor,Txt_autoLaunchMonitor,SystemSettingsSeparator"
        extraControls := "ExtraSettingsHeading,tesseractOption,Txt_tesseractOption,applyRoleFilters,Txt_applyRoleFilters,debugMode,Txt_debugMode,statusMessage,Txt_statusMessage"
        
        ; Show controls by group
        ShowControls(monitorControls)
        ShowControls(pathControls)
        ShowControls(instanceControls)
        ShowControls(extraControls)
        
        if(!isDarkTheme && useBackgroundImage) {
            GuiControl, Show, title_box
        }
        
        ; Check if tesseractOption is checked
        IniRead, tesseractOption, Settings.ini, UserSettings, tesseractOption, 0
        if (tesseractOption) {
            GuiControl, Show, Txt_TesseractPath
            GuiControl, Show, tesseractPath
            ApplyTextColor("Txt_TesseractPath")
            ApplyInputStyle("tesseractPath")
        }
        
        ; Apply text styling to all text controls
        textControls := "Txt_Monitor,Txt_Scale,Txt_FolderPath,Txt_OcrLanguage,Txt_ClientLanguage,"
        textControls .= "Txt_RowGap,Txt_InstanceLaunchDelay,Txt_autoLaunchMonitor,"
        textControls .= "ExtraSettingsHeading,Txt_tesseractOption,Txt_applyRoleFilters,Txt_debugMode,Txt_statusMessage"
        ApplyTextColorToMultiple(textControls)
        
        ApplyPageTextColor("title_system")
        
        ; Apply input styling to all input fields
        inputControls := "SelectedMonitorIndex,defaultLanguage,folderPath,ocrLanguage,clientLanguage,"
        inputControls .= "rowGap,instanceLaunchDelay"
        ApplyInputStyleToMultiple(inputControls)
        
        ; Update section headers with appropriate colors
        UpdateSectionHeaders()
        
        if(fadeStartflag = False)
            FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
        
        picList := "Btn_previous,Btn_next"
        hovList := "Hover_previous,Hover_next"
        EnableImageButtonToMultiple(picList, hovList)
        
        CurrentVisibleSection := "systemSettings"
    }
    
    ; ========== Show Pack Settings Section (IMPROVED LAYOUT with dividers) ==========
    ShowPackSettingsSection() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
        global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS, deleteMethod, nukeAccount
        global Shining, Arceus, Palkia, Dialga, Pikachu, Charizard, Mewtwo, Mew, Solgaleo, Lunala, Buzzwole
        global sortByCreated
        ToggleImageOnHover.ResetAllHoverStates()
        ; Ensure the fade-in is finished before calling HideAllSection()
        if(fadeStartflag = False){
            fadeStart()
            Loop {
                if FileExist(finishSignalFile)
                    break
                Sleep, 10
            }
            FileDelete, %finishSignalFile% ; delete signal
        }
        
        SetNormalFont()
        
        DisableAllImageButton()
        ; First, make sure all other sections are hidden
        HideAllSections()
        ShowInsettingpage()
        
        ; Get the section color
        sectionColor := isDarkTheme ? DARK_SECTION_COLORS["PackSettings"] : LIGHT_SECTION_COLORS["PackSettings"]
        
        ; === God Pack Settings Subsection ===
        ; Define control lists for each subsection
        godPackControls := "title_pack,Txt_MinStars,minStars,Txt_ShinyMinStars,minStarsShiny,"
        godPackControls .= "packMethod,Txt_packMethod,Txt_DeleteMethod,deleteMethod,Pack_Divider1"
        
        packSelectionControls := "Buzzwole,Solgaleo,Lunala,Shining,"
        packSelectionControls .= "Txt_Buzzwole,Txt_Solgaleo,Txt_Lunala,Txt_Shining,"
        packSelectionControls .= "AllPackSelection,Pack_Divider2"
        
        cardDetectionControls := "FullArtCheck,TrainerCheck,RainbowCheck,"
        cardDetectionControls .= "PseudoGodPack,CrownCheck,ShinyCheck,ImmersiveCheck,"
        cardDetectionControls .= "Txt_FullArtCheck,Txt_TrainerCheck,Txt_RainbowCheck,Txt_PseudoGodPack,"
        cardDetectionControls .= "Txt_CrownCheck,Txt_ShinyCheck,Txt_ImmersiveCheck,Txt_CheckShiningPackOnly,Txt_InvalidCheck,"
        cardDetectionControls .= "InvalidCheck,CheckShiningPackOnly,Pack_Divider3"
        
        ; Show controls by subsection
        ShowControls(godPackControls)
        ShowControls(packSelectionControls)
        ShowControls(cardDetectionControls)
        
        if(!isDarkTheme && useBackgroundImage) {
            GuiControl, Show, title_box
        }
        
        ; Check if deleteMethod is "inject" and show nukeAccount if not
        GuiControlGet, deleteMethod
        
        if (InStr(deleteMethod, "Inject")) {
            ; First make sure to hide nukeAccount which isn't applicable for Inject methods
            GuiControl, Hide, nukeAccount
            GuiControl, Hide, Txt_nukeAccount
            GuiControl,, nukeAccount, 0 ; Uncheck the checkbox when hidden
            
            ; Always show spendHourGlass
            GuiControl, Show, spendHourGlass
            GuiControl, Show, Txt_spendHourGlass
            ApplyTextColor("Txt_spendHourGlass")
            
            GuiControl, Show, SortByText
            GuiControl, Show, SortByDropdown
            ApplyTextColor("SortByText")
        } else {
            ; Always show spendHourGlass
            GuiControl, Hide, spendHourGlass
            GuiControl, Hide, Txt_spendHourGlass
            GuiControl,, spendHourGlass, 0
            
            ; Non-Inject method selected
            GuiControl, Show, nukeAccount
            GuiControl, Show, Txt_nukeAccount
            MethodControls := "SortByText,SortByDropdown"
            HideControls(MethodControls)
            ; Apply styling
            ApplyTextColor("Txt_nukeAccount")
        }
        
        ; Apply theme-based styling
        textColor := isDarkTheme ? DARK_TEXT : LIGHT_TEXT
        inputBgColor := isDarkTheme ? DARK_INPUT_BG : LIGHT_INPUT_BG
        inputTextColor := isDarkTheme ? DARK_INPUT_TEXT : LIGHT_INPUT_TEXT
        
        ; God Pack Settings text controls
        godPackTextControls := "Txt_MinStars,Txt_ShinyMinStars,Txt_DeleteMethod,Txt_packMethod,Txt_spendHourGlass"
        if (!InStr(deleteMethod, "Inject")) {
            godPackTextControls .= ",Txt_nukeAccount"
        }
        
        ; Pack Selection text controls
        packSelectionTextControls := "Txt_Buzzwole,Txt_Solgaleo,Txt_Lunala,Txt_Shining"
        
        ; Card Detection text controls
        cardDetectionTextControls := "Txt_FullArtCheck,Txt_TrainerCheck,Txt_RainbowCheck,Txt_PseudoGodPack,"
        cardDetectionTextControls .= "Txt_CrownCheck,Txt_ShinyCheck,Txt_ImmersiveCheck,Txt_CheckShiningPackOnly,Txt_InvalidCheck,"
        
        ; Input controls
        inputControls := "minStars,minStarsShiny"
        
        ; Apply text styling to all controls
        ApplyTextColorToMultiple(godPackTextControls)
        ApplyTextColorToMultiple(packSelectionTextControls)
        ApplyTextColorToMultiple(cardDetectionTextControls)
        ApplyPageTextColor("title_pack")
        
        ; Apply input styling
        ApplyInputStyleToMultiple(inputControls)
        
        ; Update section headers with appropriate colors
        UpdateSectionHeaders()
        
        if(fadeStartflag = False)
            FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
        
        picList := "Btn_previous,Btn_next"
        hovList := "Hover_previous,Hover_next"
        EnableImageButtonToMultiple(picList, hovList)
        
        CurrentVisibleSection := "PackSettings"
    }
    
    ; ========== Show Save For Trade Section (Updated with dividers) ==========
    ShowSaveForTradeSection() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_TEXT_SECONDARY, LIGHT_TEXT_SECONDARY
        global DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
        global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS
        ToggleImageOnHover.ResetAllHoverStates()
        ; Ensure the fade-in is finished before calling HideAllSection()
        if(fadeStartflag = False){
            fadeStart()
            Loop {
                if FileExist(finishSignalFile)
                    break
                Sleep, 10
            }
            FileDelete, %finishSignalFile% ; delete signal
        }
        
        DisableAllImageButton()
        ; First, make sure all other sections are hidden
        HideAllSections()
        ShowInsettingpage()
        
        ; Get the section color
        sectionColor := isDarkTheme ? DARK_SECTION_COLORS["SaveForTrade"] : LIGHT_SECTION_COLORS["SaveForTrade"]
        
        ; Show s4tEnabled toggle
        GuiControl, Show, title_trade
        GuiControl, Show, s4tEnabled
        GuiControl, Show, Txt_s4tEnabled
        GuiControl, +c%sectionColor%, Txt_s4tEnabled
        
        if(!isDarkTheme && useBackgroundImage) {
            GuiControl, Show, title_box
        }
        
        ApplyPageTextColor("title_trade")
        
        ; Check if s4tEnabled is checked to show related controls
        IniRead, s4tEnabled, Settings.ini, UserSettings, s4tEnabled, 0
        if (s4tEnabled) {
            ; Show dividers
            GuiControl, Show, SaveForTradeDivider_1
            GuiControl, Show, SaveForTradeDivider_2
            ; Define control lists for enabled state
            mainS4TControls := "s4tSilent,s4t3Dmnd,s4t4Dmnd,s4t1Star,Txt_S4TSeparator,s4tWP,"
            mainS4TControls .= "Txt_s4tSilent,Txt_s4t3Dmnd,Txt_s4t4Dmnd,Txt_s4t1Star,Txt_s4tWP"
            ShowControls(mainS4TControls)
            
            ; Discord subsection controls
            s4tDiscordControls := "S4TDiscordSettingsSubHeading,Txt_S4T_DiscordID,s4tDiscordUserId,"
            s4tDiscordControls .= "Txt_S4T_DiscordWebhook,s4tDiscordWebhookURL,s4tSendAccountXml,Txt_s4tSendAccountXml"
            ShowControls(s4tDiscordControls)
            
            ; Apply section color to sub-heading
            GuiControl, +c%sectionColor%, S4TDiscordSettingsSubHeading
            
            ; Apply text styling
            textColor := isDarkTheme ? DARK_TEXT : LIGHT_TEXT
            secondaryTextColor := isDarkTheme ? DARK_TEXT_SECONDARY : LIGHT_TEXT_SECONDARY
            
            ; Set text colors
            mainTextControls := "s4tSilent,s4t3Dmnd,s4t4Dmnd,s4t1Star,s4tWP,"
            mainTextControls .= "Txt_S4T_DiscordID,Txt_S4T_DiscordWebhook,s4tSendAccountXml"
            ApplyTextColorToMultiple(mainTextControls)
            
            ; Set secondary text color
            GuiControl, +c%secondaryTextColor%, Txt_S4TSeparator
            
            ; Apply input styling to fields
            inputControls := "s4tDiscordUserId,s4tDiscordWebhookURL"
            ApplyInputStyleToMultiple(inputControls)
            
            ; Check if Shining is enabled to show Gholdengo
            IniRead, Shining, Settings.ini, UserSettings, Shining, 0
            if (Shining) {
                GuiControl, Show, s4tGholdengo
                GuiControl, Show, s4tGholdengoEmblem
                GuiControl, Show, s4tGholdengoArrow
                
                gholdengoControls := "s4tGholdengoArrow"
                ApplyTextColorToMultiple(gholdengoControls)
            }
            
            ; Check if s4tWP is checked to show min cards
            IniRead, s4tWP, Settings.ini, UserSettings, s4tWP, 0
            if (s4tWP) {
                GuiControl, Show, s4tWPMinCardsLabel
                GuiControl, Show, s4tWPMinCards
                
                ApplyTextColor("s4tWPMinCardsLabel")
                ApplyInputStyle("s4tWPMinCards")
            }
        }
        
        ; Update section headers with appropriate colors
        UpdateSectionHeaders()
        
        if(fadeStartflag = False)
            FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
        
        picList := "Btn_previous,Btn_next"
        hovList := "Hover_previous,Hover_next"
        EnableImageButtonToMultiple(picList, hovList)
        
        CurrentVisibleSection := "SaveForTrade"
    }
    
    ; ========== Show Discord Settings Section (Updated with dividers) ==========
    ShowDiscordSettingsSection() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT
        global DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
        global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS
        ToggleImageOnHover.ResetAllHoverStates()
        ; Ensure the fade-in is finished before calling HideAllSection()
        if(fadeStartflag = False){
            fadeStart()
            Loop {
                if FileExist(finishSignalFile)
                    break
                Sleep, 10
            }
            FileDelete, %finishSignalFile% ; delete signal
        }
        
        DisableAllImageButton()
        ; First, make sure all other sections are hidden
        HideAllSections()
        ShowInsettingpage()
        
        ; Get the section color
        sectionColor := isDarkTheme ? DARK_SECTION_COLORS["DiscordSettings"] : LIGHT_SECTION_COLORS["DiscordSettings"]
        
        ; Define control lists
        mainDiscordControls := "title_discord,DiscordSettingsHeading,Txt_DiscordID,discordUserId,"
        mainDiscordControls .= "Txt_DiscordWebhook,discordWebhookURL,sendAccountXml,Txt_sendAccountXml"
        
        heartbeatHeadingControls := "HeartbeatSettingsSubHeading,Discord_Divider3,heartBeat,Txt_heartBeat"
        
        ; Show main Discord controls
        ShowControls(mainDiscordControls)
        ShowControls(heartbeatHeadingControls)
        
        if(!isDarkTheme && useBackgroundImage) {
            GuiControl, Show, title_box
        }
        
        ; Apply section color to headings
        GuiControl, +c%sectionColor%, DiscordSettingsHeading
        GuiControl, +c%sectionColor%, HeartbeatSettingsSubHeading
        
        ; Apply text styling
        textColor := isDarkTheme ? DARK_TEXT : LIGHT_TEXT
        mainTextControls := "Txt_DiscordID,Txt_DiscordWebhook,Txt_sendAccountXml,Txt_heartBeat"
        ApplyTextColorToMultiple(mainTextControls)
        
        ; Apply input styling
        inputControls := "discordUserId,discordWebhookURL"
        ApplyInputStyleToMultiple(inputControls)
        
        ApplyPageTextColor("title_discord")
        
        ; Check if heartBeat is enabled to show related controls
        IniRead, heartBeat, Settings.ini, UserSettings, heartBeat, 0
        if (heartBeat) {
            heartbeatControls := "hbName,heartBeatName,hbURL,heartBeatWebhookURL,hbDelay,heartBeatDelay"
            ShowControls(heartbeatControls)
            
            ; Apply text styling to heartbeat controls
            heartbeatTextControls := "hbName,hbURL,hbDelay"
            ApplyTextColorToMultiple(heartbeatTextControls)
            
            ; Apply input styling to heartbeat fields
            heartbeatInputControls := "heartBeatName,heartBeatWebhookURL,heartBeatDelay"
            ApplyInputStyleToMultiple(heartbeatInputControls)
        }
        
        ; Show the bottom separator
        GuiControl, Show, DiscordSettingsSeparator
        
        ; Update section headers with appropriate colors
        UpdateSectionHeaders()
        
        if(fadeStartflag = False)
            FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
        
        picList := "Btn_previous,Btn_next"
        hovList := "Hover_previous,Hover_next"
        EnableImageButtonToMultiple(picList, hovList)
        
        CurrentVisibleSection := "DiscordSettings"
    }
    
    ; ========== Download Settings Section (updated with divider and showcase options) ==========
    ShowDownloadSettingsSection() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT
        global DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
        global DARK_SECTION_COLORS, LIGHT_SECTION_COLORS
        global showcaseEnabled, showcaseURL
        ToggleImageOnHover.ResetAllHoverStates()
        ; Ensure the fade-in is finished before calling HideAllSection()
        if(fadeStartflag = False){
            fadeStart()
            Loop {
                if FileExist(finishSignalFile)
                    break
                Sleep, 10
            }
            FileDelete, %finishSignalFile% ; delete signal
        }
        
        DisableAllImageButton()
        ; First, make sure all other sections are hidden
        HideAllSections()
        ShowInsettingpage()
        
        ; Define control lists
        mainControls := "title_download,Txt_MainIdsURL,mainIdsURL,Txt_VipIdsURL,vipIdsURL,showcaseEnabled,Txt_showcaseEnabled"
        ShowControls(mainControls)
        
        if(!isDarkTheme && useBackgroundImage) {
            GuiControl, Show, title_box
        }
        
        ; Apply text styling
        textColor := isDarkTheme ? DARK_TEXT : LIGHT_TEXT
        mainTextControls := "Txt_MainIdsURL,Txt_VipIdsURL,Txt_showcaseEnabled"
        ApplyTextColorToMultiple(mainTextControls)
        
        ; Apply input styling
        inputControls := "mainIdsURL,vipIdsURL"
        ApplyInputStyleToMultiple(inputControls)
        ApplyPageTextColor("title_download")
        
        /*
        ; Check if showcaseEnabled is checked to show related controls
        IniRead, showcaseEnabled, Settings.ini, UserSettings, showcaseEnabled
        if (showcaseEnabled) {
            ShowControls("Txt_ShowcaseURL,showcaseURL")
            ApplyTextColor("Txt_ShowcaseURL")
            ApplyInputStyle("showcaseURL")
        }
        */
        
        ; Update section headers with appropriate colors
        UpdateSectionHeaders()
        
        if(fadeStartflag = False)
            FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
        
        picList := "Btn_previous,Btn_next"
        hovList := "Hover_previous,Hover_next"
        EnableImageButtonToMultiple(picList, hovList)
        
        CurrentVisibleSection := "DownloadSettings"
    }
    
    ShowPackSelectPage() {
        global isDarkTheme, DARK_TEXT, LIGHT_TEXT, useBackgroundImage
        
        ; Ensure the fade-in is finished before calling HideAllSection()
        if(fadeStartflag = False){
            fadeStart()
            Loop {
                if FileExist(finishSignalFile)
                    break
                Sleep, 10
            }
            FileDelete, %finishSignalFile% ; delete signal
        }
        
        HideAllSections()
        ShowInsettingpage()
        
        controlList := "title_Pack,Page_Buzzwole,Page_Solgaleo,Page_Lunala,Page_Shining,Arceus,"
        controlList .= "Palkia,Dialga,Pikachu,Charizard,Mewtwo,Mew,Btn_returnPack"
        Txt_controlList := "Txt_PackHeading,Txt_PageBuzzwole,Txt_PageSolgaleo,Txt_PageLunala,Txt_PageShining,Txt_Arceus,"
        Txt_controlList .= "Txt_Palkia,Txt_Dialga,Txt_Pikachu,Txt_Charizard,Txt_Mewtwo,Txt_Mew"
        HideControls := "Btn_next,Btn_previous,Btn_inset,Txt_Btn_inset"
        
        ShowControls(controlList)
        ShowControls(Txt_controlList)
        HideControls(HideControls)
        GuiControl, Show, Txt_Btn_returnPack
        
        if(!isDarkTheme && useBackgroundImage) {
            GuiControl, Show, title_box
        }
        
        ApplyTextColorToMultiple(Txt_controlList)
        ApplyPageBtnTextColor("Txt_Btn_returnPack")
        ApplyPageTextColor("title_pack")
        
        if(fadeStartflag = False)
            FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
        
        CurrentVisibleSection := "PackSelection"
    }
    
    ;; Shortcuts Functions
    HandleKeyboardShortcut(sectionIndex) {
        ; Create array for sections (updated to new structure)
        sections := []
        sections.Push("RerollSettings")
        sections.Push("SystemSettings")
        sections.Push("PackSettings")
        sections.Push("SaveForTrade")
        sections.Push("DiscordSettings")
        sections.Push("DownloadSettings")
        
        ; Check if the index is valid
        if (sectionIndex > 0 && sectionIndex <= sections.MaxIndex()) {
            ; Get the section name
            sectionName := sections[sectionIndex]
            
            ; Hide all sections
            HideAllSections()
            
            ; Show the selected section based on its name
            if (sectionName = "RerollSettings")
                ShowRerollSettingsSection()
            else if (sectionName = "SystemSettings")
                ShowSystemSettingsSection()
            else if (sectionName = "PackSettings")
                ShowPackSettingsSection()
            else if (sectionName = "SaveForTrade")
                ShowSaveForTradeSection()
            else if (sectionName = "DiscordSettings")
                ShowDiscordSettingsSection()
            else if (sectionName = "DownloadSettings")
                ShowDownloadSettingsSection()
            
            ; Update current section and tab highlighting
            CurrentVisibleSection := sectionName
            
            ; Set section title
            friendlyName := GetFriendlyName(sectionName)
            
            ; Update section color
            sectionColor := isDarkTheme ? DARK_SECTION_COLORS[sectionName] : LIGHT_SECTION_COLORS[sectionName]
            
            ; Save current settings after changing sections
            SaveAllSettings()
        }
    }
    
    HandleFunctionKeyShortcut(functionIndex) {
        if (functionIndex = 1)
            gosub, LaunchAllMumu ; F1: Launch all Mumu
        else if (functionIndex = 2)
            gosub, ArrangeWindows ; F2: Arrange Windows
        else if (functionIndex = 3)
            gosub, StartBot ; F3: Start Bot
    }
    
    ; Function to show help menu with keyboard shortcuts
    ShowHelpMenu() {
        global isDarkTheme, useBackgroundImage
        
        helpText := HelpDictionary.Help_Shortcuts . "`n`n"
        helpText .= "Ctrl+1: " . currentDictionary.btn_reroll . "`n"
        helpText .= "Ctrl+2: " . currentDictionary.btn_system . "`n"
        helpText .= "Ctrl+3: " . currentDictionary.btn_pack . "`n"
        helpText .= "Ctrl+4: " . currentDictionary.btn_save . "`n"
        helpText .= "Ctrl+5: " . currentDictionary.btn_discord . "`n"
        helpText .= "Ctrl+6: " . currentDictionary.btn_download . "`n"
        helpText .= "`n" . HelpDictionary.Help_FunctionKeys . "`n"
        helpText .= "F1: " . currentDictionary.btn_mumu . "`n"
        helpText .= "F2: " . currentDictionary.btn_arrange . "`n"
        helpText .= "F3: " . currentDictionary.btn_start . "`n"
        helpText .= "F4: " . HelpDictionary.Help_F4 . "`n"
        helpText .= "Shift+F7: " . HelpDictionary.Help_ShiftF7 . "`n`n"
        helpText .= HelpDictionary.Help_Interface . "`n"
        helpText .= HelpDictionary.Help_CurrentTheme . (isDarkTheme ? currentDictionary.btn_theme_Dark : currentDictionary.btn_theme_Light) . "`n"
        helpText .= HelpDictionary.Help_BackgroundImage . (useBackgroundImage ? HelpDictionary.Help_Enabled : HelpDictionary.Help_Disabled) . "`n"
        helpText .= HelpDictionary.Help_ToggleTheme
        helpText .= HelpDictionary.Help_ToggleBG
        
        MsgBox, 64, Keyboard Shortcuts Help, %helpText%
    }
    
    ; Helper function to convert section names to friendly names
    GetFriendlyName(sectionName) {
        if (sectionName = "RerollSettings")
            return "Reroll Settings"
        else if (sectionName = "SystemSettings")
            return "System Settings"
        else if (sectionName = "PackSettings") ; Updated
            return "Pack Settings"
        else if (sectionName = "SaveForTrade")
            return "Save For Trade"
        else if (sectionName = "DiscordSettings")
            return "Discord Settings"
        else if (sectionName = "DownloadSettings")
            return "Download Settings"
        else
            return sectionName
    }
    
    ; Function to load settings from INI file
    LoadSettingsFromIni() {
        global
        
        ; Check if Settings.ini exists
        if (FileExist("Settings.ini")) {
            ; Read basic settings with default values if they don't exist in the file
            IniRead, FriendID, Settings.ini, UserSettings, FriendID, ""
            IniRead, waitTime, Settings.ini, UserSettings, waitTime, 5
            IniRead, Delay, Settings.ini, UserSettings, Delay, 250
            IniRead, folderPath, Settings.ini, UserSettings, folderPath, C:\Program Files\Netease
            IniRead, Columns, Settings.ini, UserSettings, Columns, 5
            IniRead, godPack, Settings.ini, UserSettings, godPack, Continue
            IniRead, Instances, Settings.ini, UserSettings, Instances, 1
            IniRead, instanceStartDelay, Settings.ini, UserSettings, instanceStartDelay, 0
            IniRead, defaultLanguage, Settings.ini, UserSettings, defaultLanguage, Scale125
            IniRead, rowGap, Settings.ini, UserSettings, rowGap, 100
            IniRead, SelectedMonitorIndex, Settings.ini, UserSettings, SelectedMonitorIndex, 1
            IniRead, swipeSpeed, Settings.ini, UserSettings, swipeSpeed, 300
            IniRead, deleteMethod, Settings.ini, UserSettings, deleteMethod, 3 Pack
            IniRead, runMain, Settings.ini, UserSettings, runMain, 1
            IniRead, Mains, Settings.ini, UserSettings, Mains, 1
            IniRead, AccountName, Settings.ini, UserSettings, AccountName, ""
            IniRead, heartBeat, Settings.ini, UserSettings, heartBeat, 0
            IniRead, heartBeatWebhookURL, Settings.ini, UserSettings, heartBeatWebhookURL, ""
            IniRead, heartBeatName, Settings.ini, UserSettings, heartBeatName, ""
            IniRead, nukeAccount, Settings.ini, UserSettings, nukeAccount, 0
            IniRead, packMethod, Settings.ini, UserSettings, packMethod, 0
            IniRead, CheckShinyPackOnly, Settings.ini, UserSettings, CheckShinyPackOnly, 0
            IniRead, TrainerCheck, Settings.ini, UserSettings, TrainerCheck, 0
            IniRead, FullArtCheck, Settings.ini, UserSettings, FullArtCheck, 0
            IniRead, RainbowCheck, Settings.ini, UserSettings, RainbowCheck, 0
            IniRead, ShinyCheck, Settings.ini, UserSettings, ShinyCheck, 0
            IniRead, CrownCheck, Settings.ini, UserSettings, CrownCheck, 0
            IniRead, ImmersiveCheck, Settings.ini, UserSettings, ImmersiveCheck, 0
            IniRead, InvalidCheck, Settings.ini, UserSettings, InvalidCheck, 0
            IniRead, PseudoGodPack, Settings.ini, UserSettings, PseudoGodPack, 0
            IniRead, minStars, Settings.ini, UserSettings, minStars, 0
            IniRead, Palkia, Settings.ini, UserSettings, Palkia, 0
            IniRead, Dialga, Settings.ini, UserSettings, Dialga, 0
            IniRead, Arceus, Settings.ini, UserSettings, Arceus, 0
            IniRead, Shining, Settings.ini, UserSettings, Shining, 0
            IniRead, Mew, Settings.ini, UserSettings, Mew, 0
            IniRead, Pikachu, Settings.ini, UserSettings, Pikachu, 0
            IniRead, Charizard, Settings.ini, UserSettings, Charizard, 0
            IniRead, Mewtwo, Settings.ini, UserSettings, Mewtwo, 0
            IniRead, Solgaleo, Settings.ini, UserSettings, Solgaleo, 1
            IniRead, Lunala, Settings.ini, UserSettings, Lunala, 0
            IniRead, Buzzwole, Settings,ini, UserSettings, Buzzwole, 0
            IniRead, slowMotion, Settings.ini, UserSettings, slowMotion, 0
            IniRead, ocrLanguage, Settings.ini, UserSettings, ocrLanguage, en
            IniRead, clientLanguage, Settings.ini, UserSettings, clientLanguage, en
            IniRead, autoLaunchMonitor, Settings.ini, UserSettings, autoLaunchMonitor, 1
            IniRead, mainIdsURL, Settings.ini, UserSettings, mainIdsURL, ""
            IniRead, vipIdsURL, Settings.ini, UserSettings, vipIdsURL, ""
            IniRead, instanceLaunchDelay, Settings.ini, UserSettings, instanceLaunchDelay, 5
            IniRead, variablePackCount, Settings.ini, UserSettings, variablePackCount, 15
            IniRead, claimSpecialMissions, Settings.ini, UserSettings, claimSpecialMissions, 0
            IniRead, spendHourGlass, Settings.ini, UserSettings, spendHourGlass, 0
            IniRead, injectSortMethod, Settings.ini, UserSettings, injectSortMethod, ModifiedAsc
            IniRead, injectMaxValue, Settings.ini, UserSettings, injectMaxValue, 39 ; Default to 39
            IniRead, injectMinValue, Settings.ini, UserSettings, injectMinValue, 35 ; Default to 35
            IniRead, waitForEligibleAccounts, Settings.ini, UserSettings, waitForEligibleAccounts, 1
            IniRead, maxWaitHours, Settings.ini, UserSettings, maxWaitHours, 24
            
            ; Read S4T settings
            IniRead, s4tEnabled, Settings.ini, UserSettings, s4tEnabled, 0
            IniRead, s4tSilent, Settings.ini, UserSettings, s4tSilent, 1
            IniRead, s4t3Dmnd, Settings.ini, UserSettings, s4t3Dmnd, 0
            IniRead, s4t4Dmnd, Settings.ini, UserSettings, s4t4Dmnd, 0
            IniRead, s4t1Star, Settings.ini, UserSettings, s4t1Star, 0
            IniRead, s4tGholdengo, Settings.ini, UserSettings, s4tGholdengo, 0
            IniRead, s4tWP, Settings.ini, UserSettings, s4tWP, 0
            IniRead, s4tWPMinCards, Settings.ini, UserSettings, s4tWPMinCards, 1
            IniRead, s4tDiscordWebhookURL, Settings.ini, UserSettings, s4tDiscordWebhookURL, ""
            IniRead, s4tDiscordUserId, Settings.ini, UserSettings, s4tDiscordUserId, ""
            IniRead, s4tSendAccountXml, Settings.ini, UserSettings, s4tSendAccountXml, 1
            
            ; Advanced settings
            IniRead, minStarsShiny, Settings.ini, UserSettings, minStarsShiny, 0
            IniRead, minStarsA1Charizard, Settings.ini, UserSettings, minStarsA1Charizard, 0
            IniRead, minStarsA1Mewtwo, Settings.ini, UserSettings, minStarsA1Mewtwo, 0
            IniRead, minStarsA1Pikachu, Settings.ini, UserSettings, minStarsA1Pikachu, 0
            IniRead, minStarsA1a, Settings.ini, UserSettings, minStarsA1a, 0
            IniRead, minStarsA2Dialga, Settings.ini, UserSettings, minStarsA2Dialga, 0
            IniRead, minStarsA2Palkia, Settings.ini, UserSettings, minStarsA2Palkia, 0
            IniRead, minStarsA2a, Settings.ini, UserSettings, minStarsA2a, 0
            IniRead, minStarsA3Solgaleo, Settings.ini, UserSettings, minStarsA3Solgaleo, 0
            IniRead, minStarsA3Lunala, Settings.ini, UserSettings, minStarsA3Lunala, 0
            IniRead, minStarsA3a, Settings.ini, UserSettings, minStarA3aBuzzwole, 0
            
            IniRead, heartBeatDelay, Settings.ini, UserSettings, heartBeatDelay, 30
            IniRead, sendAccountXml, Settings.ini, UserSettings, sendAccountXml, 0
            IniRead, showcaseEnabled, Settings.ini, UserSettings, showcaseEnabled, 0
            IniRead, showcaseLikes, Settings.ini, UserSettings, showcaseLikes, 5
            IniRead, isDarkTheme, Settings.ini, UserSettings, isDarkTheme, 1
            IniRead, useBackgroundImage, Settings.ini, UserSettings, useBackgroundImage, 1
            
            ; Extra Settings
            IniRead, tesseractPath, Settings.ini, UserSettings, tesseractPath, C:\Program Files\Tesseract-OCR\tesseract.exe
            IniRead, applyRoleFilters, Settings.ini, UserSettings, applyRoleFilters, 0
            IniRead, debugMode, Settings.ini, UserSettings, debugMode, 0
            IniRead, tesseractOption, Settings.ini, UserSettings, tesseractOption, 0
            IniRead, statusMessage, Settings.ini, UserSettings, statusMessage, 1
            
            ; Validate numeric values
            if (!IsNumeric(Instances) || Instances < 1)
                Instances := 1
            if (!IsNumeric(Columns) || Columns < 1)
                Columns := 5
            if (!IsNumeric(waitTime) || waitTime < 0)
                waitTime := 5
            if (!IsNumeric(Delay) || Delay < 10)
                Delay := 250
            
            ; Return success
            return true
        } else {
            ; Settings file doesn't exist, will use defaults
            return false
        }
    }
    
    ; Function to create the default settings file if it doesn't exist
    CreateDefaultSettingsFile() {
        if (!FileExist("Settings.ini")) {
            ; Create default settings file
            IniWrite, "", Settings.ini, UserSettings, FriendID
            IniWrite, "", Settings.ini, UserSettings, AccountName
            IniWrite, 5, Settings.ini, UserSettings, waitTime
            IniWrite, 250, Settings.ini, UserSettings, Delay
            IniWrite, C:\Program Files\Netease, Settings.ini, UserSettings, folderPath
            IniWrite, 5, Settings.ini, UserSettings, Columns
            IniWrite, Continue, Settings.ini, UserSettings, godPack
            IniWrite, 1, Settings.ini, UserSettings, Instances
            IniWrite, 0, Settings.ini, UserSettings, instanceStartDelay
            IniWrite, Scale125, Settings.ini, UserSettings, defaultLanguage
            IniWrite, 1, Settings.ini, UserSettings, SelectedMonitorIndex
            IniWrite, 300, Settings.ini, UserSettings, swipeSpeed
            IniWrite, 1, Settings.ini, UserSettings, runMain
            IniWrite, 1, Settings.ini, UserSettings, Mains
            IniWrite, 0, Settings.ini, UserSettings, heartBeat
            IniWrite, "", Settings.ini, UserSettings, heartBeatWebhookURL
            IniWrite, "", Settings.ini, UserSettings, heartBeatName
            IniWrite, 30, Settings.ini, UserSettings, heartBeatDelay
            IniWrite, C:\Program Files\Tesseract-OCR\tesseract.exe, Settings.ini, UserSettings, tesseractPath
            IniWrite, 0, Settings.ini, UserSettings, applyRoleFilters
            IniWrite, 0, Settings.ini, UserSettings, debugMode
            IniWrite, 0, Settings.ini, UserSettings, tesseractOption
            IniWrite, 1, Settings.ini, UserSettings, statusMessage
            IniWrite, 0, Settings.ini, UserSettings, showcaseEnabled
            IniWrite, "", Settings.ini, UserSettings, showcaseURL
            IniWrite, 5, Settings.ini, UserSettings, showcaseLikes
            IniWrite, 1, Settings.ini, UserSettings, isDarkTheme
            IniWrite, 1, Settings.ini, UserSettings, useBackgroundImage
            IniWrite, 100, Settings.ini, UserSettings, rowGap
            IniWrite, 15, Settings.ini, UserSettings, variablePackCount
            IniWrite, 0, Settings.ini, UserSettings, claimSpecialMissions
            IniWrite, 0, Settings.ini, UserSettings, spendHourGlass
            IniWrite, ModifiedAsc, Settings.ini, UserSettings, injectSortMethod
            IniWrite, 39, Settings.ini, UserSettings, injectMaxValue ; Default max value
            IniWrite, 35, Settings.ini, UserSettings, injectMinValue ; Default min value
            IniWrite, 1, Settings.ini, UserSettings, waitForEligibleAccounts
            IniWrite, 24, Settings.ini, UserSettings, maxWaitHours
            
            return true
        }
        return false
    }
    
    resetWindows(Title, SelectedMonitorIndex, silent := true) {
        global Columns, runMain, Mains, scaleParam, debugMode, rowGap
        RetryCount := 0
        MaxRetries := 10
        
        ; Use the configurable rowGap with fallback default of 100
        if (!rowGap)
            rowGap := 100
        
        Loop
        {
            try {
                ; Get monitor origin from index
                SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
                SysGet, Monitor, Monitor, %SelectedMonitorIndex%
                
                if (runMain) {
                    if (InStr(Title, "Main") = 1) {
                        instanceIndex := StrReplace(Title, "Main", "")
                        if (instanceIndex = "")
                            instanceIndex := 1
                    } else {
                        instanceIndex := (Mains - 1) + Title + 1
                    }
                } else {
                    instanceIndex := Title
                }
                
                rowHeight := 533 ; Adjust the height of each row
                currentRow := Floor((instanceIndex - 1) / Columns)
                y := currentRow * rowHeight + (currentRow * rowGap) ; Use the configurable gap
                x := Mod((instanceIndex - 1), Columns) * scaleParam
                WinMove, %Title%, , % (MonitorLeft + x), % (MonitorTop + y), scaleParam, 537
                break
            }
            catch {
                RetryCount++
                if (RetryCount > MaxRetries) {
                    if (!silent && debugMode)
                        MsgBox, Failed to position window %Title% after %MaxRetries% attempts
                    return false
                }
            }
            Sleep, 1000
        }
        return true
    }
    
    ; ====== For picture button======
    BuildfirstImagePath()
    {
        global
        IniRead, isDarkTheme, Settings.ini, UserSettings, isDarkTheme, 0
        IniRead, useBackgroundImage, Settings.ini, UserSettings, useBackgroundImage, 0
        
        frontpath := A_ScriptDir . "\Scripts\GuiImage\"
        
        if (isDarkTheme) {
            mode := "darkmod\"
        } else {
            mode := "lightmod\"
        }
        if (useBackgroundImage = 0) {
            BGPath := "close\"
            smallBtnBox := ""
        } else {
            BGPath := "open\"
        }
        
        btn_panelHover := frontpath . mode . "btn\set\panelHover.png"
        
        ; ========== set btn =========
        btn_settingPage := frontpath . mode . "btn\set\panel.png"
        btn_main := frontpath . mode . "btn\set\mainpage.png"
        
        ; ========= main btn =========
        btn_mainPage := frontpath . mode . "btn\main\panel.png"
        btn_setting := frontpath . mode . "btn\main\settingpage.png"
        
        ; ========= inset btn =========
        btn_inset := frontpath . mode . "btn\inset\goback.png"
        btn_next := frontpath . mode . "btn\inset\next.png"
        btn_previous := frontpath . mode . "btn\inset\previous.png"
        btn_nextHover := frontpath . mode . "btn\inset\nextHover.png"
        btn_previousHover := frontpath . mode . "btn\inset\previousHover.png"
        
        ; ========== background image and other =========
        bg_main := frontpath . mode . "background\" . BGPath . "main.png"
        bg_inset := frontpath . mode . "background\" . BGPath . "inset.png"
        bg_set := frontpath . mode . "background\" . BGPath . "set.png"
        title_set := frontpath . "other\title_set.png"
        title_main := frontpath . "other\title_main.png"
        title_box := frontpath . "other\title_box.png"
        
        ; ========== License ==========
        license := frontpath . mode . "other\License.png"
    }
    
    BuildImagePath(isDarkTheme, useBackgroundImage)
    {
        global
        IniWrite, %isDarkTheme%, Settings.ini, UserSettings, isDarkTheme
        IniWrite, %useBackgroundImage%, Settings.ini, UserSettings, useBackgroundImage
        IniRead, useBackgroundImage, Settings.ini, UserSettings, useBackgroundImage
        IniRead, isDarkTheme, Settings.ini, UserSettings, isDarkTheme
        
        frontpath := A_ScriptDir . "\Scripts\GuiImage\"
        
        if (isDarkTheme) {
            mode := "darkmod\"
        } else {
            mode := "lightmod\"
        }
        
        if (useBackgroundImage = 0) {
            BGPath := "close\"
        } else {
            BGPath := "open\"
        }
        
        btn_panelHover := frontpath . mode . "btn\set\panelHover.png"
        
        ; ========== set btn =========
        btn_settingPage := frontpath . mode . "btn\set\panel.png"
        btn_main := frontpath . mode . "btn\set\mainpage.png"
        
        ; ========= main btn =========
        btn_mainPage := frontpath . mode . "btn\main\panel.png"
        btn_setting := frontpath . mode . "btn\main\settingpage.png"
        
        ; ========= inset btn =========
        btn_inset := frontpath . mode . "btn\inset\goback.png"
        btn_next := frontpath . mode . "btn\inset\next.png"
        btn_previous := frontpath . mode . "btn\inset\previous.png"
        btn_nextHover := frontpath . mode . "btn\inset\nextHover.png"
        btn_previousHover := frontpath . mode . "btn\inset\previousHover.png"
        
        ; ========== background image and other =========
        bg_main := frontpath . mode . "background\" . BGPath . "main.png"
        bg_inset := frontpath . mode . "background\" . BGPath . "inset.png"
        bg_set := frontpath . mode . "background\" . BGPath . "set.png"
        
        ; ========== License ==========
        license := frontpath . mode . "other\License.png"
        
        UpdateGui()
    }
    
    UpdateGui() {
        global
        ; btn
        GuiControl,, Btn_RerollSettings, %btn_settingPage%
        GuiControl,, Btn_SystemSettings, %btn_settingPage%
        GuiControl,, Btn_PackSettings, %btn_settingPage%
        GuiControl,, Btn_SaveForTrade, %btn_settingPage%
        GuiControl,, Btn_DiscordSettings, %btn_settingPage%
        GuiControl,, Btn_DownloadSettings, %btn_settingPage%
        GuiControl,, Btn_Arrange, %btn_mainPage%
        GuiControl,, Btn_Coffee, %btn_mainPage%
        GuiControl,, Btn_Join, %btn_mainPage%
        GuiControl,, Btn_Mumu, %btn_mainPage%
        GuiControl,, Btn_Start, %btn_mainPage%
        GuiControl,, Btn_Update, %btn_mainPage%
        GuiControl,, Btn_BalanceXMLs, %btn_mainPage%
        GuiControl,, Btn_previous, %btn_previous%
        GuiControl,, Btn_next, %btn_next%
        
        ; Hover
        GuiControl,, Hover_Arrange, %btn_panelHover%
        GuiControl,, Hover_Coffee, %btn_panelHover%
        GuiControl,, Hover_Join, %btn_panelHover%
        GuiControl,, Hover_Mumu, %btn_panelHover%
        GuiControl,, Hover_BalanceXMLs, %btn_panelHover%
        GuiControl,, Hover_Start, %btn_panelHover%
        GuiControl,, Hover_Update, %btn_panelHover%
        GuiControl,, Hover_RerollSettings, %btn_panelHover%
        GuiControl,, Hover_SystemSettings, %btn_panelHover%
        GuiControl,, Hover_PackSettings, %btn_panelHover%
        GuiControl,, Hover_SaveForTrade, %btn_panelHover%
        GuiControl,, Hover_DiscordSettings, %btn_panelHover%
        GuiControl,, Hover_DownloadSettings, %btn_panelHover%
        GuiControl,, Hover_previous, %btn_previousHover%
        GuiControl,, Hover_next, %btn_nextHover%
        
        ; background
        GuiControl,, Bg_main, %bg_main%
        GuiControl,, Bg_set, %bg_set%
        GuiControl,, Bg_inset, %bg_inset%
        
        ; other
        GuiControl,, Ot_license, %license%
    }
    ; First, try to load existing settings
    settingsLoaded := LoadSettingsFromIni()
    
    ; If no settings were loaded, create a default settings file
    if (!settingsLoaded) {
        CreateDefaultSettingsFile()
        ; Now load the default settings we just created
        LoadSettingsFromIni()
    }
    
    CheckForUpdate()
    KillADBProcesses()
    scriptName := StrReplace(A_ScriptName, ".ahk")
    winTitle := scriptName
    showStatus := true
    totalFile := A_ScriptDir . "\json\total.json"
    backupFile := A_ScriptDir . "\json\total-backup.json"
    if FileExist(totalFile) ; Check if the file exists
    {
        FileCopy, %totalFile%, %backupFile%, 1 ; Copy source file to target
        if (ErrorLevel)
            MsgBox, Failed to create %backupFile%. Ensure permissions and paths are correct.
    }
    FileDelete, %totalFile%
    packsFile := A_ScriptDir . "\json\Packs.json"
    backupFile := A_ScriptDir . "\json\Packs-backup.json"
    if FileExist(packsFile) ; Check if the file exists
    {
        FileCopy, %packsFile%, %backupFile%, 1 ; Copy source file to target
        if (ErrorLevel)
            MsgBox, Failed to create %backupFile%. Ensure permissions and paths are correct.
    }
    InitializeJsonFile() ; Create or open the JSON file
    BuildfirstImagePath()
    
    ; Initialize with dark theme
    if (isDarkTheme)
        Gui, Color, %DARK_BG%, %DARK_CONTROL_BG% ; Dark theme
    else
        Gui, Color, %LIGHT_BG%, %LIGHT_CONTROL_BG% ; Light theme
    
    ; ALL BUTTON
    global title_set, Txt_title_set
    global Btn_RerollSettings, Btn_SystemSettings, Btn_PackSettings, Btn_SaveForTrade, Btn_DiscordSettings, Btn_DownloadSettings
    global Txt_Btn_RerollSettings, Txt_Btn_SystemSettings, Txt_Btn_PackSettings, Txt_Btn_SaveForTrade, Txt_Btn_DiscordSettings, Txt_Btn_DownloadSettings
    global Hover_RerollSettings, Hover_SystemSettings, Hover_PackSettings, Hover_SaveForTrade, Hover_DiscordSettings, Hover_DownloadSettings
    global Btn_main, Txt_Btn_main
    
    global title_main, Txt_title_main
    global Btn_Arrange, Btn_Coffee, Btn_Join, Btn_Mumu, Btn_BalanceXMLs, Btn_Start, Btn_Update, Btn_Setting
    global Txt_Btn_Arrange, Txt_Btn_Coffee, Txt_Btn_Join, Txt_Btn_Mumu, Txt_Btn_BalanceXMLs, Txt_Btn_Start, Txt_Btn_Update, Txt_Btn_Setting
    global Hover_Arrange, Hover_Coffee, Hover_Join, Hover_Mumu, Hover_BalanceXMLs, Hover_Start, Hover_Update
    global Btn_previous, Btn_next, Btn_inset, Txt_Btn_inset
    global Hover_previous, Hover_next
    
    global Ot_license, Txt_license
    global Btn_ToolTip, Btn_Language, Btn_reload, BackgroundToggle, ThemeToggle
    
    ;; Choose Settings page
    Gui, Add, Picture, x0 y0 w%GUI_WIDTH% h%GUI_HEIGHT% vBg_set Hidden, %bg_set%
    Gui, Add, Picture, x20 y175 vPanel_set backgroundtrans Hidden, %panel_set%
    PageBtnShift(defaultBotLanguage)
    SetPageTitleFont()
    TestHover := AddBtn("Picture", 20, 92, 315, 54, "title_set", "", currentDictionary.title_set, title_set, "Txt_title_set", (37+xs_TitleSet), 102)
    
    SetPanelBtnFont()
    RerollSettingsBtn := AddBtn("Picture", 43, 190, 298, 54, "Btn_RerollSettings", "", "", btn_settingPage)
    RerollSettingsHover := AddBtn("Picture", 43, 190, 298, 54, "Hover_RerollSettings", "ToggleSection", currentDictionary.btn_reroll, btn_panelHover, "Txt_Btn_RerollSettings", (131+xs_Reroll), (200+ys))
    
    SystemSettingsBtn := AddBtn("Picture", 45, 244, 298, 54, "Btn_SystemSettings", "", "", btn_settingPage)
    SystemSettingsHover := AddBtn("Picture", 45, 244, 298, 54, "Hover_SystemSettings", "ToggleSection", currentDictionary.btn_system, btn_panelHover, "Txt_Btn_SystemSettings", (125+xs_System), (254+ys))
    
    PackSettingsBtn := AddBtn("Picture", 45, 298, 298, 54, "Btn_PackSettings", "", "", btn_settingPage)
    PackSettingsHover := AddBtn("Picture", 45, 298, 298, 54, "Hover_PackSettings", "ToggleSection", currentDictionary.btn_pack, btn_panelHover, "Txt_Btn_PackSettings", (135+xs_Pack), (309+ys))
    
    SaveForTradeBtn := AddBtn("Picture", 45, 352, 298, 54, "Btn_SaveForTrade", "", "", btn_settingPage)
    SaveForTradeHover := AddBtn("Picture", 45, 352, 298, 54, "Hover_SaveForTrade", "ToggleSection", currentDictionary.btn_save, btn_panelHover, "Txt_Btn_SaveForTrade", (132+xs_Trade), (362+ys))
    
    DiscordSettingsBtn := AddBtn("Picture", 45, 406, 298, 54, "Btn_DiscordSettings", "", "", btn_settingPage)
    DiscordSettingsHover := AddBtn("Picture", 45, 406, 298, 54, "Hover_DiscordSettings", "ToggleSection", currentDictionary.btn_discord, btn_panelHover, "Txt_Btn_DiscordSettings", (125+xs_Discord), (416+ys))
    
    DownloadSettingsBtn := AddBtn("Picture", 45, 460, 298, 54, "Btn_DownloadSettings", "", "", btn_settingPage)
    DownloadSettingsHover := AddBtn("Picture", 45, 460, 298, 54, "Hover_DownloadSettings", "ToggleSection", currentDictionary.btn_download, btn_panelHover, "Txt_Btn_DownloadSettings", (115+xs_Download), (470+ys))
    
    SetPageBtnFont()
    TestHover := AddBtn("Picture", 90, 575, 204, 68, "Btn_main", "SettingPage", currentDictionary.btn_main, btn_main, "Txt_Btn_main", (142+xs_MainPage), (590+ys))
    ;; Main Page
    Gui, Add, Picture, x0 y0 w%GUI_WIDTH% h%GUI_HEIGHT% vBg_main, %bg_main%
    
    SetPageTitleFont()
    TestHover := AddBtn("Picture", 20, 68, 221, 72, "title_main", "", currentDictionary.title_main . "`n" . localVersion . " " . intro, title_main, "Txt_title_main", 40, 76)
    
    SetPanelBtnFont()
    ArrangeBtn := AddBtn("Picture", 45, 157, 298, 54, "Btn_Arrange", "", "", btn_mainPage)
    ArrangeHover := AddBtn("Picture", 45, 157, 298, 54, "Hover_Arrange", "ArrangeWindows", currentDictionary.btn_arrange, btn_panelHover, "Txt_Btn_Arrange", (120+xs_Arrange), (167+ys))
    
    CoffeeBtn := AddBtn("Picture", 45, 211, 298, 54, "Btn_Coffee", "", "", btn_mainPage)
    CoffeeHover := AddBtn("Picture", 45, 211, 298, 54, "Hover_Coffee", "OpenLink", currentDictionary.btn_coffee, btn_panelHover, "Txt_Btn_Coffee", (125+xs_Coffee), (221+ys))
    
    JoinBtn := AddBtn("Picture", 45, 268, 298, 54, "Btn_Join", "", , btn_mainPage)
    JoinHover := AddBtn("Picture", 45, 268, 298, 54, "Hover_Join", "OpenDiscord", currentDictionary.btn_join, btn_panelHover, "Txt_Btn_Join", (143+xs_Join), (278+ys))
    
    MumuBtn := AddBtn("Picture", 45, 324, 298, 54, "Btn_Mumu", "", "", btn_mainPage)
    MumuHover := AddBtn("Picture", 45, 324, 298, 54, "Hover_Mumu", "LaunchAllMumu", currentDictionary.btn_mumu, btn_panelHover, "Txt_Btn_Mumu", (126+xs_Launch), (334+ys))
    
    BalanceXMLsBtn := AddBtn("Picture", 45, 379, 298, 54, "Btn_BalanceXMLs", "", "", btn_mainPage)
    BalanceXMLsHover := AddBtn("Picture", 45, 379, 298, 54, "Hover_BalanceXMLs", "BalanceXMLs", currentDictionary.btn_balance, btn_panelHover, "Txt_Btn_BalanceXMLs", (136+xs_Balance), (389+ys))
    
    StartBtn := AddBtn("Picture", 45, 436, 298, 54, "Btn_Start", "", "", btn_mainPage)
    StartHover := AddBtn("Picture", 45, 436, 298, 54, "Hover_Start", "StartBot", currentDictionary.btn_start, btn_panelHover, "Txt_Btn_Start", (152+xs_Start), (446+ys))
    
    UpdateBtn := AddBtn("Picture", 45, 491, 298, 54, "Btn_Update", "", "", btn_mainPage)
    UpdateHover := AddBtn("Picture", 45, 491, 298, 54, "Hover_Update", "CheckForUpdates", currentDictionary.btn_update, btn_panelHover, "Txt_Btn_Update", (125+xs_Update), (501+ys))
    SetPageBtnFont()
    TestHover := AddBtn("Picture", 85, 590, 204, 68, "Btn_Setting", "MainPage", currentDictionary.btn_setting, btn_setting, "Txt_Btn_Setting", (122+xs_SettingPage), (604+ys_SettingPage))
    ;; Settings Page
    Gui, Add, Picture, x0 y0 w%GUI_WIDTH% h%GUI_HEIGHT% vBg_inset Hidden, %bg_inset%
    
    previousBtn := AddBtn("Picture", 280, 525, 30, 30, "Btn_previous", "", "", btn_previous)
    previousHover := AddBtn("Picture", 280, 525, 30, 30, "Hover_previous", "Previous", "", btn_previousHover)
    nextBtn := AddBtn("Picture", 320, 525, 30, 30, "Btn_next", "", "", btn_next)
    nextHover := AddBtn("Picture", 320, 525, 30, 30, "Hover_next", "Next", "", btn_nextHover)
    SetPageBtnFont()
    TestHover := AddBtn("Picture", 85, 590, 204, 68, "Btn_inset", "GoBackPage", currentDictionary.btn_return, btn_inset, "Txt_Btn_inset", (137+xs_Return), (604+ys_Return))
    
    SetPageTitleFont()
    Gui, Add, Picture, x20 y77 w211 h51 vtitle_box backgroundtrans Hidden, %title_box%
    Gui, Add, Text, x37 y85 vtitle_download backgroundtrans Hidden, % currentDictionary.btn_download
    Gui, Add, Text, x37 y85 vtitle_discord backgroundtrans Hidden, % currentDictionary.btn_discord
    Gui, Add, Text, x37 y85 vtitle_trade backgroundtrans Hidden, % currentDictionary.btn_save
    Gui, Add, Text, x37 y85 vtitle_pack backgroundtrans Hidden, % currentDictionary.btn_pack
    Gui, Add, Text, x37 y85 vtitle_system backgroundtrans Hidden, % currentDictionary.btn_system
    Gui, Add, Text, x37 y85 vtitle_reroll backgroundtrans Hidden, % currentDictionary.btn_reroll
    
    SetLicenseFont()
    ; header & licence
    TestHover := AddBtn("Picture", 16, 11, 349, 26, "Ot_license", "", "PTCGPB " . localVersion . " (Licensed under CC BY-NC 4.0 international license)", license, "Txt_license", 45, 18)
    
    SetSmallBtnFont()
    
    ; Add ToolTip Button
    TestHover := AddBtn("Text", (38+xs_ToolTip), (45+ys_ToolTip), "", "", "Btn_ToolTip", "OpenToolTip", currentDictionary.btn_ToolTip)
    
    ; Add language toggle button next to reload
    TestHover := AddBtn("Text", (93+xs_Language), (45+ys_Language), "", "", "Btn_Language", "SwitchLanguage", currentDictionary.btn_Language)
    
    ; Add reload button next to background toggle
    TestHover := AddBtn("Text", (162+xs_Reload), (45+ys_Reload), "", "", "Btn_reload", "SaveReload", currentDictionary.btn_reload)
    
    ; Add background toggle button next to theme toggle
    TestHover := AddBtn("Text", (216+xs_Background), (45+ys_Background), "", "", "BackgroundToggle", "ToggleBackground", currentDictionary.btn_bg_Off)
    
    ; Add theme toggle button
    TestHover := AddBtn("Text", (316+xs_Theme), (45+ys_Theme), "", "", "ThemeToggle", "ToggleTheme", currentDictionary.btn_theme_Dark)
    Gui, Font, norm
    
    global Txt_runMain, Txt_slowMotion,
    global Txt_autoLaunchMonitor, Txt_applyRoleFilters, Txt_debugMode, Txt_tesseractOption, Txt_statusMessage
    global Txt_packMethod, Txt_nukeAccount, Txt_spendHourGlass, Txt_claimSpecialMissions
    global Txt_Buzzwole, Txt_Solgaleo, Txt_Lunala, Txt_Shining, Txt_Arceus, Txt_Palkia, Txt_Dialga, Txt_Pikachu, Txt_Charizard, Txt_Mewtwo, Txt_Mew
    global Txt_FullArtCheck, Txt_TrainerCheck, Txt_RainbowCheck, Txt_PseudoGodPack, Txt_CrownCheck, Txt_ShinyCheck, Txt_ImmersiveCheck, Txt_CheckShiningPackOnly, Txt_InvalidCheck
    global Txt_s4tEnabled, Txt_s4tSilent
    global Txt_s4t3Dmnd, Txt_s4t4Dmnd, Txt_s4t1Star, s4tGholdengoArrow, Txt_s4tWP, Txt_s4tSendAccountXml
    global Txt_sendAccountXml, Txt_heartBeat
    global Txt_showcaseEnabled
    ;; Friend ID Section
    SetInputFont()
    Gui, Add, Text, x45 y150 vFriendIDLabel backgroundtrans Hidden, % currentDictionary.FriendIDLabel
    if(FriendID = "ERROR" || FriendID = "") {
        Gui, Add, Edit, vFriendID w290 x45 y175 h20 -E0x200 Center backgroundtrans Hidden
    } else {
        Gui, Add, Edit, vFriendID w290 x45 y175 h20 -E0x200 Center backgroundtrans Hidden, %FriendID%
    }
    
    ; Add divider for Friend ID section
    AddSectionDivider(45, 200, 285, "FriendID_Divider")
    
    ;; Instance Settings Section
    SetNormalFont()
    Gui, Add, Text, x45 y205 backgroundtrans Hidden vTxt_Instances, % currentDictionary.Txt_Instances
    Gui, Add, Edit, vInstances cFDFDFD w30 x220 y205 h20 -E0x200 Center backgroundtrans Hidden, %Instances%
    
    Gui, Add, Text, x45 y230 backgroundtrans Hidden vTxt_InstanceStartDelay, % currentDictionary.Txt_InstanceStartDelay
    Gui, Add, Edit, vinstanceStartDelay cFDFDFD w30 x220 y230 h20 -E0x200 Center backgroundtrans Hidden, %instanceStartDelay%
    
    Gui, Add, Text, x45 y255 backgroundtrans Hidden vTxt_Columns, % currentDictionary.Txt_Columns
    Gui, Add, Edit, vColumns cFDFDFD w30 x220 y255 h20 -E0x200 Center backgroundtrans Hidden, %Columns%
    
    AddCheckBox(45, 282, 28, 13, "runMain", "mainSettings", "Gui_checked.png", "Gui_unchecked.png", runMain, "Txt_runMain", currentDictionary.Txt_runMain, 80, 280)
    Gui, Add, Edit, % "vMains cFDFDFD w30 x220 y280 h20 -E0x200 Center Hidden " . (runMain ? "" : " backgroundtrans Hidden"), %Mains%
    Gui, Add, Text, x45 y305 backgroundtrans Hidden vTxt_AccountName, % currentDictionary.Txt_AccountName
    Gui, Add, Edit, vAccountName cFDFDFD w130 x45 y330 h20 -E0x200 Center backgroundtrans Hidden, %AccountName%
    
    ; Add dividers for Instance Settings section
    AddSectionDivider(45, 355, 285, "Instance_Divider3")
    ;; Time Settings Section
    SetNormalFont()
    Gui, Add, Text, x45 y360 backgroundtrans Hidden vTxt_Delay, % currentDictionary.Txt_Delay
    Gui, Add, Edit, vDelay cFDFDFD w35 x220 y360 h20 -E0x200 Center backgroundtrans Hidden, %Delay%
    
    Gui, Add, Text, x45 y385 backgroundtrans Hidden vTxt_WaitTime, % currentDictionary.Txt_WaitTime
    Gui, Add, Edit, vwaitTime cFDFDFD w35 x220 y385 h20 -E0x200 Center backgroundtrans Hidden, %waitTime%
    
    Gui, Add, Text, x45 y410 backgroundtrans Hidden vTxt_SwipeSpeed, % currentDictionary.Txt_SwipeSpeed
    Gui, Add, Edit, vswipeSpeed cFDFDFD w35 x220 y410 h20 -E0x200 Center backgroundtrans Hidden, %swipeSpeed%
    
    AddCheckBox(45, 436, 28, 13, "slowMotion", "", "Gui_checked.png", "Gui_unchecked.png", slowMotion, "Txt_slowMotion", currentDictionary.Txt_slowMotion, 80, 435)
    
    ;; System Settings Section
    SetNormalFont()
    SysGet, MonitorCount, MonitorCount
    MonitorOptions := ""
    Loop, %MonitorCount% {
        SysGet, MonitorName, MonitorName, %A_Index%
        SysGet, Monitor, Monitor, %A_Index%
        MonitorOptions .= (A_Index > 1 ? "|" : "") "" A_Index ": (" MonitorRight - MonitorLeft "x" MonitorBottom - MonitorTop ")"
    }
    SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
    
    Gui, Add, Text, x45 y150 backgroundtrans Hidden vTxt_Monitor, % currentDictionary.Txt_Monitor
    Gui, Add, DropDownList, x190 y148 w110 vSelectedMonitorIndex Choose%SelectedMonitorIndex% -E0x200 Center BackgroundTrans Hidden, %MonitorOptions%
    
    Gui, Add, Text, x45 y175 backgroundtrans Hidden vTxt_Scale, % currentDictionary.Txt_Scale
    if (defaultLanguage = "Scale125") {
        defaultLang := 1
        scaleParam := 277
    } else if (defaultLanguage = "Scale100") {
        defaultLang := 2
        scaleParam := 287
    }
    
    Gui, Add, DropDownList, x190 y173 w80 vdefaultLanguage gdefaultLangSetting choose%defaultLang% -E0x200 Center backgroundtrans Hidden, Scale125
    
    Gui, Add, Text, x45 y200 backgroundtrans Hidden vTxt_RowGap, % currentDictionary.Txt_RowGap
    Gui, Add, Edit, vRowGap cFDFDFD w80 x190 y198 h20 -E0x200 Center backgroundtrans Hidden, %RowGap%
    Gui, Add, Text, x45 y225 backgroundtrans Hidden vTxt_FolderPath, % currentDictionary.Txt_FolderPath
    Gui, Add, Edit, vfolderPath cFDFDFD w140 x190 y223 h20 -E0x200 Center backgroundtrans Hidden, %folderPath%
    Gui, Add, Text, x45 y250 backgroundtrans Hidden vTxt_OcrLanguage, % currentDictionary.Txt_OcrLanguage
    ; ========== Language Pack list ==========
    ocrLanguageList := "en|zh|es|de|fr|ja|ru|pt|ko|it|tr|pl|nl|sv|ar|uk|id|vi|th|he|cs|no|da|fi|hu|el|zh-TW"
    if (ocrLanguage != "")
    {
        index := 0
        Loop, Parse, ocrLanguageList, |
        {
            index++
            if (A_LoopField = ocrLanguage)
            {
                defaultOcrLang := index
                break
            }
        }
    }
    
    Gui, Add, DropDownList, x190 y248 w60 vocrLanguage choose%defaultOcrLang% -E0x200 Center backgroundtrans Hidden, %ocrLanguageList%
    
    Gui, Add, Text, x45 y275 backgroundtrans Hidden vTxt_ClientLanguage, % currentDictionary.Txt_ClientLanguage
    
    ; ========== Client Language Pack list ==========
    clientLanguageList := "en|es|fr|de|it|pt|jp|ko|cn"
    
    if (clientLanguage != "")
    {
        index := 0
        Loop, Parse, clientLanguageList, |
        {
            index++
            if (A_LoopField = clientLanguage)
            {
                defaultClientLang := index
                break
            }
        }
    }
    Gui, Add, DropDownList, x190 y273 w60 vclientLanguage choose%defaultClientLang% -E0x200 Center backgroundtrans Hidden, %clientLanguageList%
    
    Gui, Add, Text, x45 y300 backgroundtrans Hidden vTxt_InstanceLaunchDelay, % currentDictionary.Txt_InstanceLaunchDelay
    Gui, Add, Edit, vinstanceLaunchDelay cFDFDFD w40 x190 y300 h20 -E0x200 Center backgroundtrans Hidden, %instanceLaunchDelay%
    
    AddCheckBox(45, 326, 28, 13, "autoLaunchMonitor", "", "Gui_checked.png", "Gui_unchecked.png", autoLaunchMonitor, "Txt_autoLaunchMonitor", currentDictionary.Txt_autoLaunchMonitor, 80, 325)
    
    SetHeaderFont()
    Gui, Add, Text, x45 y350 backgroundtrans Hidden vExtraSettingsHeading, % currentDictionary.ExtraSettingsHeading
    SetNormalFont()
    
    ; First add Role-Based Filters
    AddCheckBox(45, 376, 28, 13, "applyRoleFilters", "", "Gui_checked.png", "Gui_unchecked.png", applyRoleFilters, "Txt_applyRoleFilters", currentDictionary.Txt_applyRoleFilters, 80, 375)
    
    ; Then add Debug Mode
    AddCheckBox(45, 401, 28, 13, "debugMode", "", "Gui_checked.png", "Gui_unchecked.png", debugMode, "Txt_debugMode", currentDictionary.Txt_debugMode, 80, 400)
    
    ; Then add the Use Tesseract checkbox
    AddCheckBox(45, 426, 28, 13, "tesseractOption", "TesseractOptionSettings", "Gui_checked.png", "Gui_unchecked.png", tesseractOption, "Txt_tesseractOption", currentDictionary.Txt_tesseractOption, 80, 425)
    
    ; Then add status messages
    AddCheckBox(45, 451, 28, 13, "statusMessage", "", "Gui_checked.png", "Gui_unchecked.png", statusMessage, "Txt_statusMessage", currentDictionary.Txt_statusMessage, 80, 450)
    
    ; Keep Tesseract Path at the end
    Gui, Add, Text, x45 y475 backgroundtrans Hidden vTxt_TesseractPath, % currentDictionary.Txt_TesseractPath
    Gui, Add, Edit, vtesseractPath cFDFDFD w280 x45 y500 h20 -E0x200 backgroundtrans Hidden, %tesseractPath%
    
    ;; Pack Settings Section
    PackControlsShift(defaultBotLanguage)
    SetNormalFont()
    tempX := 110+xs_Min2star
    Gui, Add, Text, x45 y150 backgroundtrans Hidden vTxt_MinStars, % currentDictionary.Txt_MinStars
    Gui, Add, Edit, vminStars cFDFDFD w40 x%tempX% y149 h20 -E0x200 Center backgroundtrans Hidden, %minStars%
    
    tempX := 170+xs_MinShing
    Gui, Add, Text, x%tempX% y150 backgroundtrans Hidden vTxt_ShinyMinStars, % currentDictionary.Txt_ShinyMinStars
    Gui, Add, Edit, vminStarsShiny cFDFDFD w40 x290 y149 h20 -E0x200 Center backgroundtrans Hidden, %minStarsShiny%
    
    Gui, Add, Text, x45 y175 backgroundtrans Hidden vTxt_DeleteMethod, % currentDictionary.Txt_DeleteMethod
    
    Gui, Add, DropDownList, x110 y173 w120 vdeleteMethod gdeleteSettings choose%defaultDelete% -E0x200 backgroundtrans Hidden, 13 Pack|Inject|Inject Missions|Inject for Reroll
    
    ; FIXED: Determine correct selection index based on loaded deleteMethod value
    defaultDelete := 1 ; Default to first option (13 Pack)
    if (deleteMethod = "13 Pack")
        defaultDelete := 1
    else if (deleteMethod = "Inject")
        defaultDelete := 2
    else if (deleteMethod = "Inject Missions")
        defaultDelete := 3
    else if (deleteMethod = "Inject for Reroll")
        defaultDelete := 4
    
    ; Apply the correct selection
    GuiControl, Choose, deleteMethod, %defaultDelete%
    
    ;Gui, Add, Text, x245 y175 BackgroundTrans Hidden vTxt_InjectMaxValue, % currentDictionary.Txt_InjectMaxValue
    ;Gui, Add, Edit, vinjectMaxValue w40 x290 y174 h20 -E0x200 Center backgroundtrans Hidden, %injectMaxValue%
    
    ;Gui, Add, Text, x245 y175 BackgroundTrans Hidden vTxt_InjectMinValue, % currentDictionary.Txt_InjectMinValue
    ;Gui, Add, Edit, vinjectMinValue w40 x290 y174 h20 -E0x200 Center backgroundtrans Hidden, %injectMaxValue%
    
    ;Gui, Add, Text, x245 y175 BackgroundTrans Hidden vTxt_InjectRange, % currentDictionary.Txt_InjectRange
    ;Gui, Add, Edit, vinjectRange w40 x290 y174 h20 -E0x200 Center backgroundtrans Hidden, %injectRange%
    
    AddCheckBox(45, 201, 28, 13, "packMethod", "", "Gui_checked.png", "Gui_unchecked.png", packMethod, "Txt_packMethod", currentDictionary.Txt_packMethod, 80, 200)
    AddCheckBox(185, 201, 28, 13, "nukeAccount", "", "Gui_checked.png", "Gui_unchecked.png", nukeAccount, "Txt_nukeAccount", currentDictionary.Txt_nukeAccount, 220, 200)
    AddCheckBox(45, 226, 28, 13, "spendHourGlass", "", "Gui_checked.png", "Gui_unchecked.png", spendHourGlass, "Txt_spendHourGlass", currentDictionary.Txt_spendHourGlass, 80, 225)
    ;AddCheckBox((185+xs_SpecialCheck), 226, 28, 13, "claimSpecialMissions", "", "Gui_checked.png", "Gui_unchecked.png", claimSpecialMissions, "Txt_claimSpecialMissions", currentDictionary.Txt_claimSpecialMissions, (220+xs_SpecialCheck), 225)
    
    ; Create Sort By label and dropdown
    SetNormalFont()
    
    ; Determine which option to pre-select
    sortOption := 1 ; Default (ModifiedAsc)
    if (injectSortMethod = "ModifiedDesc")
        sortOption := 2
    else if (injectSortMethod = "PacksAsc")
        sortOption := 3
    else if (injectSortMethod = "PacksDesc")
        sortOption := 4
    
    ; Create the controls with static positions but unique variable names
    tempX := 110+xs_Sort
    Gui, Add, Text, x45 y250 vSortByText BackgroundTrans Hidden, % currentDictionary.SortByText
    Gui, Add, DropDownList, x%tempX% y248 w120 vSortByDropdown gSortByDropdownHandler Choose%sortOption% BackgroundTrans Hidden, Oldest First|Newest First|Fewest Packs First|Most Packs First
    
    ; Add divider for God Pack Settings section
    AddSectionDivider(45, 275, 285, "Pack_Divider1")
    
    ; === Pack Selection Subsection ===
    SetNormalFont()
    ; Latest 4 Packs
    AddCheckBox(45, 301, 28, 13, "Buzzwole", "", "Gui_checked.png", "Gui_unchecked.png", Buzzwole, "Txt_Buzzwole", currentDictionary.Txt_Buzzwole, 80, 300)
    AddCheckBox(190, 301, 28, 13, "Solgaleo", "", "Gui_checked.png", "Gui_unchecked.png", Solgaleo, "Txt_Solgaleo", currentDictionary.Txt_Solgaleo, 225, 300)
    AddCheckBox(45, 326, 28, 13, "Lunala", "", "Gui_checked.png", "Gui_unchecked.png", Lunala, "Txt_Lunala", currentDictionary.Txt_Lunala, 80, 325)
    AddCheckBox(190, 326, 28, 13, "Shining", "", "Gui_checked.png", "Gui_unchecked.png", Shining, "Txt_Shining", currentDictionary.Txt_Shining, 225, 325)
    ; Page for all pack settings
    global AllPackSelection, Btn_returnPack, Txt_Btn_returnPack
    global Page_Buzzwole, Page_Solgaleo, Page_Lunala, Page_Shining
    global Txt_PageBuzzwole,Txt_PageSolgaleo, Txt_PageLunala, Txt_PageShining, Txt_PageArceus
    SetSmallBtnFont()
    TestHover := AddBtn("Text", 235, 360, "", "", "AllPackSelection", "GoPackSelect", currentDictionary.AllPack, "", "", "", "")
    
    SetSectionFont()
    Gui, Add, Text, x45 y150 vTxt_PackHeading BackgroundTrans Hidden, % currentDictionary.PackHeading
    
    SetNormalFont()
    Yline := 185
    Xline := 55
    AddCheckBox(Xline, (Yline+1), 28, 13, "Page_Buzzwole", "PackCheck", "Gui_checked.png", "Gui_unchecked.png", Buzzwole, "Txt_PageBuzzwole", currentDictionary.Txt_Buzzwole, (Xline+35), Yline)
    Xline += 155
    AddCheckBox(Xline, (Yline+1), 28, 13, "Page_Solgaleo", "PackCheck", "Gui_checked.png", "Gui_unchecked.png", Solgaleo, "Txt_PageSolgaleo", currentDictionary.Txt_Solgaleo, (Xline+35), Yline)
    Xline -= 155
    Yline += 25
    AddCheckBox(Xline, (Yline+1), 28, 13, "Page_Lunala", "PackCheck", "Gui_checked.png", "Gui_unchecked.png", Lunala, "Txt_PageLunala", currentDictionary.Txt_Lunala, (Xline+35), Yline)
    Xline += 155
    AddCheckBox(Xline, (Yline+1), 28, 13, "Page_Shining", "PackCheck", "Gui_checked.png", "Gui_unchecked.png", Shining, "Txt_PageShining", currentDictionary.Txt_Shining, (Xline+35), Yline)
    Xline -= 155
    Yline += 25
    AddCheckBox(Xline, (Yline+1), 28, 13, "Arceus", "", "Gui_checked.png", "Gui_unchecked.png", Arceus, "Txt_Arceus", currentDictionary.Txt_Arceus, (Xline+35), Yline)
    Xline += 155
    AddCheckBox(Xline, (Yline+1), 28, 13, "Palkia", "", "Gui_checked.png", "Gui_unchecked.png", Palkia, "Txt_Palkia", currentDictionary.Txt_Palkia, (Xline+35), Yline)
    Xline -= 155
    Yline += 25
    AddCheckBox(Xline, (Yline+1), 28, 13, "Dialga", "", "Gui_checked.png", "Gui_unchecked.png", Dialga, "Txt_Dialga", currentDictionary.Txt_Dialga, (Xline+35), Yline)
    Xline += 155
    AddCheckBox(Xline, (Yline+1), 28, 13, "Pikachu", "", "Gui_checked.png", "Gui_unchecked.png", Pikachu, "Txt_Pikachu", currentDictionary.Txt_Pikachu, (Xline+35), Yline)
    Xline -= 155
    Yline += 25
    AddCheckBox(Xline, (Yline+1), 28, 13, "Charizard", "", "Gui_checked.png", "Gui_unchecked.png", Charizard, "Txt_Charizard", currentDictionary.Txt_Charizard, (Xline+35), Yline)
    Xline += 155
    AddCheckBox(Xline, (Yline+1), 28, 13, "Mewtwo", "", "Gui_checked.png", "Gui_unchecked.png", Mewtwo, "Txt_Mewtwo", currentDictionary.Txt_Mewtwo, (Xline+35), Yline)
    Xline -= 155
    Yline += 25
    AddCheckBox(Xline, (Yline+1), 28, 13, "Mew", "", "Gui_checked.png", "Gui_unchecked.png", Mew, "Txt_Mew", currentDictionary.Txt_Mew, (Xline+35), Yline)
    
    SetPageBtnFont()
    ReturnPackBtn := AddBtn("Picture", 85, 590, 204, 68, "Btn_returnPack", "ReturnPackSettingsSection", currentDictionary.btn_return, btn_inset, "Txt_Btn_returnPack", (137+xs_Return), (604+ys_Return))
    
    ; Add divider for Pack Selection section
    AddSectionDivider(45, 380, 285, "Pack_Divider2")
    ; === Card Detection Subsection ===
    SetNormalFont()
    ; 2-Column Layout for Card Detection Subsection
    AddCheckBox(45, 386, 28, 13, "FullArtCheck", "", "Gui_checked.png", "Gui_unchecked.png", FullArtCheck, "Txt_FullArtCheck", currentDictionary.Txt_FullArtCheck, 80, 385)
    AddCheckBox(45, 411, 28, 13, "TrainerCheck", "", "Gui_checked.png", "Gui_unchecked.png", TrainerCheck, "Txt_TrainerCheck", currentDictionary.Txt_TrainerCheck, 80, 410)
    AddCheckBox(45, 436, 28, 13, "RainbowCheck", "", "Gui_checked.png", "Gui_unchecked.png", RainbowCheck, "Txt_RainbowCheck", currentDictionary.Txt_RainbowCheck, 80, 435)
    AddCheckBox(45, 461, 28, 13, "PseudoGodPack", "", "Gui_checked.png", "Gui_unchecked.png", PseudoGodPack, "Txt_PseudoGodPack", currentDictionary.Txt_PseudoGodPack, 80, 460)
    AddCheckBox(45, 486, 28, 13, "CheckShiningPackOnly", "", "Gui_checked.png", "Gui_unchecked.png", CheckShiningPackOnly, "Txt_CheckShiningPackOnly", currentDictionary.Txt_CheckShiningPackOnly, 80, 485)
    
    AddCheckBox((190+xs_SaveCrown), 386, 28, 13, "CrownCheck", "", "Gui_checked.png", "Gui_unchecked.png", CrownCheck, "Txt_CrownCheck", currentDictionary.Txt_CrownCheck, (225+xs_SaveCrown), 385)
    AddCheckBox((190+xs_SaveShing), 411, 28, 13, "ShinyCheck", "", "Gui_checked.png", "Gui_unchecked.png", ShinyCheck, "Txt_ShinyCheck", currentDictionary.Txt_ShinyCheck, (225+xs_SaveShing), 410)
    AddCheckBox((190+xs_SaveImmer), 436, 28, 13, "ImmersiveCheck", "", "Gui_checked.png", "Gui_unchecked.png", ImmersiveCheck, "Txt_ImmersiveCheck", currentDictionary.Txt_ImmersiveCheck, (225+xs_SaveImmer), 435)
    AddCheckBox((190+xs_invalid), 461, 28, 13, "InvalidCheck", "", "Gui_checked.png", "Gui_unchecked.png", InvalidCheck, "Txt_InvalidCheck", currentDictionary.Txt_InvalidCheck, (225+xs_invalid), 460)
    
    ; Add divider for Card Detection section
    AddSectionDivider(45, 510, 285, "Pack_Divider3")
    
    ;; Save For Trade Section
    SetNormalFont()
    AddCheckBox(45, 151, 28, 13, "s4tEnabled", "s4tSettings", "Gui_checked.png", "Gui_unchecked.png", s4tEnabled, "Txt_s4tEnabled", currentDictionary.Txt_s4tEnabled, 80, 150)
    
    AddCheckBox(45, 181, 28, 13, "s4tSilent", "", "Gui_checked.png", "Gui_unchecked.png", s4tSilent, "Txt_s4tSilent", currentDictionary.Txt_s4tSilent, 80, 180)
    
    AddCheckBox(45, 206, 28, 13, "s4t3Dmnd", "", "Gui_checked.png", "Gui_unchecked.png", s4t3Dmnd, "Txt_s4t3Dmnd", "3 ◆◆◆", 80, 205)
    AddCheckBox(45, 231, 28, 13, "s4t4Dmnd", "", "Gui_checked.png", "Gui_unchecked.png", s4t4Dmnd, "Txt_s4t4Dmnd", "4 ◆◆◆◆", 80, 230)
    AddCheckBox(45, 256, 28, 13, "s4t1Star", "", "Gui_checked.png", "Gui_unchecked.png", s4t1Star, "Txt_s4t1Star", "1 ★", 80, 255)
    
    AddSectionDivider(45, 280, 285, "SaveForTradeDivider_1")
    
    AddCheckBox(185, 206, 28, 13, "s4tGholdengo", "", "Gui_checked.png", "Gui_unchecked.png", s4tGholdengo, "s4tGholdengoArrow", "➤", 220, 205)
    Gui, Add, Picture, % ((!s4tEnabled || !Shining) ? "backgroundtrans backgroundtrans Hidden " : "") . "vs4tGholdengoEmblem w25 h25 x240 y201 backgroundtrans Hidden", % A_ScriptDir . "\Scripts\GuiImage\other\GholdengoEmblem.png"
    
    AddCheckBox(45, 286, 28, 13, "s4tWP", "s4tWPSettings", "Gui_checked.png", "Gui_unchecked.png", s4tWP, "Txt_s4tWP", currentDictionary.Txt_s4tWP, 80, 285)
    
    Gui, Add, Text, % "vs4tWPMinCardsLabel x45 y310 backgroundtrans Hidden " . (!s4tEnabled || !s4tWP ? "backgroundtrans Hidden " : ""), % currentDictionary.Txt_s4tWPMinCards
    Gui, Add, Edit, % "vs4tWPMinCards cFDFDFD w40 x165 y310 h20 -E0x200 Center backgroundtrans Hidden " . (!s4tEnabled || !s4tWP ? "Center backgroundtrans Hidden" : ""), %s4tWPMinCards%
    
    AddSectionDivider(45, 335, 285, "SaveForTradeDivider_2")
    ; === S4T Discord Settings (now part of Save For Trade) ===
    SetHeaderFont()
    Gui, Add, Text, x45 y340 backgroundtrans Hidden vS4TDiscordSettingsSubHeading, % currentDictionary.S4TDiscordSettingsSubHeading
    
    SetNormalFont()
    if(StrLen(s4tDiscordUserId) < 3)
        s4tDiscordUserId =
    if(StrLen(s4tDiscordWebhookURL) < 3)
        s4tDiscordWebhookURL =
    
    Gui, Add, Text, x45 y365 backgroundtrans Hidden vTxt_S4T_DiscordID, Discord ID:
    Gui, Add, Edit, vs4tDiscordUserId w220 x45 y390 h20 -E0x200 Center backgroundtrans Hidden, %s4tDiscordUserId%
    Gui, Add, Text, x45 y415 backgroundtrans Hidden vTxt_S4T_DiscordWebhook, Webhook URL:
    Gui, Add, Edit, vs4tDiscordWebhookURL w220 x45 y440 h20 -E0x200 Center backgroundtrans Hidden, %s4tDiscordWebhookURL%
    AddCheckBox(45, 466, 28, 13, "s4tSendAccountXml", "", "Gui_checked.png", "Gui_unchecked.png", s4tSendAccountXml, "Txt_s4tSendAccountXml", currentDictionary.Txt_s4tSendAccountXml, 80, 465)
    
    ;; Discord Settings Section
    SetSectionFont()
    ; Add main heading for Discord Settings section
    Gui, Add, Text, x45 y150 backgroundtrans Hidden vDiscordSettingsHeading, % currentDictionary.DiscordSettingsHeading
    
    SetNormalFont()
    if(StrLen(discordUserID) < 3)
        discordUserID =
    if(StrLen(discordWebhookURL) < 3)
        discordWebhookURL =
    
    Gui, Add, Text, x45 y175 backgroundtrans Hidden vTxt_DiscordID, Discord ID:
    if(discordUserId = "" || discordUserId = "ERROR")
        Gui, Add, Edit, vdiscordUserId cFDFDFD w280 x45 y200 h20 -E0x200 Center backgroundtrans Hidden,
    else
        Gui, Add, Edit, vdiscordUserId cFDFDFD w280 x45 y200 h20 -E0x200 Center backgroundtrans Hidden, %discordUserId%
    
    Gui, Add, Text, x45 y225 backgroundtrans Hidden vTxt_DiscordWebhook, Webhook URL:
    if(discordWebhookURL = "" || discordWebhookURL = "ERROR")
        Gui, Add, Edit, vdiscordWebhookURL cFDFDFD w280 x45 y250 h20 -E0x200 Center backgroundtrans Hidden,
    else
        Gui, Add, Edit, vdiscordWebhookURL cFDFDFD w280 x45 y250 h20 -E0x200 Center backgroundtrans Hidden, %discordWebhookURL%
    
    AddCheckBox(45, 276, 28, 13, "sendAccountXml", "", "Gui_checked.png", "Gui_unchecked.png", sendAccountXml, "Txt_sendAccountXml", currentDictionary.Txt_sendAccountXml, 80, 275)
    
    ; Add divider after heading
    AddSectionDivider(45, 300, 285, "Discord_Divider3")
    ; === Heartbeat Settings (now part of Discord) ===
    SetHeaderFont()
    Gui, Add, Text, x45 y305 backgroundtrans Hidden vHeartbeatSettingsSubHeading, % currentDictionary.HeartbeatSettingsSubHeading
    
    SetNormalFont()
    AddCheckBox(45, 331, 28, 13, "heartBeat", "discordSettings", "Gui_checked.png", "Gui_unchecked.png", heartBeat, "Txt_heartBeat", currentDictionary.Txt_heartBeat, 80, 330)
    
    if(StrLen(heartBeatName) < 3)
        heartBeatName =
    if(StrLen(heartBeatWebhookURL) < 3)
        heartBeatWebhookURL =
    
    Gui, Add, Text, vhbName x45 y355 backgroundtrans Hidden, % currentDictionary.hbName
    Gui, Add, Edit, vheartBeatName cFDFDFD w280 x45 y380 h20 -E0x200 Center backgroundtrans Hidden, %heartBeatName%
    Gui, Add, Text, vhbURL x45 y405 backgroundtrans Hidden, Webhook URL:
    Gui, Add, Edit, vheartBeatWebhookURL cFDFDFD w280 x45 y430 h20 -E0x200 Center backgroundtrans Hidden, %heartBeatWebhookURL%
    Gui, Add, Text, vhbDelay x45 y455 backgroundtrans Hidden, % currentDictionary.hbDelay
    Gui, Add, Edit, vheartBeatDelay cFDFDFD w40 x220 y454 h20 -E0x200 Center backgroundtrans Hidden, %heartBeatDelay%
    
    ;; Download Settings Section
    SetNormalFont()
    if(StrLen(mainIdsURL) < 3)
        mainIdsURL =
    if(StrLen(vipIdsURL) < 3)
        vipIdsURL =
    
    Gui, Add, Text, x45 y150 backgroundtrans Hidden vTxt_MainIdsURL, ids.txt API:
    Gui, Add, Edit, vmainIdsURL cFDFDFD w280 x45 y175 h20 -E0x200 Center backgroundtrans Hidden, %mainIdsURL%
    
    Gui, Add, Text, x45 y200 backgroundtrans Hidden vTxt_VipIdsURL, vip_ids.txt API:
    Gui, Add, Edit, vvipIdsURL cFDFDFD w280 x45 y225 h20 -E0x200 Center backgroundtrans Hidden, %vipIdsURL%
    
    ; Add Showcase options to Download Settings Section
    AddCheckBox(45, 251, 28, 13, "showcaseEnabled", "showcaseSettings", "Gui_checked.png", "Gui_unchecked.png", showcaseEnabled, "Txt_showcaseEnabled", currentDictionary.Txt_showcaseEnabled, 80, 250)
    
    ;Gui, Add, Text, x45 y275 backgroundtrans Hidden vTxt_ShowcaseURL, Showcase.txt API:
    ;Gui, Add, Edit, vshowcaseURL w280 x45 y300 h20 -E0x200 Center backgroundtrans Hidden, %showcaseURL%
    
    HoverSystem := new ToggleImageOnHover()
    
    HoverSystem.RegisterTextControl(ArrangeHover.textHwnd, ArrangeBtn.hwnd)
    HoverSystem.RegisterTextControl(CoffeeHover.textHwnd, CoffeeBtn.hwnd)
    HoverSystem.RegisterTextControl(JoinHover.textHwnd, JoinBtn.hwnd)
    HoverSystem.RegisterTextControl(MumuHover.textHwnd, MumuBtn.hwnd)
    HoverSystem.RegisterTextControl(BalanceXMLsHover.textHwnd, BalanceXMLsBtn.hwnd)
    HoverSystem.RegisterTextControl(StartHover.textHwnd, StartBtn.hwnd)
    HoverSystem.RegisterTextControl(UpdateHover.textHwnd, UpdateBtn.hwnd)
    
    HoverSystem.RegisterTextControl(RerollSettingsHover.textHwnd, RerollSettingsBtn.hwnd)
    HoverSystem.RegisterTextControl(SystemSettingsHover.textHwnd, SystemSettingsBtn.hwnd)
    HoverSystem.RegisterTextControl(PackSettingsHover.textHwnd, PackSettingsBtn.hwnd)
    HoverSystem.RegisterTextControl(SaveForTradeHover.textHwnd, SaveForTradeBtn.hwnd)
    HoverSystem.RegisterTextControl(DiscordSettingsHover.textHwnd, DiscordSettingsBtn.hwnd)
    HoverSystem.RegisterTextControl(DownloadSettingsHover.textHwnd, DownloadSettingsBtn.hwnd)
    
    HoverSystem.CreateImagePair(ArrangeBtn.hwnd, ArrangeHover.hwnd)
    HoverSystem.CreateImagePair(CoffeeBtn.hwnd, CoffeeHover.hwnd)
    HoverSystem.CreateImagePair(JoinBtn.hwnd, JoinHover.hwnd)
    HoverSystem.CreateImagePair(MumuBtn.hwnd, MumuHover.hwnd)
    HoverSystem.CreateImagePair(BalanceXMLsBtn.hwnd, BalanceXMLsHover.hwnd)
    HoverSystem.CreateImagePair(StartBtn.hwnd, StartHover.hwnd)
    HoverSystem.CreateImagePair(UpdateBtn.hwnd, UpdateHover.hwnd)
    
    HoverSystem.CreateImagePair(RerollSettingsBtn.hwnd, RerollSettingsHover.hwnd)
    HoverSystem.CreateImagePair(SystemSettingsBtn.hwnd, SystemSettingsHover.hwnd)
    HoverSystem.CreateImagePair(PackSettingsBtn.hwnd, PackSettingsHover.hwnd)
    HoverSystem.CreateImagePair(SaveForTradeBtn.hwnd, SaveForTradeHover.hwnd)
    HoverSystem.CreateImagePair(DiscordSettingsBtn.hwnd, DiscordSettingsHover.hwnd)
    HoverSystem.CreateImagePair(DownloadSettingsBtn.hwnd, DownloadSettingsHover.hwnd)
    
    HoverSystem.CreateImagePair(previousBtn.hwnd, previousHover.hwnd)
    HoverSystem.CreateImagePair(nextBtn.hwnd, nextHover.hwnd)
    ; Initialize GUI with no section selected
    HideAllSections()
    Gui, Show, w%GUI_WIDTH% h%GUI_HEIGHT%, PTCGPB Bot Setup [Non-Commercial 4.0 International License]
    
    ; Hide all sections on startup
    CurrentVisibleSection := "MainPage"
    fadeStartflag = False
    ApplyTheme() ; Ensure everything is colored properly on startup
    HideAllSections()
    ShowInitail()
    ToggleImageOnHover.CheckIfHover()
; Update keyboard shortcuts for sections (updated to new structure)
^1::HandleKeyboardShortcut(1) ; Reroll Settings
^2::HandleKeyboardShortcut(2) ; System Settings
^3::HandleKeyboardShortcut(3) ; Pack Settings
^4::HandleKeyboardShortcut(4) ; Save For Trade
^5::HandleKeyboardShortcut(5) ; Discord Settings
^6::HandleKeyboardShortcut(6) ; Download Settings

; Function key shortcuts with the requested mapping
F1::HandleFunctionKeyShortcut(1) ; Launch All Mumu
F2::HandleFunctionKeyShortcut(2) ; Arrange Windows
F3::HandleFunctionKeyShortcut(3) ; Start Bot
F4::ShowHelpMenu() ; Help Menu
Return

; NEW: Handle drop-down changes for sort method
SortByDropdownHandler:
    Gui, Submit, NoHide
    GuiControlGet, selectedOption,, SortByDropdown
    
    ; Update injectSortMethod based on selected option
    if (selectedOption = "Oldest First")
        injectSortMethod := "ModifiedAsc"
    else if (selectedOption = "Newest First")
        injectSortMethod := "ModifiedDesc"
    else if (selectedOption = "Fewest Packs First")
        injectSortMethod := "PacksAsc"
    else if (selectedOption = "Most Packs First")
        injectSortMethod := "PacksDesc"
    
    ; Save the updated setting
    IniWrite, %injectSortMethod%, Settings.ini, UserSettings, injectSortMethod
    
    ; Save all settings to ensure consistency
    SaveAllSettings()
return

MainPage:
    Showsettingpage()
    CurrentVisibleSection := "SettingPage"
return

SettingPage:
    Showmainpage()
    CurrentVisibleSection := "MainPage"
return

GoBackPage:
    Showsettingpage()
    CurrentVisibleSection := "SettingPage"
return

Next:
    if (CurrentVisibleSection = "RerollSettings") {
        ShowSystemSettingsSection()
    } else if (CurrentVisibleSection = "SystemSettings") {
        ShowPackSettingsSection()
    } else if (CurrentVisibleSection = "PackSettings") {
        ShowSaveForTradeSection()
    } else if (CurrentVisibleSection = "SaveForTrade") {
        ShowDiscordSettingsSection()
    } else if (CurrentVisibleSection = "DiscordSettings") {
        ShowDownloadSettingsSection()
    } else if (CurrentVisibleSection = "DownloadSettings") {
        ShowRerollSettingsSection()
    }
    ToggleImageOnHover.ResetAllHoverStates()
    ToggleImageOnHover.ForceRecheck()
return

Previous:
    if (CurrentVisibleSection = "RerollSettings") {
        ShowDownloadSettingsSection()
    } else if (CurrentVisibleSection = "SystemSettings") {
        ShowRerollSettingsSection()
    } else if (CurrentVisibleSection = "PackSettings") {
        ShowSystemSettingsSection()
    } else if (CurrentVisibleSection = "SaveForTrade") {
        ShowPackSettingsSection()
    } else if (CurrentVisibleSection = "DiscordSettings") {
        ShowSaveForTradeSection()
    } else if (CurrentVisibleSection = "DownloadSettings") {
        ShowDiscordSettingsSection()
    }
    ToggleImageOnHover.ResetAllHoverStates()
    ToggleImageOnHover.ForceRecheck()
return

SwitchLanguage:
    global IsLanguageSet
    MsgBox, 4, Check Switch Language, % currentDictionary.languageNotice
    IfMsgBox, No
    {
        return ; Return to GUI for user to modify settings
    }
    IsLanguageSet := 0
    IniWrite, %IsLanguageSet%, Settings.ini, UserSettings, IsLanguageSet
    Gosub, SaveReload
return

ToggleTheme:
    ; Toggle the theme
    global isDarkTheme
    isDarkTheme := !isDarkTheme
    
    fadeStartflag := True
    fadeStart()
    Loop {
        if FileExist(finishSignalFile)
            break
        Sleep, 10
    }
    FileDelete, %finishSignalFile% ; delete signal
    
    ApplyTheme()
    
    ; Make sure current section is properly colored based on new structure
    if (CurrentVisibleSection = "RerollSettings")
        ShowRerollSettingsSection()
    else if (CurrentVisibleSection = "SystemSettings")
        ShowSystemSettingsSection()
    else if (CurrentVisibleSection = "PackSettings")
        ShowPackSettingsSection()
    else if (CurrentVisibleSection = "PackSelection")
        ShowPackSelectPage()
    else if (CurrentVisibleSection = "SaveForTrade")
        ShowSaveForTradeSection()
    else if (CurrentVisibleSection = "DiscordSettings")
        ShowDiscordSettingsSection()
    else if (CurrentVisibleSection = "DownloadSettings")
        ShowDownloadSettingsSection()
    else if (CurrentVisibleSection = "SettingPage")
        Showsettingpage()
    else if (CurrentVisibleSection = "MainPage")
        Showmainpage()
    
    ; Save the theme setting
    IniWrite, %isDarkTheme%, Settings.ini, UserSettings, isDarkTheme
    ; change image path to meet the theme
    BuildImagePath(isDarkTheme, useBackgroundImage)
    
    FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
    fadeStartflag := False
Return

ToggleBackground:
    global useBackgroundImage
    useBackgroundImage := !useBackgroundImage
    
    fadeStartflag := True
    fadeStart()
    Loop {
        if FileExist(finishSignalFile)
            break
        Sleep, 10
    }
    FileDelete, %finishSignalFile% ; delete signal
    
    SetSmallBtnText()
    
    ; Make sure current section is properly colored based on new structure
    if (CurrentVisibleSection = "RerollSettings")
        ShowRerollSettingsSection()
    else if (CurrentVisibleSection = "SystemSettings")
        ShowSystemSettingsSection()
    else if (CurrentVisibleSection = "PackSettings")
        ShowPackSettingsSection()
    else if (CurrentVisibleSection = "PackSelection")
        ShowPackSelectPage()
    else if (CurrentVisibleSection = "SaveForTrade")
        ShowSaveForTradeSection()
    else if (CurrentVisibleSection = "DiscordSettings")
        ShowDiscordSettingsSection()
    else if (CurrentVisibleSection = "DownloadSettings")
        ShowDownloadSettingsSection()
    else if (CurrentVisibleSection = "SettingPage")
        Showsettingpage()
    else if (CurrentVisibleSection = "MainPage")
        Showmainpage()
    BuildImagePath(isDarkTheme, useBackgroundImage)
    
    FileAppend,, %A_ScriptDir%\Scripts\Include\go.signal
    fadeStartflag := False
Return

ToggleSection:
    ; Get clicked button name
    ClickedButton := A_GuiControl
    
    ; Extract just the section name without the "Btn_" prefix
    StringTrimLeft, SectionName, ClickedButton, 6
    
    ; Show section based on new structure
    if (SectionName = "RerollSettings") {
        ShowRerollSettingsSection()
    } else if (SectionName = "SystemSettings") {
        ShowSystemSettingsSection()
    } else if (SectionName = "PackSettings") {
        ShowPackSettingsSection()
    } else if (SectionName = "SaveForTrade") {
        ShowSaveForTradeSection()
    } else if (SectionName = "DiscordSettings") {
        ShowDiscordSettingsSection()
    } else if (SectionName = "DownloadSettings") {
        ShowDownloadSettingsSection()
    }
    ; Enable previous & next btn when in setting
    picList := "Btn_previous,Btn_next"
    hovList := "Hover_previous,Hover_next"
    EnableImageButtonToMultiple(picList, hovList)
    
    ; Update current section and tab highlighting
    CurrentVisibleSection := SectionName
    ; Update section headers with appropriate colors
    UpdateSectionHeaders()
    ToggleImageOnHover.ResetAllHoverStates()
    ToggleImageOnHover.ForceRecheck()
Return

GoPackSelect:
    DisableAllImageButton()
    ; Show Pack Select Page
    ShowPackSelectPage()
return

PackCheck:
    ; Get clicked button name
    ClickedButton := A_GuiControl
    
    ; Extract just the section name without the "Page_" prefix
    StringTrimLeft, CheckBoxName, ClickedButton, 5
    
    ToggleCheckbox(CheckBoxName)
    
    GuiControl,, %ClickedButton%, % newValue ? "Gui_checked.png" : "Gui_unchecked.png"
return

ReturnPackSettingsSection:
    pictureList := "Btn_previous,Btn_next"
    hoverList := "Hover_previous,Hover_next"
    EnableImageButtonToMultiple(pictureList, hoverList)
    ShowPackSettingsSection()
return

CheckForUpdates:
    CheckForUpdate()
return

; ========== For prototype check box ===========
; gLabel not required for this checkbox
CheckBoxToggle:
    varName := A_GuiControl
    ToggleCheckbox(varName)
    if (varName = "Buzzwole" || varName = "Solgaleo" || varName = "Lunala" || varName = "Shining") {
        PageVarName := "Page_" . varName
        newValue := %varName%
        GuiControl,, %PageVarName%, % newValue ? "Gui_checked.png" : "Gui_unchecked.png"
    }
return

mainSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    
    runMain := !runMain
    ifEqual, runMain, 1, GuiControl,, runMain, Gui_checked.png
    else GuiControl,, runMain, Gui_unchecked.png
        
        IniWrite, %runMain%, Settings.ini, UserSettings, runMain
    
    if (runMain) {
        GuiControl, Show, Mains
        
        ; Apply theme-specific styling
        if (isDarkTheme) {
            GuiControl, +Background%DARK_INPUT_BG% +c%DARK_INPUT_TEXT%, Mains
        } else {
            GuiControl, +Background%LIGHT_INPUT_BG% +c%LIGHT_INPUT_TEXT%, Mains
        }
    }
    else {
        GuiControl, Hide, Mains
    }
return

discordSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    
    heartBeat := !heartBeat
    ifEqual, heartBeat, 1, GuiControl,, heartBeat, Gui_checked.png
    else GuiControl,, heartBeat, Gui_unchecked.png
        
        IniWrite, %heartBeat%, Settings.ini, UserSettings, heartBeat
    
    if (heartBeat) {
        heartbeatControls := "heartBeatName,heartBeatWebhookURL,heartBeatDelay,hbName,hbURL,hbDelay"
        ShowControls(heartbeatControls)
        
        ; Apply theme-specific styling using helper functions
        textControls := "hbName,hbURL,hbDelay"
        ApplyTextColorToMultiple(textControls)
        
        inputControls := "heartBeatName,heartBeatWebhookURL,heartBeatDelay"
        ApplyInputStyleToMultiple(inputControls)
    }
    else {
        heartbeatControls := "heartBeatName,heartBeatWebhookURL,heartBeatDelay,hbName,hbURL,hbDelay"
        HideControls(heartbeatControls)
    }
return

s4tSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    global SaveForTradeDivider_1, SaveForTradeDivider_2
    s4tEnabled := !s4tEnabled
    ifEqual, s4tEnabled, 1, GuiControl,, s4tEnabled, Gui_checked.png
    else GuiControl,, s4tEnabled, Gui_unchecked.png
        
    IniWrite, %s4tEnabled%, Settings.ini, UserSettings, s4tEnabled
    
    if (s4tEnabled) {
        ; Show main S4T controls
        s4tMainControls := "s4tSilent,s4t3Dmnd,s4t4Dmnd,s4t1Star,Txt_S4TSeparator,s4tWP,"
        s4tMainControls .= "Txt_s4tEnabled,Txt_s4tSilent,Txt_s4t3Dmnd,Txt_s4t4Dmnd,Txt_s4t1Star,Txt_s4tWP,Txt_s4tSendAccountXml,"
        s4tMainControls .= "S4TDiscordSettingsSubHeading,Txt_S4T_DiscordID,s4tDiscordUserId,"
        s4tMainControls .= "Txt_S4T_DiscordWebhook,s4tDiscordWebhookURL,s4tSendAccountXml,"
        s4tMainControls .= "SaveForTradeDivider_1,SaveForTradeDivider_2"
        ShowControls(s4tMainControls)
        
        ; Apply theme styling using helper functions
        textControls := "Txt_s4tEnabled,Txt_s4tSilent,Txt_s4t3Dmnd,Txt_s4t4Dmnd,Txt_s4t1Star,s4tGholdengoArrow,Txt_s4tWP,Txt_S4T_DiscordID,"
        textControls .= "Txt_S4T_DiscordWebhook,Txt_s4tSendAccountXml"
        ApplyTextColorToMultiple(textControls)
        
        inputControls := "s4tDiscordUserId,s4tDiscordWebhookURL"
        ApplyInputStyleToMultiple(inputControls)
        
        ; Apply section color to sub-heading
        sectionColor := isDarkTheme ? DARK_SECTION_COLORS["SaveForTrade"] : LIGHT_SECTION_COLORS["SaveForTrade"]
        GuiControl, +c%sectionColor%, S4TDiscordSettingsSubHeading
        
        ; Check if Shining is enabled to show Gholdengo - Important logic from PTCGPB.ahk
        IniRead, Shining, Settings.ini, UserSettings, Shining, 0
        if (Shining) {
            GuiControl, Show, s4tGholdengo
            GuiControl, Show, s4tGholdengoEmblem
            GuiControl, Show, s4tGholdengoArrow
            
            ; Apply text styling
            if (isDarkTheme) {
                GuiControl, +c%DARK_TEXT%, s4tGholdengo
                GuiControl, +c%DARK_TEXT%, s4tGholdengoArrow
            } else {
                GuiControl, +c%LIGHT_TEXT%, s4tGholdengo
                GuiControl, +c%LIGHT_TEXT%, s4tGholdengoArrow
            }
        } else {
            GuiControl, Hide, s4tGholdengo
            GuiControl, Hide, s4tGholdengoEmblem
            GuiControl, Hide, s4tGholdengoArrow
        }
        
        ; Check if s4tWP is enabled
        if (s4tWP) {
            GuiControl, Show, s4tWPMinCardsLabel
            GuiControl, Show, s4tWPMinCards
            
            ; Apply styling
            ApplyTextColor("s4tWPMinCardsLabel")
            ApplyInputStyle("s4tWPMinCards")
        } else {
            GuiControl, Hide, s4tWPMinCardsLabel
            GuiControl, Hide, s4tWPMinCards
        }
    } else {
        ; Hide all S4T controls
        s4tAllControls := "s4tSilent,s4t3Dmnd,s4t4Dmnd,s4t1Star,s4tGholdengo,s4tGholdengoEmblem,"
        s4tAllControls .= "Txt_s4tSilent,Txt_s4t3Dmnd,Txt_s4t4Dmnd,Txt_s4t1Star,Txt_s4tWP,Txt_s4tSendAccountXml,"
        s4tAllControls .= "s4tGholdengoArrow,Txt_S4TSeparator,s4tWP,s4tWPMinCardsLabel,s4tWPMinCards,"
        s4tAllControls .= "S4TDiscordSettingsSubHeading,Txt_S4T_DiscordID,s4tDiscordUserId,"
        s4tAllControls .= "Txt_S4T_DiscordWebhook,s4tDiscordWebhookURL,s4tSendAccountXml,"
        s4tAllControls .= "SaveForTradeDivider_1,SaveForTradeDivider_2"
        HideControls(s4tAllControls)
    }
return

s4tWPSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    
    s4tWP := !s4tWP
    ifEqual, s4tWP, 1, GuiControl,, s4tWP, Gui_checked.png
    else GuiControl,, s4tWP, Gui_unchecked.png
        
        IniWrite, %s4tWP%, settings.ini, UserSettings, s4tWP
    
    if (s4tWP) {
        GuiControl, Show, s4tWPMinCardsLabel
        GuiControl, Show, s4tWPMinCards
        
        ; Apply styling using helper functions
        ApplyTextColor("s4tWPMinCardsLabel")
        ApplyInputStyle("s4tWPMinCards")
    } else {
        GuiControl, Hide, s4tWPMinCardsLabel
        GuiControl, Hide, s4tWPMinCards
    }
return

TesseractOptionSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    
    tesseractOption := !tesseractOption
    ifEqual, tesseractOption, 1, GuiControl,, tesseractOption, Gui_checked.png
    else GuiControl,, tesseractOption, Gui_unchecked.png
        
        IniWrite, %tesseractOption%, settings.ini, UserSettings, tesseractOption
    
    if (tesseractOption) {
        GuiControl, Show, Txt_TesseractPath
        GuiControl, Show, tesseractPath
        
        ; Apply styling using helper functions
        ApplyTextColor("Txt_TesseractPath")
        ApplyInputStyle("tesseractPath")
    } else {
        GuiControl, Hide, Txt_TesseractPath
        GuiControl, Hide, tesseractPath
    }
return

deleteSettings:
    Gui, Submit, NoHide
    global scaleParam, defaultLanguage, sortByCreated
    
    ; Store the current scaleParam value
    currentScaleParam := scaleParam
    
    ; Get the current value of deleteMethod control
    GuiControlGet, currentMethod,, deleteMethod
    
    deleteMethod := currentMethod
    ; Immediately save to prevent loss
    IniWrite, %deleteMethod%, Settings.ini, UserSettings, deleteMethod
    
    claimSpecialMissions := 0
    IniWrite, %claimSpecialMissions%, settings.ini, UserSettings, claimSpecialMissions
    if(InStr(currentMethod, "Inject")) {
        ; Hide nukeAccount checkbox
        GuiControl, Hide, nukeAccount
        GuiControl, Hide, Txt_nukeAccount
        nukeAccount := 0
        IniWrite, %nukeAccount%, settings.ini, UserSettings, nukeAccount
        
        ifEqual, spendHourGlass, 1, GuiControl,, spendHourGlass, Gui_checked.png
        else GuiControl,, spendHourGlass, Gui_unchecked.png
            GuiControl, Show, spendHourGlass
        GuiControl, Show, Txt_spendHourGlass
        ApplyTextColor("Txt_spendHourGlass")
        
        ; Show existing controls
        GuiControl, Show, SortByText
        GuiControl, Show, SortByDropdown
        ApplyTextColor("SortByText")
    }
    else {
        ifEqual, nukeAccount, 1, GuiControl,, nukeAccount, Gui_checked.png
        else GuiControl,, nukeAccount, Gui_unchecked.png
            GuiControl, Show, nukeAccount
        GuiControl, Show, Txt_nukeAccount
        ApplyTextColor("Txt_nukeAccount")
        
        GuiControl, Hide, spendHourGlass
        GuiControl, Hide, Txt_spendHourGlass
        spendHourGlass := 0
        IniWrite, %spendHourGlass%, Settings.ini, UserSettings, spendHourGlass
        
        ; Hide Sort By controls if they exist
        GuiControl, Hide, SortByText
        GuiControl, Hide, SortByDropdown
    }
    
    ; Ensure scaleParam value is preserved based on the currentLanguage
    if (defaultLanguage = "Scale125") {
        scaleParam := 277
    } else if (defaultLanguage = "Scale100") {
        scaleParam := 287
    }
    
    ; Only show a message if debugging is needed
    if (debugMode && scaleParam != currentScaleParam) {
        MsgBox, Scale parameter updated: %scaleParam% (Was: %currentScaleParam%)
    }
    
    ; Save settings after changing delete method
    SaveAllSettings()
return

; Add a new function for showcase settings toggle
showcaseSettings:
    Gui, Submit, NoHide
    global isDarkTheme, DARK_TEXT, LIGHT_TEXT, DARK_INPUT_BG, DARK_INPUT_TEXT, LIGHT_INPUT_BG, LIGHT_INPUT_TEXT
    
    showcaseEnabled := !showcaseEnabled
    ifEqual, showcaseEnabled, 1, GuiControl,, showcaseEnabled, Gui_checked.png
    else GuiControl,, showcaseEnabled, Gui_unchecked.png
        
        IniWrite, %showcaseEnabled%, settings.ini, UserSettings, showcaseEnabled
    
    /*
    if (showcaseEnabled) {
        GuiControl, Show, Txt_ShowcaseURL
        GuiControl, Show, showcaseURL
        
        ; Apply styling using helper functions
        ApplyTextColor("Txt_ShowcaseURL")
        ApplyInputStyle("showcaseURL")
    } else {
        GuiControl, Hide, Txt_ShowcaseURL
        GuiControl, Hide, showcaseURL
    }
    */
return

defaultLangSetting:
    global scaleParam
    GuiControlGet, defaultLanguage,, defaultLanguage
    if (defaultLanguage = "Scale125") {
        scaleParam := 277
        MsgBox, Scale set to 125`% with scaleParam = %scaleParam%
    } else if (defaultLanguage = "Scale100") {
        scaleParam := 287
        MsgBox, Scale set to 100`% with scaleParam = %scaleParam%
    }
    
    ; Save settings after changing language
    SaveAllSettings()
return

ArrangeWindows:
    GuiControlGet, Mains,, Mains
    GuiControlGet, Instances,, Instances
    GuiControlGet, Columns,, Columns
    GuiControlGet, SelectedMonitorIndex,, SelectedMonitorIndex
    GuiControlGet, defaultLanguage,, defaultLanguage
    GuiControlGet, rowGap,, rowGap
    IniRead, runMain, Settings.ini, UserSettings, runMain
    
    ; Re-validate scaleParam based on current language
    if (defaultLanguage = "Scale125") {
        scaleParam := 277
    } else if (defaultLanguage = "Scale100") {
        scaleParam := 287
    }
    
    windowsPositioned := 0
    
    if (runMain && Mains > 0) {
        Loop %Mains% {
            mainInstanceName := "Main" . (A_Index > 1 ? A_Index : "")
            if (WinExist(mainInstanceName)) {
                WinActivate, %mainInstanceName%
                WinGetPos, curX, curY, curW, curH, %mainInstanceName%
                
                ; Calculate position
                SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
                SysGet, Monitor, Monitor, %SelectedMonitorIndex%
                
                instanceIndex := A_Index
                rowHeight := 533
                currentRow := Floor((instanceIndex - 1) / Columns)
                y := MonitorTop + (currentRow * rowHeight) + (currentRow * rowGap)
                x := MonitorLeft + (Mod((instanceIndex - 1), Columns) * scaleParam)
                
                ; Move window
                WinMove, %mainInstanceName%,, %x%, %y%, %scaleParam%, 537
                WinSet, Redraw, , %mainInstanceName%
                
                windowsPositioned++
                sleep, 100
            }
        }
    }
    
    if (Instances > 0) {
        Loop %Instances% {
            if (WinExist(A_Index)) {
                WinActivate, %A_Index%
                WinGetPos, curX, curY, curW, curH, %A_Index%
                
                ; Calculate position
                SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
                SysGet, Monitor, Monitor, %SelectedMonitorIndex%
                
                if (runMain) {
                    instanceIndex := (Mains - 1) + A_Index + 1
                } else {
                    instanceIndex := A_Index
                }
                
                rowHeight := 533
                currentRow := Floor((instanceIndex - 1) / Columns)
                y := MonitorTop + (currentRow * rowHeight) + (currentRow * rowGap)
                x := MonitorLeft + (Mod((instanceIndex - 1), Columns) * scaleParam)
                
                ; Move window
                WinMove, %A_Index%,, %x%, %y%, %scaleParam%, 537
                WinSet, Redraw, , %A_Index%
                
                windowsPositioned++
                sleep, 100
            }
        }
    }
    
    if (debugMode && windowsPositioned == 0) {
        MsgBox, No windows found to arrange
    } else {
        MsgBox, Arranged %windowsPositioned% windows
    }
    
    ; Save settings after arranging windows
    SaveAllSettings()
return

moveScreen:
    TargetWindowTitle := "PTCGPB Bot Setup [Non-Commercial 4.0 International License]"
    
    WinGetPos, x, y, w, h, % TargetWindowTitle
    
    Loop, 10 {
        t := 250 - A_Index * 25
        WinSet, Transparent, %t%, % TargetWindowTitle
        Sleep, 5
    }
    
    WinMove, % TargetWindowTitle, , 1250, y
    
    Loop, 50 {
        t := 5 + A_Index * 5
        WinSet, Transparent, %t%, % TargetWindowTitle
        Sleep, 4
    }
return

LaunchAllMumu:
    SetTimer, moveScreen, -1
    GuiControlGet, Instances,, Instances
    GuiControlGet, folderPath,, folderPath
    GuiControlGet, Mains,, Mains
    GuiControlGet, instanceLaunchDelay,, instanceLaunchDelay
    IniRead, runMain, Settings.ini, UserSettings, runMain
    
    ; Save settings before launching
    SaveAllSettings()
    
    if(StrLen(A_ScriptDir) > 200 || InStr(A_ScriptDir, " ")) {
        MsgBox, the path to the bot folder is too long or contain white spaces. move it to a shorter path without spaces
        return
    }
    
    launchAllFile := "LaunchAllMumu.ahk"
    if(FileExist(launchAllFile)) {
        Run, %launchAllFile%
    }
return

; ToolTip
OpenToolTip:
    Tool := "GUI ToolTip.html"
    Run, %Tool%
return

; Handle the link click
OpenLink:
    Run, https://buymeacoffee.com/aarturoo
return

OpenDiscord:
    Run, https://discord.gg/C9Nyf7P4sT
return

; IMPROVED: Ensure settings are saved completely before reload
SaveReload:
    ; Get the most current values from all controls
    Gui, Submit
    ; Save all settings using our comprehensive function
    SaveAllSettings()
    ; Reload the script
    Reload
return

BalanceXMLs:
    if(Instances>0) {
        ; Save all settings first to ensure Instances is up to date
        SaveAllSettings()
        
        ;get current # of instances in box
        GuiControlGet, Instances,, Instances
        
        ;todo better status message location or method
        GuiControlGet, ButtonPos, Pos, BalanceXMLs
        XTooltipPos = % ButtonPosX + 10
        YTooltipPos = % ButtonPosY + 140
        
        ;check folders
        saveDir := A_ScriptDir "\Accounts\Saved\"
        if !FileExist(saveDir) ; Check if the directory exists
            FileCreateDir, %saveDir% ; Create the directory if it doesn't exist
        
        tmpDir := A_ScriptDir "\Accounts\Saved\tmp"
        if !FileExist(tmpDir) ; Check if the directory exists
            FileCreateDir, %tmpDir% ; Create the directory if it doesn't exist
        
        ;lags gui for some reason
        Tooltip, Moving Files and Folders to tmp, XTooltipPos, YTooltipPos
        Loop, Files, %saveDir%*, D
        {
            if (A_LoopFilePath == tmpDir)
                continue
            dest := tmpDir . "\" . A_LoopFileName
            
            FileMoveDir, %A_LoopFilePath%, %dest%, 1
        }
        Loop, Files, %saveDir%\*, F
        {
            dest := tmpDir . "\" . A_LoopFileName
            FileMove, %A_LoopFilePath%, %dest%, 1
        }
        
        ; create instance dirs
        Loop , %Instances%
        {
            instanceDir := saveDir . "\" . A_Index
            if !FileExist(instanceDir) ; Check if the directory exists
                FileCreateDir, %instanceDir% ; Create the directory if it doesn't exist
            listfile := instanceDir . "\list.txt"
            if FileExist(listfile)
                FileDelete, %listfile% ; delete list if it exists
        }
        
        ToolTip, Checking for Duplicate names, XTooltipPos, YTooltipPos
        fileList := ""
        seenFiles := {}
        Loop, Files, %tmpDir%\*.xml, R
        {
            fileName := A_LoopFileName
            fileTime := A_LoopFileTimeModified
            ; TODO can also sort by name (num packs), or time created
            fileTime := A_LoopFileTimeCreated
            filePath := A_LoopFileFullPath
            
            if seenFiles.HasKey(fileName)
            {
                ; Compare the timestamps to determine which file is older
                prevTime := seenFiles[fileName].Time
                prevPath := seenFiles[fileName].Path
                
                if (fileTime > prevTime)
                {
                    ; Current file is newer, delete the previous one
                    FileDelete, %prevPath%
                    seenFiles[fileName] := {Time: fileTime, Path: filePath}
                }
                else
                {
                    ; Current file is older, delete it
                    FileDelete, %filePath%
                }
                continue
            }
            
            ; Store the file info
            seenFiles[fileName] := {Time: fileTime, Path: filePath}
            fileList .= fileTime "`t" filePath "`n"
        }
        
        ToolTip, Sorting by modified date, XTooltipPos, YTooltipPos
        Sort, fileList, R
        
        ToolTip, Distributing XMLs between folders...please wait, XTooltipPos, YTooltipPos
        instance := 1
        Loop, Parse, fileList, `n
        {
            if (A_LoopField = "")
                continue
            
            ; Split each line into timestamp and file path (split by tab)
            StringSplit, parts, A_LoopField, %A_Tab%
            tmpFile := parts2 ; Get the file path from the second part
            toDir := saveDir . "\" . instance
            
            ; Move the file
            FileMove, %tmpFile%, %toDir%, 1
            
            instance++
            if (instance > Instances)
                instance := 1
        }
        
        ;count number of xmls with date modified time over 24 hours in instance 1
        instanceOneDir := saveDir . "1"
        counter := 0
        counter2 := 0
        Loop, Files, %instanceOneDir%\*.xml
        {
            fileModifiedTimeDiff := A_Now
            FileGetTime, fileModifiedTime, %A_LoopFileFullPath%, M
            EnvSub, fileModifiedTimeDiff, %fileModifiedTime%, Hours
            if (fileModifiedTimeDiff >= 24) ; 24 hours
                counter++
        }
        
        Tooltip ;clear tooltip
        MsgBox, Done balancing XMLs between %Instances% instances`n%counter% XMLs past 24 hours per instance
    }
return

; Function to reset all account lists (automatically called on startup)
ResetAccountLists() {
    ; Run the ResetLists.ahk script without waiting
    Run, %A_ScriptDir%\ResetLists.ahk,, Hide UseErrorLevel
    
    ; Very short delay to ensure process starts
    Sleep, 50
    
    ; Log that we've delegated to the script
    LogToFile("Account lists reset via ResetLists.ahk. New lists will be generated on next injection.")
    
    ; Create a status message
    CreateStatusMessage("Account lists reset. New lists will use current method settings.",,,, false)
}

StartBot:
    ; === FAST PRE-CONFIRMATION CHECKS ===
    ; Only do lightweight operations before showing popup
    Gui, Submit, NoHide
    
    ; Quick path validation (no file I/O)
    if(StrLen(A_ScriptDir) > 200 || InStr(A_ScriptDir, " ")) {
        MsgBox, % SetUpDictionary.Error_BotPathTooLong
        return
    }
    
    ; Build confirmation message with current GUI values
    confirmMsg := SetUpDictionary.Confirm_SelectedMethod . deleteMethod . "`n"
    
    ; Add method-specific details
    if (deleteMethod = "Inject Range" && injectRange != "") {
        confirmMsg .= SetUpDictionary.Confirm_RangeValue . injectRange . "`n"
    }
    else if (deleteMethod = "Inject" || deleteMethod = "Inject Missions") {
        confirmMsg .= SetUpDictionary.Confirm_MaxPackCount . injectMaxValue . "`n"
    }
    else if (deleteMethod = "Inject for Reroll") {
        confirmMsg .= SetUpDictionary.Confirm_MinPackCount . injectMinValue . "`n"
    }
    
    confirmMsg .= "`n" . SetUpDictionary.Confirm_SelectedPacks . "`n"
    if (Buzzwole)
        confirmMsg .= "• " . currentDictionary.Txt_Buzzwole . "`n"
    if (Solgaleo)
        confirmMsg .= "• " . currentDictionary.Txt_Solgaleo . "`n"
    if (Lunala)
        confirmMsg .= "• " . currentDictionary.Txt_Lunala . "`n"
    if (Shining)
        confirmMsg .= "• " . currentDictionary.Txt_Shining . "`n"
    if (Arceus)
        confirmMsg .= "• " . currentDictionary.Txt_Arceus . "`n"
    if (Palkia)
        confirmMsg .= "• " . currentDictionary.Txt_Palkia . "`n"
    if (Dialga)
        confirmMsg .= "• " . currentDictionary.Txt_Dialga . "`n"
    if (Pikachu)
        confirmMsg .= "• " . currentDictionary.Txt_Pikachu . "`n"
    if (Charizard)
        confirmMsg .= "• " . currentDictionary.Txt_Charizard . "`n"
    if (Mewtwo)
        confirmMsg .= "• " . currentDictionary.Txt_Mewtwo . "`n"
    if (Mew)
        confirmMsg .= "• " . currentDictionary.Txt_Mew . "`n"
    
    confirmMsg .= "`n" . SetUpDictionary.Confirm_AdditionalSettings
    additionalSettingsFound := false
    
    if (packMethod) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_1PackMethod
        additionalSettingsFound := true
    }
    if (nukeAccount && !InStr(deleteMethod, "Inject")) {
        confirmMsg .= "`n•" . SetUpDictionary.Confirm_MenuDelete
        additionalSettingsFound := true
    }
    if (spendHourGlass) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_SpendHourGlass
        additionalSettingsFound := true
    }
    if (claimSpecialMissions && InStr(deleteMethod, "Inject")) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_ClaimMissions
        additionalSettingsFound := true
    }
    if (InStr(deleteMethod, "Inject") && sortByCreated) {
        GuiControlGet, selectedSortOption,, SortByDropdown
        confirmMsg .= "`n" . SetUpDictionary.Confirm_SortBy . selectedSortOption
        additionalSettingsFound := true
    }
    if (!additionalSettingsFound)
        confirmMsg .= "`n" . SetUpDictionary.Confirm_None
    
    confirmMsg .= "`n`n" . SetUpDictionary.Confirm_CardDetection
    cardDetectionFound := false
    
    if (FullArtCheck) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_SingleFullArt
        cardDetectionFound := true
    }
    if (TrainerCheck) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_SingleTrainer
        cardDetectionFound := true
    }
    if (RainbowCheck) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_SingleRainbow
        cardDetectionFound := true
    }
    if (PseudoGodPack) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_Double2Star
        cardDetectionFound := true
    }
    if (CrownCheck) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_SaveCrowns
        cardDetectionFound := true
    }
    if (ShinyCheck) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_SaveShiny
        cardDetectionFound := true
    }
    if (ImmersiveCheck) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_SaveImmersives
        cardDetectionFound := true
    }
    if (CheckShinyPackOnly) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_OnlyShinyPacks
        cardDetectionFound := true
    }
    if (InvalidCheck) {
        confirmMsg .= "`n" . SetUpDictionary.Confirm_IgnoreInvalid
        cardDetectionFound := true
    }
    
    if (!cardDetectionFound)
        confirmMsg .= "`n" . SetUpDictionary.Confirm_None
    
    confirmMsg .= "`n`n" . SetUpDictionary.Confirm_RowGap . rowGap . " pixels"
    confirmMsg .= "`n`n" . SetUpDictionary.Confirm_StartBot
    
    ; === SHOW CONFIRMATION DIALOG IMMEDIATELY ===
    MsgBox, 4, Confirm Bot Settings, %confirmMsg%
    IfMsgBox, No
    {
        return ; Return to GUI for user to modify settings
    }
    
    ; === HEAVY OPERATIONS AFTER USER CONFIRMATION ===
    
    ; Reset account lists (this was causing the delay)
    ResetAccountLists()
    
    ; Update dropdown settings if needed
    if (InStr(deleteMethod, "Inject") && sortByCreated) {
        GuiControlGet, selectedSortOption,, SortByDropdown
        if (selectedSortOption = "Oldest First")
            injectSortMethod := "ModifiedAsc"
        else if (selectedSortOption = "Newest First")
            injectSortMethod := "ModifiedDesc"
        else if (selectedSortOption = "Fewest Packs First")
            injectSortMethod := "PacksAsc"
        else if (selectedSortOption = "Most Packs First")
            injectSortMethod := "PacksDesc"
    }
    
    ; Save all settings
    SaveAllSettings()
    
    ; Re-validate scaleParam based on current language
    if (defaultLanguage = "Scale125") {
        scaleParam := 277
    } else if (defaultLanguage = "Scale100") {
        scaleParam := 287
    }
    
    ; Handle deprecated FriendID field
    if (inStr(FriendID, "http")) {
        MsgBox, To provide a URL for friend IDs, please use the ids.txt API field and leave the Friend ID field empty.
        
        if (mainIdsURL = "") {
            IniWrite, "", Settings.ini, UserSettings, FriendID
            IniWrite, %FriendID%, Settings.ini, UserSettings, mainIdsURL
        }
        
        Reload
    }
    
    ; Download a new Main ID file prior to running the rest of the below
    if (mainIdsURL != "") {
        DownloadFile(mainIdsURL, "ids.txt")
    }
    
    ; Download showcase codes if enabled
    if (showcaseEnabled && showcaseURL != "") {
        DownloadFile(showcaseURL, "showcase_codes.txt")
    }
    
    ; Check for showcase_ids.txt if enabled
    if (showcaseEnabled) {
        if (!FileExist("showcase_ids.txt")) {
            MsgBox, 48, Showcase Warning, Showcase is enabled but showcase_ids.txt does not exist.`nPlease create this file in the same directory as the script.
        }
    }
    
    ; Create the second page dynamically based on the number of instances
    Gui, Destroy ; Close the first page
    
    ; Run main before instances to account for instance start delay
    if (runMain) {
        Loop, %Mains%
        {
            if (A_Index != 1) {
                SourceFile := "Scripts\Main.ahk" ; Path to the source .ahk file
                TargetFolder := "Scripts\" ; Path to the target folder
                TargetFile := TargetFolder . "Main" . A_Index . ".ahk" ; Generate target file path
                FileDelete, %TargetFile%
                FileCopy, %SourceFile%, %TargetFile%, 1 ; Copy source file to target
                if (ErrorLevel)
                    MsgBox, Failed to create %TargetFile%. Ensure permissions and paths are correct.
            }
            
            mainInstanceName := "Main" . (A_Index > 1 ? A_Index : "")
            FileName := "Scripts\" . mainInstanceName . ".ahk"
            Command := FileName
            
            if (A_Index > 1 && instanceStartDelay > 0) {
                instanceStartDelayMS := instanceStartDelay * 1000
                Sleep, instanceStartDelayMS
            }
            
            Run, %Command%
        }
    }
    
    ; Loop to process each instance
    Loop, %Instances%
    {
        if (A_Index != 1) {
            SourceFile := "Scripts\1.ahk" ; Path to the source .ahk file
            TargetFolder := "Scripts\" ; Path to the target folder
            TargetFile := TargetFolder . A_Index . ".ahk" ; Generate target file path
            if(Instances > 1) {
                FileDelete, %TargetFile%
                FileCopy, %SourceFile%, %TargetFile%, 1 ; Copy source file to target
            }
            if (ErrorLevel)
                MsgBox, Failed to create %TargetFile%. Ensure permissions and paths are correct.
        }
        
        FileName := "Scripts\" . A_Index . ".ahk"
        Command := FileName
        
        if ((Mains > 1 || A_Index > 1) && instanceStartDelay > 0) {
            instanceStartDelayMS := instanceStartDelay * 1000
            Sleep, instanceStartDelayMS
        }
        
        ; Clear out the last run time so that our monitor script doesn't try to kill and refresh this instance right away
        metricFile := A_ScriptDir . "\Scripts\" . A_Index . ".ini"
        if (FileExist(metricFile)) {
            IniWrite, 0, %metricFile%, Metrics, LastEndEpoch
            IniWrite, 0, %metricFile%, UserSettings, DeadCheck
            IniWrite, 0, %metricFile%, Metrics, rerolls
            now := A_TickCount
            IniWrite, %now%, %metricFile%, Metrics, rerollStartTime
        }
        
        Run, %Command%
    }
    
    if(autoLaunchMonitor) {
        monitorFile := "Monitor.ahk"
        if(FileExist(monitorFile)) {
            Run, %monitorFile%
        }
    }
    
    ; Update ScaleParam for use in displaying the status
    SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
    SysGet, Monitor, Monitor, %SelectedMonitorIndex%
    rerollTime := A_TickCount
    
    typeMsg := "\nType: " . deleteMethod
    injectMethod := false
    if(InStr(deleteMethod, "Inject"))
        injectMethod := true
    if(packMethod)
        typeMsg .= " (1P Method)"
    if(nukeAccount && !injectMethod)
        typeMsg .= " (Menu Delete)"
    
    Selected := []
    selectMsg := "\nOpening: "
    if(Shining)
        Selected.Push("Shining")
    if(Arceus)
        Selected.Push("Arceus")
    if(Palkia)
        Selected.Push("Palkia")
    if(Dialga)
        Selected.Push("Dialga")
    if(Mew)
        Selected.Push("Mew")
    if(Pikachu)
        Selected.Push("Pikachu")
    if(Charizard)
        Selected.Push("Charizard")
    if(Mewtwo)
        Selected.Push("Mewtwo")
    if(Solgaleo)
        Selected.Push("Solgaleo")
    if(Lunala)
        Selected.Push("Lunala")
    if(Buzzwole)
        Selected.Push("Buzzwole")
    
    for index, value in Selected {
        if(index = Selected.MaxIndex())
            commaSeparate := ","
        else
            commaSeparate := ", "
        if(value)
            selectMsg .= value . commaSeparate
        else
            selectMsg .= value . commaSeparate
    }
    
    ; === MAIN HEARTBEAT LOOP ===
    Loop {
        Sleep, 30000
        
        ; Check if Main toggled GP Test Mode and send notification if needed
        IniRead, mainTestMode, HeartBeat.ini, TestMode, Main, -1
        if (mainTestMode != -1) {
            ; Main has toggled test mode, get status and send notification
            IniRead, mainStatus, HeartBeat.ini, HeartBeat, Main, 0
            
            onlineAHK := ""
            offlineAHK := ""
            Online := []
            
            Loop %Instances% {
                IniRead, value, HeartBeat.ini, HeartBeat, Instance%A_Index%
                if(value)
                    Online.Push(1)
                else
                    Online.Push(0)
                IniWrite, 0, HeartBeat.ini, HeartBeat, Instance%A_Index%
            }
            
            for index, value in Online {
                if(index = Online.MaxIndex())
                    commaSeparate := ""
                else
                    commaSeparate := ", "
                if(value)
                    onlineAHK .= A_Index . commaSeparate
                else
                    offlineAHK .= A_Index . commaSeparate
            }
            
            if (runMain) {
                if(mainStatus) {
                    if (onlineAHK)
                        onlineAHK := "Main, " . onlineAHK
                    else
                        onlineAHK := "Main"
                }
                else {
                    if (offlineAHK)
                        offlineAHK := "Main, " . offlineAHK
                    else
                        offlineAHK := "Main"
                }
            }
            
            if(offlineAHK = "")
                offlineAHK := "Offline: none"
            else
                offlineAHK := "Offline: " . RTrim(offlineAHK, ", ")
            if(onlineAHK = "")
                onlineAHK := "Online: none"
            else
                onlineAHK := "Online: " . RTrim(onlineAHK, ", ")
            
            ; Create status message with all regular heartbeat info
            discMessage := heartBeatName ? "\n" . heartBeatName : ""
            discMessage .= "\n" . onlineAHK . "\n" . offlineAHK
            
            total := SumVariablesInJsonFile()
            totalSeconds := Round((A_TickCount - rerollTime) / 1000)
            mminutes := Floor(totalSeconds / 60)
            packStatus := "Time: " . mminutes . "m | Packs: " . total
            packStatus .= " | Avg: " . Round(total / mminutes, 2) . " packs/min"
            
            discMessage .= "\n" . packStatus . "\nVersion: " . RegExReplace(githubUser, "-.*$") . "-" . localVersion
            discMessage .= typeMsg
            discMessage .= selectMsg
            
            ; Add special note about Main's test mode status
            if (mainTestMode == "1")
                discMessage .= "\n\nMain entered GP Test Mode ✕"
            else
                discMessage .= "\n\nMain exited GP Test Mode ✓"
            
            ; Send the message
            LogToDiscord(discMessage,, false,,, heartBeatWebhookURL)
            
            ; Clear the flag
            IniDelete, HeartBeat.ini, TestMode, Main
        }
        
        ; Every 5 minutes, pull down the main ID list and showcase list
        if(Mod(A_Index, 10) = 0) {
            if(mainIdsURL != "") {
                DownloadFile(mainIdsURL, "ids.txt")
            } else {
                if(FileExist("ids.txt"))
                    FileDelete, ids.txt
            }
        }
        
        ; Sum all variable values and write to total.json
        total := SumVariablesInJsonFile()
        totalSeconds := Round((A_TickCount - rerollTime) / 1000) ; Total time in seconds
        mminutes := Floor(totalSeconds / 60)
        
        packStatus := "Time: " . mminutes . "m Packs: " . total
        packStatus .= " | Avg: " . Round(total / mminutes, 2) . " packs/min"
        
        ; Display pack status at the bottom of the first reroll instance
        DisplayPackStatus(packStatus, ((runMain ? Mains * scaleParam : 0) + 5), 625)
        
        ; FIXED HEARTBEAT CODE
        if(heartBeat) {
            ; Each loop iteration is 30 seconds (0.5 minutes)
            ; So for X minutes, we need X * 2 iterations
            heartbeatIterations := heartBeatDelay * 2
            
            ; Send heartbeat at start (A_Index = 1) or every heartbeatDelay minutes
            if (A_Index = 1 || Mod(A_Index, heartbeatIterations) = 0) {
                
                onlineAHK := ""
                offlineAHK := ""
                Online := []
                
                Loop %Instances% {
                    IniRead, value, HeartBeat.ini, HeartBeat, Instance%A_Index%
                    if(value)
                        Online.Push(1)
                    else
                        Online.Push(0)
                    IniWrite, 0, HeartBeat.ini, HeartBeat, Instance%A_Index%
                }
                
                for index, value in Online {
                    if(index = Online.MaxIndex())
                        commaSeparate := ""
                    else
                        commaSeparate := ", "
                    if(value)
                        onlineAHK .= A_Index . commaSeparate
                    else
                        offlineAHK .= A_Index . commaSeparate
                }
                
                if(runMain) {
                    IniRead, value, HeartBeat.ini, HeartBeat, Main
                    if(value) {
                        if (onlineAHK)
                            onlineAHK := "Main, " . onlineAHK
                        else
                            onlineAHK := "Main"
                    }
                    else {
                        if (offlineAHK)
                            offlineAHK := "Main, " . offlineAHK
                        else
                            offlineAHK := "Main"
                    }
                    IniWrite, 0, HeartBeat.ini, HeartBeat, Main
                }
                
                if(offlineAHK = "")
                    offlineAHK := "Offline: none"
                else
                    offlineAHK := "Offline: " . RTrim(offlineAHK, ", ")
                if(onlineAHK = "")
                    onlineAHK := "Online: none"
                else
                    onlineAHK := "Online: " . RTrim(onlineAHK, ", ")
                
                discMessage := heartBeatName ? "\n" . heartBeatName : ""
                
                discMessage .= "\n" . onlineAHK . "\n" . offlineAHK . "\n" . packStatus . "\nVersion: " . RegExReplace(githubUser, "-.*$") . "-" . localVersion
                discMessage .= typeMsg
                discMessage .= selectMsg
                
                LogToDiscord(discMessage,, false,,, heartBeatWebhookURL)
                
                ; Optional debug log
                if (debugMode) {
                    FileAppend, % A_Now . " - Heartbeat sent at iteration " . A_Index . "`n", %A_ScriptDir%\heartbeat_log.txt
                }
            }
        }
    }

Return

GuiClose:
    ; Save all settings before exiting
    SaveAllSettings()
    
    ; Kill all related scripts
    KillAllScripts()

ExitApp
return

; New hotkey for sending "All Offline" status message
~+F7::
    SendAllInstancesOfflineStatus()
ExitApp
return

; Function to send a Discord message with all instances marked as offline
SendAllInstancesOfflineStatus() {
    global heartBeatName, heartBeatWebhookURL, localVersion, githubUser, Instances, runMain, Mains
    global typeMsg, selectMsg, rerollTime, scaleParam
    
    ; Display visual feedback that the hotkey was triggered
    DisplayPackStatus("Shift+F7 pressed - Sending offline heartbeat to Discord...", ((runMain ? Mains * scaleParam : 0) + 5), 625)
    
    ; Create message showing all instances as offline
    offlineInstances := ""
    if (runMain) {
        offlineInstances := "Main"
        if (Mains > 1) {
            Loop, % Mains - 1
                offlineInstances .= ", Main" . (A_Index + 1)
        }
        if (Instances > 0)
            offlineInstances .= ", "
    }
    
    Loop, %Instances% {
        offlineInstances .= A_Index
        if (A_Index < Instances)
            offlineInstances .= ", "
    }
    
    ; Create status message with heartbeat info
    discMessage := heartBeatName ? "\n" . heartBeatName : ""
    discMessage .= "\nOnline: none"
    discMessage .= "\nOffline: " . offlineInstances
    
    ; Add pack statistics
    total := SumVariablesInJsonFile()
    totalSeconds := Round((A_TickCount - rerollTime) / 1000)
    mminutes := Floor(totalSeconds / 60)
    packStatus := "Time: " . mminutes . "m | Packs: " . total
    packStatus .= " | Avg: " . Round(total / mminutes, 2) . " packs/min"
    
    discMessage .= "\n" . packStatus . "\nVersion: " . RegExReplace(githubUser, "-.*$") . "-" . localVersion
    discMessage .= typeMsg
    discMessage .= selectMsg
    discMessage .= "\n\n All instances marked as OFFLINE"
    
    ; Send the message
    LogToDiscord(discMessage,, false,,, heartBeatWebhookURL)
    
    ; Display confirmation in the status bar
    DisplayPackStatus("Discord notification sent: All instances marked as OFFLINE", ((runMain ? Mains * scaleParam : 0) + 5), 625)
}

; Improved status display function
DisplayPackStatus(Message, X := 0, Y := 625) {
    global SelectedMonitorIndex
    static GuiName := "PackStatusGUI"
    
    ; Fixed light theme colors
    bgColor := "F0F5F9" ; Light background
    textColor := "2E3440" ; Dark text for contrast
    
    MaxRetries := 10
    RetryCount := 0
    
    try {
        ; Get monitor origin from index
        SelectedMonitorIndex := RegExReplace(SelectedMonitorIndex, ":.*$")
        SysGet, Monitor, Monitor, %SelectedMonitorIndex%
        X := MonitorLeft + X
        
        ;Adjust Y position to be just above buttons
        Y := MonitorTop + 503 ; This is approximately where the buttons start - 30 (status height)
        
        ; Check if GUI already exists
        Gui %GuiName%:+LastFoundExist
        if WinExist() {
            GuiControl, %GuiName%:, PacksText, %Message%
        }
        else {
            ; Create a new GUI with light theme styling
            OwnerWND := WinExist(1)
            if(!OwnerWND)
                Gui, %GuiName%:New, +ToolWindow -Caption +LastFound -DPIScale
            else
                Gui, %GuiName%:New, +Owner%OwnerWND% +ToolWindow -Caption +LastFound -DPIScale
            
            Gui, %GuiName%:Color, %bgColor% ; Light background
            Gui, %GuiName%:Margin, 2, 2
            Gui, %GuiName%:Font, s8 c%textColor% ; Dark text
            Gui, %GuiName%:Add, Text, vPacksText c%textColor%, %Message%
            
            ; Show the GUI without activating it
            Gui, %GuiName%:Show, NoActivate x%X% y%Y%, %GuiName%
        }
    } catch e {
        ; Silent error handling
    }
}

; Global variable to track the current JSON file
global jsonFileName := ""

; Function to create or select the JSON file
InitializeJsonFile() {
    global jsonFileName
    fileName := A_ScriptDir . "\json\Packs.json"
    
    ; Add this line to create the directory if it doesn't exist
    FileCreateDir, %A_ScriptDir%\json
    
    if FileExist(fileName)
        FileDelete, %fileName%
    if !FileExist(fileName) {
        ; Create a new file with an empty JSON array
        FileAppend, [], %fileName% ; Write an empty JSON array
        jsonFileName := fileName
        return
    }
}

; Function to append a time and variable pair to the JSON file
AppendToJsonFile(variableValue) {
    global jsonFileName
    if (jsonFileName = "") {
        MsgBox, JSON file not initialized. Call InitializeJsonFile() first.
        return
    }
    
    ; Read the current content of the JSON file
    FileRead, jsonContent, %jsonFileName%
    if (jsonContent = "") {
        jsonContent := "[]"
    }
    
    ; Parse and modify the JSON content
    jsonContent := SubStr(jsonContent, 1, StrLen(jsonContent) - 1) ; Remove trailing bracket
    if (jsonContent != "[")
        jsonContent .= ","
    jsonContent .= "{""time"": """ A_Now """, ""variable"": " variableValue "}]"
    
    ; Write the updated JSON back to the file
    FileDelete, %jsonFileName%
    FileAppend, %jsonContent%, %jsonFileName%
}

; Function to sum all variable values in the JSON file
SumVariablesInJsonFile() {
    global jsonFileName
    if (jsonFileName = "") {
        return 0 ; Return 0 instead of nothing if jsonFileName is empty
    }
    
    ; Read the file content
    FileRead, jsonContent, %jsonFileName%
    if (jsonContent = "") {
        return 0
    }
    
    ; Parse the JSON and calculate the sum
    sum := 0
    ; Clean and parse JSON content
    jsonContent := StrReplace(jsonContent, "[", "") ; Remove starting bracket
    jsonContent := StrReplace(jsonContent, "]", "") ; Remove ending bracket
    Loop, Parse, jsonContent, {, }
    {
        ; Match each variable value
        if (RegExMatch(A_LoopField, """variable"":\s*(-?\d+)", match)) {
            sum += match1
        }
    }
    
    ; Write the total sum to a file called "total.json"
    if(sum > 0) {
        totalFile := A_ScriptDir . "\json\total.json"
        totalContent := "{""total_sum"": " sum "}"
        FileDelete, %totalFile%
        FileAppend, %totalContent%, %totalFile%
    }
    
    return sum
}

CheckForUpdate() {
    global githubUser, repoName, localVersion, zipPath, extractPath, scriptFolder, currentDictionary
    url := "https://api.github.com/repos/" githubUser "/" repoName "/releases/latest"
    
    response := HttpGet(url)
    if !response
    {
        MsgBox, currentDictionary.fail_fetch
        return
    }
    latestReleaseBody := FixFormat(ExtractJSONValue(response, "body"))
    latestVersion := ExtractJSONValue(response, "tag_name")
    zipDownloadURL := ExtractJSONValue(response, "zipball_url")
    Clipboard := latestReleaseBody
    if (zipDownloadURL = "" || !InStr(zipDownloadURL, "http"))
    {
        MsgBox, % currentDictionary.fail_url
        return
    }
    
    if (latestVersion = "")
    {
        MsgBox, % currentDictionary.fail_version
        return
    }
    
    if (VersionCompare(latestVersion, localVersion) > 0)
    {
        ; Get release notes from the JSON (ensure this is populated earlier in the script)
        releaseNotes := latestReleaseBody ; Assuming `latestReleaseBody` contains the release notes
        
        ; Show a message box asking if the user wants to download
        updateAvailable := currentDictionary.update_title
        latestDownloaad := currentDictionary.confirm_dl
        MsgBox, 4, %updateAvailable% %latestVersion%, %releaseNotes%`n`nDo you want to download the latest version?
        
        ; If the user clicks Yes (return value 6)
        IfMsgBox, Yes
        {
            MsgBox, 64, Downloading..., % currentDictionary.downloading
            
            ; Proceed with downloading the update
            URLDownloadToFile, %zipDownloadURL%, %zipPath%
            if ErrorLevel
            {
                MsgBox, % currentDictionary.dl_failed
                return
            }
            else {
                MsgBox, % currentDictionary.dl_complete
                
                ; Create a temporary folder for extraction
                tempExtractPath := A_Temp "\PTCGPB_Temp"
                FileCreateDir, %tempExtractPath%
                
                ; Extract the ZIP file into the temporary folder
                RunWait, powershell -Command "Expand-Archive -Path '%zipPath%' -DestinationPath '%tempExtractPath%' -Force",, Hide
                
                ; Check if extraction was successful
                if !FileExist(tempExtractPath)
                {
                    MsgBox, % currentDictionary.extract_failed
                    return
                }
                
                ; Get the first subfolder in the extracted folder
                Loop, Files, %tempExtractPath%\*, D
                {
                    extractedFolder := A_LoopFileFullPath
                    break
                }
                
                ; Check if a subfolder was found and move its contents recursively to the script folder
                if (extractedFolder)
                {
                    MoveFilesRecursively(extractedFolder, scriptFolder)
                    
                    ; Clean up the temporary extraction folder
                    FileRemoveDir, %tempExtractPath%, 1
                    MsgBox, % currentDictionary.installed
                    Reload
                }
                else
                {
                    MsgBox, % currentDictionary.missing_files
                    return
                }
            }
        }
        else
        {
            MsgBox, % currentDictionary.cancel
            return
        }
    }
    else
    {
        MsgBox, % currentDictionary.up_to_date
    }
}

MoveFilesRecursively(srcFolder, destFolder) {
    ; Loop through all files and subfolders in the source folder
    Loop, Files, % srcFolder . "\*", R
    {
        ; Get the relative path of the file/folder from the srcFolder
        relativePath := SubStr(A_LoopFileFullPath, StrLen(srcFolder) + 2)
        
        ; Create the corresponding destination path
        destPath := destFolder . "\" . relativePath
        
        ; If it's a directory, create it in the destination folder
        if (A_LoopIsDir)
        {
            ; Ensure the directory exists, if not, create it
            FileCreateDir, % destPath
        }
        else
        {
            if ((relativePath = "ids.txt" && FileExist(destPath))
                || (relativePath = "usernames.txt" && FileExist(destPath))
                || (relativePath = "discord.txt" && FileExist(destPath))
                || (relativePath = "vip_ids.txt" && FileExist(destPath))) {
                continue
            }
            ; If it's a file, move it to the destination folder
            ; Ensure the directory exists before moving the file
            FileCreateDir, % SubStr(destPath, 1, InStr(destPath, "\", 0, 0) - 1)
            FileMove, % A_LoopFileFullPath, % destPath, 1
        }
    }
}

HttpGet(url) {
    http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", url, false)
    http.Send()
    return http.ResponseText
}

; Function to extract value from JSON
ExtractJSONValue(json, key1, key2:="", ext:="") {
    value := ""
    json := StrReplace(json, """", "")
    lines := StrSplit(json, ",")
    
    Loop, % lines.MaxIndex()
    {
        if InStr(lines[A_Index], key1 ":") {
            ; Take everything after the first colon as the value
            value := SubStr(lines[A_Index], InStr(lines[A_Index], ":") + 1)
            if (key2 != "")
            {
                if InStr(lines[A_Index+1], key2 ":") && InStr(lines[A_Index+1], ext)
                    value := SubStr(lines[A_Index+1], InStr(lines[A_Index+1], ":") + 1)
            }
            break
        }
    }
    return Trim(value)
}

FixFormat(text) {
    ; Replace carriage return and newline with an actual line break
    text := StrReplace(text, "\r\n", "`n") ; Replace \r\n with actual newlines
    text := StrReplace(text, "\n", "`n") ; Replace \n with newlines
    
    ; Remove unnecessary backslashes before other characters like "player" and "None"
    text := StrReplace(text, "\player", "player") ; Example: removing backslashes around words
    text := StrReplace(text, "\None", "None") ; Remove backslash around "None"
    text := StrReplace(text, "\Welcome", "Welcome") ; Removing \ before "Welcome"
    
    ; Escape commas by replacing them with %2C (URL encoding)
    text := StrReplace(text, ",", "")
    
    return text
}

VersionCompare(v1, v2) {
    ; Remove non-numeric characters (like 'alpha', 'beta')
    cleanV1 := RegExReplace(v1, "[^\d.]")
    cleanV2 := RegExReplace(v2, "[^\d.]")
    
    v1Parts := StrSplit(cleanV1, ".")
    v2Parts := StrSplit(cleanV2, ".")
    
    Loop, % Max(v1Parts.MaxIndex(), v2Parts.MaxIndex()) {
        num1 := v1Parts[A_Index] ? v1Parts[A_Index] : 0
        num2 := v2Parts[A_Index] ? v2Parts[A_Index] : 0
        if (num1 > num2)
            return 1
        if (num1 < num2)
            return -1
    }
    
    ; If versions are numerically equal, check if one is an alpha version
    isV1Alpha := InStr(v1, "alpha") || InStr(v1, "beta")
    isV2Alpha := InStr(v2, "alpha") || InStr(v2, "beta")
    
    if (isV1Alpha && !isV2Alpha)
        return -1 ; Non-alpha version is newer
    if (!isV1Alpha && isV2Alpha)
        return 1 ; Alpha version is older
    
    return 0 ; Versions are equal
}

DownloadFile(url, filename) {
    url := url
    localPath = %A_ScriptDir%\%filename%
    
    URLDownloadToFile, %url%, %localPath%
}

ReadFile(filename, numbers := false) {
    FileRead, content, %A_ScriptDir%\%filename%.txt
    
    if (!content)
        return false
    
    values := []
    for _, val in StrSplit(Trim(content), "`n") {
        cleanVal := RegExReplace(val, "[^a-zA-Z0-9]") ; Remove non-alphanumeric characters
        if (cleanVal != "")
            values.Push(cleanVal)
    }
    
    return values.MaxIndex() ? values : false
}

ErrorHandler(exception) {
    ; Display the error message
    errorMessage := "Error in PTCGPB.ahk`n`n"
        . "Message: " exception.Message "`n"
        . "What: " exception.What "`n"
        . "Line: " exception.Line "`n`n"
        . "Click OK to close all related scripts and exit."
    
    MsgBox, 16, PTCGPB Error, %errorMessage%
    
    ; Kill all related scripts
    KillAllScripts()
    
    ; Exit this script
    ExitApp, 1
    return true ; Indicate that the error was handled
}

; Add this function to kill all related scripts
KillAllScripts() {
    ; Kill Monitor.ahk if running
    Process, Exist, Monitor.ahk
    if (ErrorLevel) {
        Process, Close, %ErrorLevel%
    }
    
    ; Kill all instance scripts
    Loop, 50 { ; Assuming you won't have more than 50 instances
        scriptName := A_Index . ".ahk"
        Process, Exist, %scriptName%
        if (ErrorLevel) {
            Process, Close, %ErrorLevel%
        }
        
        ; Also check for Main scripts
        if (A_Index = 1) {
            Process, Exist, Main.ahk
            if (ErrorLevel) {
                Process, Close, %ErrorLevel%
            }
        } else {
            mainScript := "Main" . A_Index . ".ahk"
            Process, Exist, %mainScript%
            if (ErrorLevel) {
                Process, Close, %ErrorLevel%
            }
        }
    }
    
    ; Close any status GUIs that might be open
    Gui, PackStatusGUI:Destroy
}
