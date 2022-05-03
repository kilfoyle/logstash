@echo off
setlocal enabledelayedexpansion

if "%WORKSPACE%" == "" (
  echo Error: environment variable WORKSPACE must be defined. Aborting..
  exit /B 1
)

:: see if %WORKSPACE% is already mapped to a drive
for /f "tokens=1* delims==> " %%G IN ('subst') do (
  set sdrive=%%G
  :: removing extra space
  set sdrive=!sdrive:~0,2!
  set spath=%%H

  if /I "!spath!" == "%WORKSPACE%" (
    set use_drive=!sdrive!
    goto :found_drive
  )
)

:: no existing mapping
:: try to assign "%WORKSPACE%" to the first drive letter which works
for %%i in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
    set "drive=%%i:"
    subst !drive! "%WORKSPACE%" >nul
    if not errorlevel 1 (
        set use_drive=!drive!
        goto :found_drive
    )
)

echo Error: unable to subst drive to path %WORKSPACE%. Aborting...
exit /B 1

:found_drive
echo Using drive !use_drive! for %WORKSPACE%

:: change current directory to that drive
!use_drive!

if defined JAVA_OPTS (
  set JAVA_OPTS="%JAVA_OPTS% -Djdk.io.File.enableADS=true"
) else (
  set JAVA_OPTS="-Djdk.io.File.enableADS=true"
)

if defined JRUBY_OPTS (
  set JRUBY_OPTS="%JRUBY_OPTS% -J-Xmx1g -J-Djdk.io.File.enableADS=true"
) else (
  set JRUBY_OPTS="-J-Xmx1g -J-Djdk.io.File.enableADS=true"
)
if defined GRADLE_OPTS (
  set GRADLE_OPTS="%GRADLE_OPTS% -Djdk.io.File.enableADS=true"
) else (
  set GRADLE_OPTS="-Djdk.io.File.enableADS=true"
)

echo Running core tests..
if defined BUILD_JAVA_HOME (
  set GRADLE_OPTS=%GRADLE_OPTS% -Dorg.gradle.java.home=%BUILD_JAVA_HOME%
)
echo Invoking Gradle, GRADLE_OPTS: %GRADLE_OPTS%, BUILD_JAVA_HOME: %BUILD_JAVA_HOME%, JRUBY_OPTS: %JRUBY_OPTS%, JAVA_OPTS: %JAVA_OPTS%
call .\gradlew.bat test --console=plain --no-daemon --info

if errorlevel 1 (
  echo Error: failed to run core tests. Aborting..
  exit /B 1
)
