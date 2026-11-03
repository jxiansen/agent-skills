# PowerShell 配方

按任务查，不要整段照搬。

## 运行外部程序并取结果

```powershell
$out = & git status --porcelain 2>&1
$code = $LASTEXITCODE
if ($code -ne 0) { throw "git failed ($code): $out" }
```

参数里有空格或引号时用数组：

```powershell
$args = @('--max-time', '20', '-sSL', $url)
& curl.exe @args
```

## JSON

```powershell
$data = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
$data | ConvertTo-Json -Depth 8
```

写文件时显式编码，避免 BOM 差异：

```powershell
$json | Set-Content -LiteralPath $path -Encoding utf8
```

## 查找替换（保留编码）

```powershell
$text = Get-Content -LiteralPath $path -Raw
$text = $text -replace 'old', 'new'
Set-Content -LiteralPath $path -Value $text -Encoding utf8 -NoNewline
```

多个文件：

```powershell
Get-ChildItem -Recurse -Filter *.md | ForEach-Object {
    $t = Get-Content -LiteralPath $_.FullName -Raw
    Set-Content -LiteralPath $_.FullName -Value ($t -replace 'old', 'new') -Encoding utf8 -NoNewline
}
```

## 路径与文件

```powershell
$p = Join-Path $HOME '.config\opencode'
if (Test-Path -LiteralPath $p) { Get-ChildItem -LiteralPath $p }
```

长路径需要系统启用 `LongPathsEnabled`；PS 7 支持，PS 5.1 不一定。

## 进程、端口、服务

```powershell
Get-Process -Name node -ErrorAction SilentlyContinue
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -eq 3425 }
Get-CimInstance Win32_Service -Filter "Name='Spooler'" |
    Select-Object Name, State, StartMode, ProcessId
```

`Get-NetTCPConnection` 在受限环境下可能只看到部分监听项，不要据此断言端口没被占用；用 `netstat -ano` 交叉验证。

## 下载

```powershell
curl.exe -sSL --max-time 20 -o $out $url
```

不要用 `Invoke-WebRequest` 去抓需要流式处理的大文件。

## 环境变量

```powershell
$env:HTTP_PROXY
[Environment]::GetEnvironmentVariable('Path', 'User')
[Environment]::GetEnvironmentVariable('Path', 'Machine')
```

进程级修改只影响当前进程；要持久化用 `[Environment]::SetEnvironmentVariable(..., 'User')`。

## 行尾与 BOM

```powershell
$bytes = [IO.File]::ReadAllBytes($p)
$hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
$text = [IO.File]::ReadAllText($p)
$crlf = ($text -split "`r`n").Count - 1
```

## 输出重定向

```powershell
& some.exe *> $log
```

PS 7 写 UTF-8；PS 5.1 需要 `| Out-File -Encoding utf8 $log` 才能避免 UTF-16。

## 网络与重试

```powershell
curl.exe -sSL --max-time 20 -o $out $url
```

- 第一次失败就换 `curl.exe`，不要反复用 `Invoke-WebRequest`。
- 同一 URL 第二次失败就停，报告而不是继续猜路径。
- GitHub API 的 401 是没带 token，429 是限额；换 `gh`、token 或 `websearch`，不要重试。

## Python 依赖

```powershell
uv run --with pillow python script.py

# 或先探测
python -c "import PIL" 2>$null
if ($LASTEXITCODE -ne 0) { 'PIL missing' }
```

## 输出限量

```powershell
Get-ChildItem -Recurse | Select-Object -First 20
rg -m 5 "pattern" .
& some.exe *> "$env:TEMP\out.log"
(Get-Item "$env:TEMP\out.log").Length
```

## 临时脚本（含中文或多行）

```powershell
$p = Join-Path $env:TEMP 'task.ps1'
@'
# 中文注释可以放心写
Get-ChildItem 'C:\Users' | Select-Object -First 5
'@ | Set-Content -LiteralPath $p -Encoding utf8
pwsh -NoProfile -File $p
```

管道不要留在行尾：`} |` 跨行在部分传输方式下会变成空管道，报 `An empty pipe element is not allowed`。
