@echo off
REM VLagIt Web Build Script for Windows
REM Builds Flutter web app for production deployment

echo Building VLagIt Web App for Production...

REM Navigate to project root
cd /d "%~dp0\.."

REM Clean previous builds
echo Cleaning previous builds...
call flutter clean

REM Get dependencies
echo Getting dependencies...
call flutter pub get

REM Build for production
echo Building Flutter web...
call flutter build web --release

REM Check if build was successful
if exist "build\web" (
    echo Build successful!
    echo Build output: build\web\
    echo.
    echo Next steps:
    echo 1. Upload all files from build\web\ to public_html\
    echo 2. Ensure .htaccess files are uploaded
    echo 3. Test the deployment at https://vlagit.com
) else (
    echo Build failed! Check errors above.
    exit /b 1
)

pause
