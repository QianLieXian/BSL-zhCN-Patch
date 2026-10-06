@echo off
chcp 65001 >nul
echo BSL 10.1.8 简体中文优化魔改补丁
echo 请在随后弹出的窗口中选择官方原版 ZIP。
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Apply-Optimized.ps1"
if errorlevel 1 echo 安装失败。请查看上面的错误说明；原版 ZIP 保留不变。
pause
