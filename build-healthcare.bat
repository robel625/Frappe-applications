@echo off
echo ============================================
echo  Building erpnext-healthcare:v15 image
echo  (erpnext v15 + healthcare v15)
echo  This may take 20-40 minutes on first build.
echo ============================================
echo.

docker build --no-cache --tag erpnext-healthcare:v15 --file Dockerfile.healthcare .

if %errorlevel% neq 0 (
  echo.
  echo BUILD FAILED.
  echo Make sure Docker is running and you are in the frappe_docker directory.
  exit /b 1
)

echo.
echo ============================================
echo  BUILD SUCCESSFUL!
echo ============================================
echo.
echo  Next steps:
echo    docker compose -f pwd.yml down -v
echo    docker compose -f pwd.yml up -d
echo.
