@echo off
chcp 65001 >nul
title 简历网站 - 更新发布
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1"
echo.
pause
