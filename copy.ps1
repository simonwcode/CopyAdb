param(
    [String]$cmd = "help",
    [String]$sourceDir,
    [String]$sleep = 3,
    [String]$depth = 100,
    [String]$check = "false"
)

$dirListFile = "copy-dir-list.txt"
$dirSettingFile = "copy-dir-setting.txt"
$fileListFile = "copy-file-list.txt"
$fileSettingFile = "copy-file-setting.txt"
$fileLogFile = "copy-file-log.txt"
$autoFunc = $null
$script:success = $false
$script:total = 0

function Test1 {
    Write-Host "Test1"

    $files = (.\adb shell ls /sdcard/test 2>&1)
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Exception caught."
    }
    Write-Host $files

}

function Get-AdbDir {
    param([String]$sourceDir, [String]$depth)

    ($dirList = .\adb shell find $sourceDir -mindepth 1 -maxdepth $depth -type d 2>&1) | Out-File $dirListFile -Encoding utf8
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Get Dir Error: $sourceDir"
     
        # if (Test-Path $dirListFile) {
        #     Remove-Item $dirListFile
        # }

        return
    }    

    Write-Host "Get Dir Done: $dirListFile $($dirList.Count)"
}

function Get-AdbFileCount {
    param([String]$sourceDir)

    $fileList = .\adb shell find $sourceDir -mindepth 1 -maxdepth 1 -type f

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Faild to create FileList"
        $script:success = $false
        return
    }

    $script:total += $fileList.Count
    $script:success = $true
    Write-Host "Files: $script:total `t $($fileList.Count) `t $sourceDir"
}

function Clear-AdbDir {
    if (Test-Path $dirListFile) {
        Remove-Item $dirListFile
    }
    
    if (Test-Path $dirSettingFile) {
        Remove-Item $dirSettingFile
    }

    if (Test-Path $fileListFile) {
        Remove-Item $fileListFile
    }

    if (Test-Path $fileSettingFile) {
        Remove-Item $fileSettingFile
    }
}

function Copy-AdbAuto {
    param([String]$sourceDir, [String]$check, [String]$sleep)

    while (-not $script:success) {
        Try {
            Copy-AdbDir -sourceDir $sourceDir -check $check
        }
        Catch {
            Write-Warning "Wait..."
        } 
        Finally {
            Start-Sleep -Seconds $sleep
        }
    }
}

function Copy-AdbDir {
    param([String]$sourceDir, [String]$check)
    
    $isRightPlace = $false
    $dirList = @()
    $dirSetting =
    $script:success = $false

    $devices = .\adb devices
    if (!($devices -match "device$")) {
        Write-Warning "Cant connect Android device"
        $script:success = $false
        return
    }

    if (Test-Path $dirListFile) {
        $dirList = Get-Content $dirListFile        
    }
    else { 
        ($dirList = .\adb shell find $sourceDir -mindepth 1 -maxdepth 100 -type d) | Out-File $dirListFile -Encoding utf8
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Create DirList Error: $dirListFile"

            if (Test-Path $dirListFile) {
                Remove-Item $dirListFile
            }

            $script:success = $false
            return
        }        
    } 

    if (Test-Path $dirSettingFile) {
        $dirSetting = Get-Content $dirSettingFile
    }
    else {
        $isRightPlace = $true
    }

    if ($dirSetting -eq "Done") {
        $script:success = $true
        Write-Host "Copy Dir Done!"
        return
    }

    ForEach ($dir in $dirList) {        
        if ($dir -eq $dirSetting) {            
            $isRightPlace = $true
        }

        if (-not $isRightPlace) {
            continue
        }

        try {
            & $autoFunc -sourceDir $dir -check $check
        }
        catch {
            $script:success = $false
            Write-Warning "Dir Error: $dir"
        }

        if (-not $script:success) {
            $dir | Out-File $dirSettingFile -Encoding utf8
            return
        }
    }

    $script:success = $true
    "Done" | Out-File $dirSettingFile -Encoding utf8
    Write-Host "Copy Dir Done!"
}



function Copy-AdbFile {
    param([String]$sourceDir, [String]$check)

    $isRightPlace = $false
    $fileList = @()
    $fileSetting =
    $targetDir = ".$sourceDir"

    # $devices = .\adb devices
    # if (!($devices -match "device$")) {
    #     Write-Warning "Cant connect Android device"
    #     $script:success = $false
    #     return
    # }

    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory 
    }


    if (Test-Path $fileListFile) {
        $fileList = Get-Content $fileListFile        
    }
    else { 
        ($fileList = .\adb shell find $sourceDir -mindepth 1 -maxdepth 1 -type f) | Out-File $fileListFile -Encoding utf8

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Create FileList Error: $fileListFile"

            if (Test-Path $fileListFile) {
                Remove-Item $fileListFile
            }

            $script:success = $false
            return
        }
    } 

    if (Test-Path $fileSettingFile) {
        $fileSetting = Get-Content $fileSettingFile        
    }
    else {
        $isRightPlace = $true
    }

    ForEach ($file in $fileList) {
        if ($file -eq $fileSetting) {
            $isRightPlace = $true
        }

        if (-not $isRightPlace) {
            continue
        }

        $fileName = $file | Split-Path -Leaf
        $targetFile = "$targetDir/$fileName"

        if ($check -eq "true") {
            if (-not (Test-Path $targetFile)) {
                $targetFile | Out-File $fileLogFile -Encoding utf8 -Append
                .\adb pull $file $targetFile 2>&1
            }
        }
        else {
            .\adb pull $file $targetFile 2>&1
        }        

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Copy Error: $file $script:total"
            $file | Out-File $fileSettingFile -Encoding utf8

            if (Test-Path $targetFile) {
                Remove-Item $targetFile
            }

            $script:success = $false
            return
        }

        $script:total++
    }
    
    if (Test-Path $fileListFile) {
        Remove-Item $fileListFile
    }

    if (Test-Path $fileSettingFile) {
        Remove-Item $fileSettingFile
    }
    
    $script:success = $true
    Write-Host "Copy Done: $sourceDir $script:total"
}

switch ($cmd) {
    "auto" {
        $autoFunc = "Copy-AdbFile"
        Copy-AdbAuto -sourceDir $sourceDir -check $check -sleep $sleep 
    }
    "count" {
        $autoFunc = "Get-AdbFileCount"
        Copy-AdbAuto -sourceDir $sourceDir -sleep $sleep
    }
    "list" {
        Get-AdbDir -sourceDir $sourceDir -depth $depth
    }
    "dir" {
        Copy-AdbDir -sourceDir $sourceDir -check $check
    }
    "file" {
        Copy-AdbFile -sourceDir $sourceDir -check $check
    }
    "clear" {
        Clear-AdbDir
    }
    "test" {
        Test1
    }
    default {
        Write-Host "CopyAdb v1.0
Copy Android file to PC via Adb which support breakpoint transfer by file unit: 
    -cmd auto|count|list|dir|file|clear -sourceDir /sdcard/yourdir [-check bool|-sleep seconds|-depth dirDepth]
        -cmd: command
        -sourceDir: source dir in Android
        -check: copy only non-existent files
        -sleep: retry sleep seconds after dissconnect
        -depth: list dir depth
Exmples:
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
"
    }
}