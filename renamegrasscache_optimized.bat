@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo     S E A S O N A L   G R A S S   C A C H E
echo            F I L E   R E N A M E R
echo ===============================================
echo           renamegrasscache.bat v1.1 (Optimized)

echo.
echo.

echo Current Folder: %CD%
echo.

rem Define choices
set "CHOICE_WIN=1"
set "CHOICE_SPR=2"
set "CHOICE_SUM=3"
set "CHOICE_AUT=4"
set "CHOICE_REMOVE=7"
set "CHOICE_EXIT=0"

rem Ask user to select a season to rename to or strip seasonal extensions
echo Rename Files to:
echo ------------------------------
echo  %CHOICE_WIN%. Winter
echo  %CHOICE_SPR%. Spring
echo  %CHOICE_SUM%. Summer
echo  %CHOICE_AUT%. Autumn
echo.
echo  %CHOICE_REMOVE%. Remove seasonal extension(s)
echo.
echo  %CHOICE_EXIT%. Exit without renaming
echo ------------------------------
echo.

:choose_option
set /p choice="Enter your choice: "

rem More efficient choice validation using goto
if "%choice%"=="0" exit /b
if "%choice%"=="1" goto set_winter
if "%choice%"=="2" goto set_spring  
if "%choice%"=="3" goto set_summer
if "%choice%"=="4" goto set_autumn
if "%choice%"=="7" goto set_remove
echo Invalid choice, please enter a valid option.
goto choose_option

:set_winter
set "extension=.WIN.cgid"
set "season_name=Winter"
goto start_processing

:set_spring  
set "extension=.SPR.cgid"
set "season_name=Spring"
goto start_processing

:set_summer
set "extension=.SUM.cgid" 
set "season_name=Summer"
goto start_processing

:set_autumn
set "extension=.AUT.cgid"
set "season_name=Autumn"
goto start_processing

:set_remove
set "extension=.cgid"
set "season_name=Remove seasonal extensions"
goto start_processing

:start_processing
echo.
echo.

rem Initialize counters
set /a counter=0
set /a renamedCounter=0
set /a errorCounter=0
set /a skippedCounter=0

echo Processing: %season_name%
if not "%season_name%"=="Remove seasonal extensions" (
    echo Renaming all *.cgid files in current folder to filename%extension%...
) else (
    echo Renaming all *.cgid files in current folder to filename.cgid...
)

rem More efficient file processing
for %%f in (*.cgid) do (
    rem Get the base filename more efficiently using string manipulation
    set "fullname=%%~nf"
    
    rem Extract base name by finding first dot (much faster than for /f)
    for /f "tokens=1 delims=." %%a in ("!fullname!") do set "filenameBase=%%a"
    
    set /a counter+=1
    set "targetFile=!filenameBase!!extension!"
    set "currentPath=%%~dpf"
    
    rem Check if target file already exists
    if exist "!currentPath!!targetFile!" (
        echo Error: File "!targetFile!" already exists. Skipping rename.
        set /a errorCounter+=1
    ) else (
        rem Check if rename is actually needed (case-sensitive comparison)
        if "!targetFile!" neq "%%~nxf" (
            rem Perform the rename with error checking
            ren "%%f" "!targetFile!" 2>nul
            if errorlevel 1 (
                echo Error: Failed to rename "%%~nxf" to "!targetFile!"
                set /a errorCounter+=1
            ) else (
                set /a renamedCounter+=1
            )
        ) else (
            set /a skippedCounter+=1
        )
    )
)

echo.

if !counter! equ 0 (
    echo =================================================
    echo No valid files found for renaming. Aborting...
) else (
    echo =================================================
    echo Processed !counter! files:
    echo   - !renamedCounter! files renamed successfully
    echo   - !skippedCounter! files already had correct names
    echo   - !errorCounter! files had errors
)
echo.
pause
