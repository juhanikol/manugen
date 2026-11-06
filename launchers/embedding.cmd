@echo off
rem Embedding server only: application.rag.embeddingServer of settings.json beside this file (same arguments and
rem process control as ticket-demo.cmd). Starts no application, RAG service or generation server.
rem Option: --settings FILE. Stop: Ctrl+C (stops only this server).
"%~dp0embedding.exe" %*
if errorlevel 1 pause
