@echo off
setlocal
cd /d "%~dp0"
echo Starting Hexo preview at http://localhost:4000
".\node_modules\.bin\hexo.cmd" generate
node ".\local-tools\static-server.js"
