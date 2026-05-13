@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
cd /d "%~dp0"

SET "SLN=balances-api-netcore.sln"
SET "WEB_PROJ=src\main\EntryPoint.WebApi\EntryPoint.WebApi.csproj"
SET "SWAGGER_URL=http://localhost:5132/api/transactions-search/v1/swagger"

IF /I "%~1"=="/?" GOTO help
IF /I "%~1"=="--help" GOTO help

IF /I "%~1"=="clean" GOTO clean
IF /I "%~1"=="app" GOTO app

IF /I NOT "%~1"=="test" (
    IF /I NOT "%~1"=="coverage" (
        IF /I NOT "%~1"=="mutation" (
            GOTO help
        )
    )
)

IF /I "%~1"=="test" GOTO test
IF /I "%~1"=="coverage" GOTO coverage
IF /I "%~1"=="mutation" GOTO mutation

:help
ECHO.
ECHO FMS Balance API - development scripts.
ECHO.
ECHO Usage:
ECHO %~0 [clean] [test] [app] [coverage] [mutation]
ECHO.
ECHO Parameters:
ECHO     clean      Removes bin, obj, and StrykerOutput folders, then runs dotnet clean.
ECHO.
ECHO     test       Runs all tests in the solution.
ECHO.
ECHO     app        Builds and runs the Web API (http launch profile from launchSettings).
ECHO.
ECHO     coverage   Runs tests with Coverlet and opens the HTML coverage report.
ECHO.
ECHO     mutation   Runs Stryker on the three test projects (Core, WebApi, Infra.MongoDB).
ECHO.
ECHO     --help     Shows this help message (or /? as the first argument).

GOTO end

:clean
ECHO.
ECHO Removing binary files...
CALL dotnet clean %SLN%
FOR /f %%i in ('dir bin /s /b 2^>nul') do rd /s /q "%%i"
FOR /f %%i in ('dir obj /s /b 2^>nul') do rd /s /q "%%i"
FOR /f %%i in ('dir StrykerOutput /s /b 2^>nul') do rd /s /q "%%i"

IF /I "%~2"=="test" GOTO test
IF /I "%~2"=="coverage" GOTO coverage
IF /I "%~2"=="mutation" GOTO mutation

GOTO end

:test
ECHO.
ECHO Resolving dependencies...
CALL dotnet restore %SLN% --force --no-cache

ECHO.
ECHO Building the solution...
CALL dotnet build %SLN% --configuration Debug --no-restore

ECHO.
ECHO Running tests...
CALL dotnet test %SLN% --no-build --nologo -v q

GOTO end

:app
ECHO.
ECHO Resolving dependencies...
CALL dotnet restore %SLN% --force --no-cache

ECHO.
ECHO Building the solution...
CALL dotnet build %SLN% --configuration Debug --no-restore

ECHO.
ECHO Opening Swagger UI...
START "" "%SWAGGER_URL%"

ECHO.
ECHO Running the server (MongoDB must be reachable; see launchSettings.json)...
CALL dotnet run --no-build --no-restore --nologo --launch-profile http --project .\%WEB_PROJ%

GOTO end

:coverage
ECHO.
ECHO Resolving dependencies...
CALL dotnet restore %SLN% --force --no-cache

ECHO.
ECHO Building the solution...
CALL dotnet build %SLN% --configuration Debug --no-restore

ECHO.
ECHO Running tests with coverage...
dotnet test %SLN% --no-build --nologo -v q /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura

ECHO.
ECHO Opening code coverage...
dotnet tool list -g | FINDSTR /C:"dotnet-reportgenerator-globaltool" > nul

IF %ERRORLEVEL% equ 0 (
    ECHO dotnet-reportgenerator-globaltool is already installed.
) ELSE (
    ECHO Installing dotnet-reportgenerator-globaltool...
    dotnet tool install -g dotnet-reportgenerator-globaltool
    IF %ERRORLEVEL% equ 0 (
        ECHO Installation completed successfully.
    ) ELSE (
        ECHO Installation failed.
        EXIT /b 1
    )
)

reportgenerator "-reports:./**/*.cobertura.xml" "-targetdir:coverage\lcov-report" "-reporttypes:Html"

start coverage\lcov-report\index.html

GOTO end

:mutation
ECHO.
ECHO Resolving dependencies...
CALL dotnet restore %SLN% --force --no-cache

ECHO.
ECHO Building the solution...
CALL dotnet build %SLN% --configuration Debug --no-restore

CALL :run_stryker "src\test\UnitTest.Core" "Mutation - Core"
CALL :run_stryker "src\test\IntegrationTest.EntryPoint.WebApi" "Mutation - EntryPoint.WebApi"
CALL :run_stryker "src\test\IntegrationTest.Infra.MongoDB" "Mutation - Infra.MongoDB"

GOTO end

:run_stryker
SET "STRYKER_DIR=%~1"
SET "STRYKER_LABEL=%~2"
ECHO.
ECHO %STRYKER_LABEL%
PUSHD "%STRYKER_DIR%"
IF NOT EXIST "dotnet-tools.json" (
    IF NOT EXIST ".config\dotnet-tools.json" (
        dotnet new tool-manifest
    )
)
dotnet tool install dotnet-stryker --version 4.5.1
IF ERRORLEVEL 1 dotnet tool update dotnet-stryker --version 4.5.1
dotnet stryker -o
SET "ERR=!ERRORLEVEL!"
POPD
IF !ERR! neq 0 EXIT /b !ERR!
GOTO :eof

:end
