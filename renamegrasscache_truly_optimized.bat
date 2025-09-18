@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo     S E A S O N A L   G R A S S   C A C H E
echo            F I L E   R E N A M E R
echo ===============================================
echo           renamegrasscache.bat v1.2 (Actually Optimized)

echo.
echo Current Folder: %CD%
echo.

echo Rename Files to:
echo ------------------------------
echo  1. Winter
echo  2. Spring
echo  3. Summer
echo  4. Autumn
echo.
echo  7. Remove seasonal extension(s)
echo.
echo  0. Exit without renaming
echo ------------------------------
echo.

:choose_option
set /p choice="Enter your choice: "

if "%choice%"=="0" exit /b
if "%choice%"=="1" set "extension=.WIN.cgid" & set "season_name=Winter" & goto start_processing
if "%choice%"=="2" set "extension=.SPR.cgid" & set "season_name=Spring" & goto start_processing  
if "%choice%"=="3" set "extension=.SUM.cgid" & set "season_name=Summer" & goto start_processing
if "%choice%"=="4" set "extension=.AUT.cgid" & set "season_name=Autumn" & goto start_processing
if "%choice%"=="7" set "extension=.cgid" & set "season_name=Remove seasonal extensions" & goto start_processing
echo Invalid choice, please enter a valid option.
goto choose_option

:start_processing
echo.
echo Processing: !season_name!
echo Renaming all *.cgid files in current folder...
echo.

set /a counter=0
set /a renamedCounter=0
set /a errorCounter=0
set /a skippedCounter=0

rem ACTUAL PERFORMANCE FIX: Use string manipulation instead of for /f
for %%f in (*.cgid) do (
    set "fullname=%%~nf"
    
    rem Fast string manipulation to get base name (no subprocess!)
    set "filenameBase=!fullname!"
    if "!fullname!" neq "!fullname:.=!" (
        rem File has dots, extract everything before first dot
        set "temp=!fullname!"
        set "filenameBase="
        :extract_loop
        if "!temp!" equ "" goto extract_done
        if "!temp:~0,1!" equ "." goto extract_done
        set "filenameBase=!filenameBase!!temp:~0,1!"
        set "temp=!temp:~1!"
        goto extract_loop
        :extract_done
    )
    
    set /a counter+=1
    set "targetFile=!filenameBase!!extension!"
    
    if exist "!targetFile!" (
        echo Error: File "!targetFile!" already exists. Skipping "%%~nxf"
        set /a errorCounter+=1
    ) else (
        if "!targetFile!" neq "%%~nxf" (
            ren "%%f" "!targetFile!" 2>nul
            if errorlevel 1 (
                echo Error: Failed to rename "%%~nxf" to "!targetFile!"
                set /a errorCounter+=1
            ) else (
                echo Renamed: "%%~nxf" to "!targetFile!"
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
    echo No *.cgid files found in current directory.
) else (
    echo =================================================
    echo Summary:
    echo   Total files processed: !counter!
    echo   Successfully renamed:  !renamedCounter!
    echo   Already correct name:  !skippedCounter!
    echo   Errors encountered:    !errorCounter!
)
echo.
pause
