@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

rem ================================================================
rem  書籤一鍵安裝程式
rem  支援：Google Chrome、Microsoft Edge、Mozilla Firefox
rem ================================================================
rem  使用說明：
rem  1. 修改下方 BM_NAME 為書籤顯示名稱
rem  2. 將 URL_START 下一行換成你的 javascript:...
rem  3. 雙擊執行（瀏覽器會自動強制關閉再重開）
rem ================================================================

rem ▼ 修改書籤名稱 ▼
set "BM_NAME=✏Phab Editor"
rem ▲ 修改書籤名稱 ▲

goto :MAIN

rem :::URL_START:::
javascript:void(0); rem placeholder - replaced by convert.py with the real bookmarklet
rem :::URL_END:::

rem :::PS_START:::
$batPath = $env:BAT_PATH
$choice  = [int]$env:BM_CHOICE
$lines   = [IO.File]::ReadAllLines($batPath, [Text.Encoding]::UTF8)

$bmName = ""
foreach ($line in $lines) {
    if ($line -match '^set "BM_NAME=(.+)"') { $bmName = $matches[1]; break }
}
$si = 0
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match ':::URL_START:::') { $si = $i + 1; break }
}
$bmUrl = $lines[$si].Trim()

$py = Get-Command python  -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }

$installedBrowsers = [System.Collections.Generic.List[string]]::new()
$script:firstRunGuideShown = $false

function Show-FirstRunGuide($browserName) {
    if ($script:firstRunGuideShown) { return }
    $script:firstRunGuideShown = $true
    Write-Host "" 
    Write-Host "  [教學] $browserName 可能是首次使用，尚未建立書籤/設定檔。" -ForegroundColor Yellow
    Write-Host "  [教學] 請依序操作：" -ForegroundColor Yellow
    Write-Host "    1) 關閉本安裝程式" -ForegroundColor Yellow
    Write-Host "    2) 手動開啟 $browserName 一次" -ForegroundColor Yellow
    Write-Host "    3) 新增任意一個暫時書籤" -ForegroundColor Yellow
    Write-Host "    4) 完全關閉瀏覽器" -ForegroundColor Yellow
    Write-Host "    5) 重新執行 install-phab-editor.bat" -ForegroundColor Yellow
    Write-Host "" 
}

function Close-Browser($procName, $displayName) {
    $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($procs) {
        Write-Host "  正在關閉 $displayName..." -ForegroundColor Cyan
        Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $still = Get-Process -Name $procName -ErrorAction SilentlyContinue
        if ($still) {
            Write-Host "  警告：無法完全關閉 $displayName" -ForegroundColor Yellow
            return $false
        }
        Write-Host "  $displayName 已關閉" -ForegroundColor Green
    }
    return $true
}

function Open-Browser($browserName) {
    Write-Host "  正在開啟 $browserName..." -ForegroundColor Cyan
    $paths = @()
    switch ($browserName) {
        "Chrome" {
            $paths = @(
                "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
                "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
            )
        }
        "Edge" {
            $paths = @(
                "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe",
                "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
                "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
            )
        }
        "Firefox" {
            $paths = @(
                "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
                "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
            )
        }
    }
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Start-Process $p
            Write-Host "  $browserName 已開啟" -ForegroundColor Green
            return
        }
    }
    # Fallback: try by process name
    try { Start-Process $browserName.ToLower(); Write-Host "  $browserName 已開啟" -ForegroundColor Green }
    catch { Write-Host "  找不到 $browserName 執行檔" -ForegroundColor Yellow }
}

$chromePyLines = @(
    "import json, hashlib, time, uuid, os, shutil",
    "bpath = os.environ['_BM_PATH']",
    "bname = os.environ['_BM_NAME']",
    "import io",
    "burl = io.open(os.environ['_BM_URL_FILE'], encoding='utf-8').read()",
    "f = open(bpath, 'r', encoding='utf-8')",
    "data = json.load(f)",
    "f.close()",
    "def get_max_id(node):",
    "    try: m = int(node.get('id', 0))",
    "    except: m = 0",
    "    for c in node.get('children', []): m = max(m, get_max_id(c))",
    "    return m",
    "roots = data['roots']",
    "max_id = 0",
    "for k in ['bookmark_bar','other','synced','mobile']:",
    "    if k in roots: max_id = max(max_id, get_max_id(roots[k]))",
    "ts = str(int((time.time() + 11644473600) * 1000000))",
    "new_bm = {",
    "    'date_added': ts,",
    "    'date_last_used': '0',",
    "    'guid': str(uuid.uuid4()),",
    "    'id': str(max_id + 1),",
    "    'meta_info': {'power_bookmark_meta': ''},",
    "    'name': bname,",
    "    'type': 'url',",
    "    'url': burl",
    "}",
    "bar = roots['bookmark_bar']",
    "def already_in(node, u):",
    "    if node.get('url') == u: return True",
    "    return any(already_in(c, u) for c in node.get('children', []))",
    "if already_in(bar, burl):",
    "    print('ALREADY_INSTALLED'); exit()",
    "if 'children' not in bar: bar['children'] = []",
    "bar['children'].append(new_bm)",
    "bar['date_modified'] = ts",
    "def calc_cs(roots):",
    "    buf = bytearray()",
    "    def add(n):",
    "        buf.extend(n['id'].encode('utf-8'))",
    "        buf.extend(n['name'].encode('utf-8'))",
    "        if n.get('type') == 'url': buf.extend(n['url'].encode('utf-8'))",
    "        for c in n.get('children', []): add(c)",
    "    add(roots['bookmark_bar'])",
    "    add(roots['other'])",
    "    sv = roots.get('synced') or roots.get('mobile')",
    "    if sv: add(sv)",
    "    return hashlib.md5(bytes(buf)).hexdigest()",
    "orig_cs = data.get('checksum','')",
    "data['checksum'] = calc_cs(roots)",
    "out = open(bpath, 'w', encoding='utf-8')",
    "json.dump(data, out, ensure_ascii=False, indent=3)",
    "out.close()",
    "shutil.copy2(bpath, bpath + '.bak')",
    "print('OK:' + str(max_id + 1) + ':' + orig_cs + ':' + data['checksum'])"
)

function Install-Chromium($bName, $bPath) {
    if (-not (Test-Path $bPath)) {
        Write-Host "  [$bName] 找不到書籤檔，跳過" -ForegroundColor Yellow
        Show-FirstRunGuide $bName
        return
    }
    if (-not $py) {
        Write-Host "  [$bName] 需要 Python，請先安裝 Python" -ForegroundColor Yellow
        return
    }
    $tmp = [IO.Path]::GetTempFileName() + ".py"
    [IO.File]::WriteAllLines($tmp, $chromePyLines, [Text.UTF8Encoding]::new($false))
    $tmpUrl = [IO.Path]::GetTempFileName()
    [IO.File]::WriteAllText($tmpUrl, $bmUrl, [Text.UTF8Encoding]::new($false))
    $env:_BM_PATH     = $bPath
    $env:_BM_NAME     = $bmName
    $env:_BM_URL_FILE = $tmpUrl
    $result = & $py.Source $tmp 2>&1
    Remove-Item $tmp     -Force -ErrorAction SilentlyContinue
    Remove-Item $tmpUrl  -Force -ErrorAction SilentlyContinue
    if ("$result" -match "ALREADY_INSTALLED") {
        Write-Host "  [$bName] 已安裝，跳過" -ForegroundColor Cyan
    } elseif ("$result" -match "^OK:(\d+):([^:]*):(.+)$") {
        $id = $matches[1]; $oldCs = $matches[2]; $newCs = $matches[3]
        $csMatch = if ($oldCs -eq "") { "（新建）" } elseif ($oldCs -ne $newCs) { "checksum 已更新" } else { "checksum 未變" }
        Write-Host "  [$bName] 安裝成功 (ID=$id，$csMatch)" -ForegroundColor Green
    } else {
        Write-Host "  [$bName] 失敗：$result" -ForegroundColor Red
    }
}

function Install-BrowserAllProfiles($browserName, $baseDir, $procName) {
    if (-not (Test-Path $baseDir)) {
        Write-Host "  [$browserName] 未安裝，跳過" -ForegroundColor Yellow
        return
    }
    Close-Browser $procName $browserName | Out-Null
    $profiles = Get-ChildItem $baseDir -Directory |
                Where-Object { $_.Name -eq 'Default' -or $_.Name -match '^Profile' }
    if ($profiles.Count -eq 0) {
        Write-Host "  [$browserName] 找不到任何設定檔" -ForegroundColor Yellow
        Show-FirstRunGuide $browserName
        return
    }
    $ok = $false
    foreach ($p in $profiles) {
        $bPath = Join-Path $p.FullName "Bookmarks"
        Install-Chromium "$browserName/$($p.Name)" $bPath
        if (Test-Path $bPath) { $ok = $true }
    }
    if ($ok) { $script:installedBrowsers.Add($browserName) }
}

function Install-Firefox() {
    $base = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (-not (Test-Path $base)) {
        Write-Host "  [Firefox] 未安裝，跳過" -ForegroundColor Yellow
        return
    }
    if (-not $py) {
        Write-Host "  [Firefox] 需要 Python" -ForegroundColor Yellow
        return
    }
    Close-Browser "firefox" "Firefox" | Out-Null
    # 找所有 default 設定檔
    $profiles = Get-ChildItem $base -Directory |
                Where-Object { $_.Name -match 'default' }
    if ($profiles.Count -eq 0) {
        $profiles = Get-ChildItem $base -Directory | Select-Object -First 1
    }
    if ($profiles.Count -eq 0) {
        Write-Host "  [Firefox] 找不到任何設定檔" -ForegroundColor Yellow
        Show-FirstRunGuide "Firefox"
        return
    }
    $ok = $false
    foreach ($profile in $profiles) {
        $db = Join-Path $profile.FullName "places.sqlite"
        if (-not (Test-Path $db)) {
            Write-Host "  [Firefox/$($profile.Name)] places.sqlite 不存在，跳過" -ForegroundColor Yellow
            Show-FirstRunGuide "Firefox/$($profile.Name)"
            continue
        }
        $tmpUrl2 = [IO.Path]::GetTempFileName()
        [IO.File]::WriteAllText($tmpUrl2, $bmUrl, [Text.UTF8Encoding]::new($false))
        $env:_BM_NAME     = $bmName
        $env:_BM_URL_FILE = $tmpUrl2
        $ffPyLines = @(
            "import sqlite3, time, sys, os",
            "db   = r'$db'",
            "burl  = open(os.environ['_BM_URL_FILE'], encoding='utf-8').read()",
            "bname = os.environ['_BM_NAME']",
            "con = sqlite3.connect(db)",
            "con.execute('PRAGMA journal_mode=WAL')",
            "cur = con.cursor()",
            "cur.execute('SELECT id FROM moz_bookmarks WHERE guid=?', ('toolbar_____',))",
            "row = cur.fetchone()",
            "if not row: cur.execute('SELECT id FROM moz_bookmarks WHERE type=2 AND title=?', ('toolbar',))",
            "if not row: row = cur.fetchone()",
            "if not row: cur.execute('SELECT id FROM moz_bookmarks WHERE type=2 LIMIT 1')",
            "if not row: row = cur.fetchone()",
            "tid = row[0] if row else 2",
            "print('toolbar_id=' + str(tid))",
            "cur.execute('SELECT COUNT(*) FROM moz_bookmarks bm JOIN moz_places p ON bm.fk=p.id WHERE p.url=? AND bm.parent=?', (burl, tid))",
            "if cur.fetchone()[0] > 0:",
            "    print('ALREADY_INSTALLED'); con.close(); exit()",
            "ts = int(time.time() * 1000000)",
            "cur.execute('INSERT OR IGNORE INTO moz_places(url,title,visit_count,hidden,typed,frecency) VALUES(?,?,0,0,0,-1)', (burl, bname))",
            "cur.execute('SELECT id FROM moz_places WHERE url=?', (burl,))",
            "row2 = cur.fetchone()",
            "if not row2: sys.exit('ERROR: url not in moz_places')",
            "pid = row2[0]",
            "cur.execute('SELECT COALESCE(MAX(position),0)+1 FROM moz_bookmarks WHERE parent=?', (tid,))",
            "pos = cur.fetchone()[0]",
            "cur.execute('INSERT INTO moz_bookmarks(type,fk,parent,position,title,dateAdded,lastModified) VALUES(1,?,?,?,?,?,?)', (pid,tid,pos,bname,ts,ts))",
            "con.commit()",
            "con.execute('PRAGMA wal_checkpoint(TRUNCATE)')",
            "con.close()",
            "print('OK')"
        )
        $pyCode = $ffPyLines -join "`n"
        $tmp = [IO.Path]::GetTempFileName() + ".py"
        [IO.File]::WriteAllText($tmp, $pyCode, [Text.UTF8Encoding]::new($true))
        $result = & $py.Source $tmp 2>&1
        Remove-Item $tmp     -Force -ErrorAction SilentlyContinue
        Remove-Item $tmpUrl2 -Force -ErrorAction SilentlyContinue
        if ("$result" -match "ALREADY_INSTALLED") {
            Write-Host "  [Firefox/$($profile.Name)] 已安裝，跳過" -ForegroundColor Cyan
            $ok = $true
        } elseif ("$result" -match "OK") {
            Write-Host "  [Firefox/$($profile.Name)] 安裝成功 ($result)" -ForegroundColor Green
            $ok = $true
        } else {
            Write-Host "  [Firefox/$($profile.Name)] 失敗：$result" -ForegroundColor Red
        }
    }
    if ($ok) { $script:installedBrowsers.Add("Firefox") }
}

$localApp = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
if ($choice -eq 1 -or $choice -eq 4) { Install-BrowserAllProfiles "Chrome"  "$localApp\Google\Chrome\User Data"    "chrome"  }
if ($choice -eq 2 -or $choice -eq 4) { Install-BrowserAllProfiles "Edge"    "$localApp\Microsoft\Edge\User Data"    "msedge"  }
if ($choice -eq 3 -or $choice -eq 4) { Install-Firefox }

Write-Host ""
if ($installedBrowsers.Count -gt 0) {
    Write-Host "  安裝完成！正在開啟瀏覽器..." -ForegroundColor White
    Start-Sleep -Seconds 1
    foreach ($b in $installedBrowsers) {
        Open-Browser $b
        Start-Sleep -Milliseconds 500
    }
} else {
    Write-Host "  沒有成功安裝到任何瀏覽器。" -ForegroundColor Yellow
}
Write-Host ""
rem :::PS_END:::

:MAIN
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS%" set "PS=%ProgramFiles%\PowerShell\7\pwsh.exe"
if not exist "%PS%" (echo [錯誤] 找不到 PowerShell. & pause & exit /b 1)

cls
echo.
echo  ==========================================
echo    Phabricator-Editor-Plugin 安裝程式
echo    Support: Chrome / Edge / Firefox
echo  ==========================================
echo.
echo  注意：安裝前會自動強制關閉選擇的瀏覽器
echo.
echo       安裝完成後會自動重新開啟
echo.
echo    請選擇要安裝的瀏覽器：
echo.
echo      1. Google Chrome
echo      2. Microsoft Edge
echo      3. Mozilla Firefox
echo      4. 全部瀏覽器
echo.
choice /c 1234 /n /m "  輸入數字 (1-4)："
set "BM_CHOICE=%ERRORLEVEL%"
set "BAT_PATH=%~f0"

echo.
echo  安裝中，請稍候...
echo.

%PS% -ExecutionPolicy Bypass -NoProfile -Command "$f=[IO.File]::ReadAllLines($env:BAT_PATH,[Text.Encoding]::UTF8); $s=($f|Select-String -SimpleMatch 'rem :::PS_START:::' | Select-Object -First 1).LineNumber; $e=($f|Select-String -SimpleMatch 'rem :::PS_END:::' | Select-Object -First 1).LineNumber; [IO.File]::WriteAllLines($env:TEMP+'\bm_install.ps1',$f[$s..($e-2)],[Text.UTF8Encoding]::new($true))"

%PS% -ExecutionPolicy Bypass -NoProfile -File "%TEMP%\bm_install.ps1"

del "%TEMP%\bm_install.ps1" 2>nul

echo.
pause
endlocal
