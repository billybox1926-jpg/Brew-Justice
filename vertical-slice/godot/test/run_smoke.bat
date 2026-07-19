@echo off
echo Running focus_mode smoke checks...
if not exist "C:\Users\Billy\Documents\GitHub\Brew-Justice\vertical-slice\godot\project.godot" (
  echo Missing project.godot
  exit /b 1
)
echo OK: project.godot found
exit /b 0
