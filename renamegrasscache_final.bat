@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo     S E A S O N A L   G R A S S   C A C H E
echo            F I L E   R E N A M E R
echo ===============================================
echo           renamegrasscache.bat v2.0 (Final)

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
if "%choice%"=="1" set "ext=.WIN.cgid" & goto process
if "%choice%"=="2" set "ext=.SPR.cgid" & goto process
if "%choice%"=="3" set "ext=.SUM.cgid" & goto process  
if "%choice%"=="4" set "ext=.AUT.cgid" & goto process
if "%choice%"=="7" set "ext=.cgid" & goto process
echo Invalid choice, please enter a valid option.
goto choose_option

:process
echo.
set /a count=0, renamed=0, errors=0, skipped=0

rem FASTEST METHOD: Simple string replacement using batch built-ins
for %%f in (*.cgid) do (
    set "name=%%~nf"
    set "base=!name!"
    
    rem Remove everything after first dot (fastest method)
    for /f "tokens=1 delims=." %%a in ("!name!") do set "base=%%a"
    
    set /a count+=1
    set "target=!base!!ext!"
    
    if exist "!target!" (
        echo Error: "!target!" already exists. Skipping "%%f"
        set /a errors+=1
    ) else if "!target!" neq "%%~nxf" (
        ren "%%f" "!target!" 2>nul && (
            echo Renamed: "%%f" to "!target!"
            set /a renamed+=1
        ) || (
            echo Error: Failed to rename "%%f"
            set /a errors+=1
        )
    ) else (
        set /a skipped+=1
    )
)

echo.
echo =================================================
echo Summary: !count! files processed
echo   Renamed: !renamed!, Skipped: !skipped!, Errors: !errors!
echo.
pause
