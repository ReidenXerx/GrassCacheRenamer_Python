@echo off
setlocal enabledelayedexpansion

rem ===============================================
rem   SEASONAL GRASS CACHE FILE RENAMER
rem          Auto-Installing Python Runner
rem ===============================================

set "SCRIPT_DIR=%~dp0"
set "PYTHON_SCRIPT=%SCRIPT_DIR%renamegrasscache.py"
set "PYTHON_INSTALLER=python-3.12.0-amd64.exe"
set "PYTHON_URL=https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
set "MIN_PYTHON_VERSION=3.7"

echo ===============================================
echo   SEASONAL GRASS CACHE FILE RENAMER
echo      Python Auto-Installer ^& Runner
echo ===============================================
echo.

rem Check if Python script exists
if not exist "%PYTHON_SCRIPT%" (
    echo ERROR: Python script not found: %PYTHON_SCRIPT%
    echo Please ensure renamegrasscache.py is in the same directory as this batch file.
    goto :error_exit
)

echo Checking Python installation...
echo.

rem Function to check Python version
:check_python
python --version >nul 2>&1
if errorlevel 1 (
    echo Python not found in PATH.
    goto :install_python
)

rem Get Python version
for /f "tokens=2" %%v in ('python --version 2^>^&1') do set "PYTHON_VERSION=%%v"
echo Found Python version: %PYTHON_VERSION%

rem Check if version is sufficient (simple check for 3.x)
echo %PYTHON_VERSION% | findstr /r "^3\." >nul
if errorlevel 1 (
    echo Python version is too old. Need Python 3.7 or higher.
    goto :install_python
)

rem Extract major.minor version for more precise checking
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    set "MAJOR=%%a"
    set "MINOR=%%b"
)

if %MAJOR% LSS 3 (
    echo Python version %PYTHON_VERSION% is too old. Need Python 3.7 or higher.
    goto :install_python
)

if %MAJOR% EQU 3 if %MINOR% LSS 7 (
    echo Python version %PYTHON_VERSION% is too old. Need Python 3.7 or higher.
    goto :install_python
)

echo Python version is sufficient.
goto :run_script

:install_python
echo.
echo Python installation required.
echo This will download and install Python 3.12.0 from python.org
echo.
choice /c YN /m "Do you want to download and install Python now"
if errorlevel 2 goto :manual_install
if errorlevel 1 goto :download_python

:download_python
echo.
echo Downloading Python installer...
echo URL: %PYTHON_URL%
echo.

rem Try PowerShell first (more reliable)
powershell -Command "& {[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%PYTHON_URL%', '%TEMP%\%PYTHON_INSTALLER%')}" >nul 2>&1
if errorlevel 1 (
    echo PowerShell download failed. Trying curl...
    curl -L -o "%TEMP%\%PYTHON_INSTALLER%" "%PYTHON_URL%" >nul 2>&1
    if errorlevel 1 (
        echo Download failed. Please install Python manually.
        goto :manual_install
    )
)

echo Download completed successfully.
echo.

echo Installing Python...
echo This may take a few minutes and might require administrator privileges.
echo.

rem Run Python installer with quiet install and add to PATH
"%TEMP%\%PYTHON_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
if errorlevel 1 (
    echo Installation failed. Trying interactive installation...
    "%TEMP%\%PYTHON_INSTALLER%"
    if errorlevel 1 (
        echo Python installation failed.
        goto :error_exit
    )
)

rem Clean up installer
del "%TEMP%\%PYTHON_INSTALLER%" >nul 2>&1

echo.
echo Python installation completed.
echo.
echo IMPORTANT: You may need to restart your command prompt or computer
echo for Python to be available in PATH.
echo.
echo Checking if Python is now available...

rem Refresh environment variables
call :refresh_env

rem Try to find Python again
python --version >nul 2>&1
if errorlevel 1 (
    echo Python still not found in PATH after installation.
    echo Please restart your command prompt and run this script again.
    echo.
    echo Alternatively, you can run the Python script directly:
    echo   python "%PYTHON_SCRIPT%"
    goto :manual_exit
)

echo Python is now available!
goto :run_script

:refresh_env
rem Try to refresh environment variables
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "SYS_PATH=%%b"
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%b"
if defined USER_PATH (
    set "PATH=%SYS_PATH%;%USER_PATH%"
) else (
    set "PATH=%SYS_PATH%"
)
exit /b

:manual_install
echo.
echo Manual installation required:
echo 1. Go to https://www.python.org/downloads/
echo 2. Download Python 3.7 or higher
echo 3. Run the installer and make sure to check "Add Python to PATH"
echo 4. Restart your command prompt
echo 5. Run this script again
echo.
goto :manual_exit

:run_script
echo.
echo ===============================================
echo Starting Grass Cache Renamer...
echo ===============================================
echo.
echo The script will ask you to select the target folder containing .cgid files.
echo.

rem Change to script directory to ensure relative paths work
cd /d "%SCRIPT_DIR%"

rem Run the Python script (it will handle folder selection)
python "%PYTHON_SCRIPT%"
if errorlevel 1 (
    echo.
    echo Python script execution failed.
    goto :error_exit
)

goto :normal_exit

:error_exit
echo.
echo ===============================================
echo Script execution failed.
echo ===============================================
pause
exit /b 1

:manual_exit
echo.
pause
exit /b 0

:normal_exit
echo.
echo ===============================================
echo Script execution completed.
echo ===============================================
exit /b 0
