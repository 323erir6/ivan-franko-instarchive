@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title Instarchive - private GitHub publishing

echo ======================================================
echo   INSTARCHIVE - private GitHub repository publishing
echo ======================================================
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Git is not installed. Install it from https://git-scm.com/download/win
  start "" "https://git-scm.com/download/win"
  goto :failed
)
where gh >nul 2>nul
if errorlevel 1 (
  echo [ERROR] GitHub CLI is not installed. Install it from https://cli.github.com/
  start "" "https://cli.github.com/"
  goto :failed
)

gh auth status >nul 2>nul
if errorlevel 1 (
  echo [INFO] Please sign in to your GitHub account.
  gh auth login -h github.com -w
  if errorlevel 1 goto :failed
)

for /f "usebackq delims=" %%A in (`gh api user --jq ".login"`) do set "GH_USER=%%A"
for /f "usebackq delims=" %%A in (`gh api user --jq ".id"`) do set "GH_ID=%%A"
if not defined GH_USER (
  echo [ERROR] Unable to determine authenticated GitHub user.
  goto :failed
)
set "REPO=ivan-franko-instarchive"
set "FULL_REPO=!GH_USER!/!REPO!"

echo [INFO] Signed in as !GH_USER!
echo [INFO] Destination: https://github.com/!FULL_REPO!
echo [INFO] Visibility: PRIVATE
echo.
choice /C YN /M "Create/push this private repository"
if errorlevel 2 goto :done

if not exist ".git" (
  git init
  if errorlevel 1 goto :failed
)
git branch -M main >nul 2>nul
git config --local user.name "!GH_USER!"
git config --local user.email "!GH_ID!+!GH_USER!@users.noreply.github.com"
git add index.html styles.css app.js favicon.svg README.md publish-to-github.bat
if errorlevel 1 goto :failed

git diff --cached --quiet
if errorlevel 1 (
  git commit -m "Create Ivan Franko historical social profile"
  if errorlevel 1 goto :failed
)

for /f "usebackq delims=" %%V in (`gh repo view "!FULL_REPO!" --json visibility --jq ".visibility" 2^>nul`) do set "REPO_VISIBILITY=%%V"
if defined REPO_VISIBILITY (
  if /I not "!REPO_VISIBILITY!"=="PRIVATE" (
    echo [ERROR] Repository already exists and is not private. No changes were uploaded.
    goto :failed
  )
  git remote get-url origin >nul 2>nul
  if errorlevel 1 (
    git remote add origin "https://github.com/!FULL_REPO!.git"
  )
  git push -u origin main
  if errorlevel 1 goto :failed
) else (
  gh repo create "!FULL_REPO!" --private --source=. --remote=origin --push --description "Ivan Franko - educational Instagram-like historical profile"
  if errorlevel 1 goto :failed
)

echo.
echo [SUCCESS] Your website has been pushed to a PRIVATE repository.
echo [URL] https://github.com/!FULL_REPO!
start "" "https://github.com/!FULL_REPO!"
goto :done

:failed
echo.
echo Publication was not completed. Fix the error above and rerun this script.
:done
echo.
pause
endlocal
