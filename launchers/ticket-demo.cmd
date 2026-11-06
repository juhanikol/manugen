@echo off
rem Ticket application. Everything it starts is set in settings.json beside this file: the llama-server it starts
rem (application.modelServer "start") or connects to ("connect"), the workflow and the listen address
rem (default UI http://127.0.0.1:3000/). Edit settings.json and start again to apply a change.
rem Option: --settings FILE. Stop: Ctrl+C (stops only the processes this start began).
"%~dp0ticket-demo.exe" %*
if errorlevel 1 pause
