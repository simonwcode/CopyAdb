# CopyAdb
## CopyAdb v1.0
Copy Android file to PC via Adb which support breakpoint transfer by file unit:   

    -cmd auto|count|list|dir|file|clear -sourceDir /sdcard/yourdir [-check bool|-sleep seconds|-depth dirDepth]  
        -cmd: command  
        -sourceDir: source dir in Android  
        -check: copy only non-existent files  
        -sleep: retry sleep seconds after dissconnect  
        -depth: list dir depth  
        
**Exmples:**  

    copy whole dir auto reconnect:
    .\copy.ps1 -cmd auto -sourceDir /sdcard/Picutres -check true -sleep 3

    count file in dir:
    .\copy.ps1 -cmd count -sourceDir /sdcard/Picutres -sleep 3

    list all sub dir:
    .\copy.ps1 -cmd list -sourceDir /sdcard/Picutres -depth 2

    copy whole dir:
    .\copy.ps1 -cmd dir -sourceDir /sdcard/Picutres -check true

    copy single level files:
    .\copy.ps1 -cmd file -sourceDir /sdcard/Picutres -check false

    clear all temp files:
    .\copy.ps1 -cmd clear

> 如果有中文文件名：Win10/11-控制面板-区域-管理-更改系统区域设置-Beta版：使用Unicode UTF-8提供全球语言支持
> 
> 写这个脚本的原因是，我的手机在系统升级后无限重启，只能在桌面停留10s，没有也无法Root
