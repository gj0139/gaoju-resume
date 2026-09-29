# 简历网站一键更新发布脚本
# 用法：双击 publish.cmd，或在 PowerShell 中执行本文件
$ErrorActionPreference = "Stop"

# 1) 把便携版 git / gh 加入本次会话 PATH
$env:Path = "$env:LOCALAPPDATA\Programs\MinGit\cmd;$env:LOCALAPPDATA\Programs\gh\bin;$env:Path"

# 2) 读取系统代理（GitHub 主站需走代理才能推送）
$proxy = ""
try {
  $is = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
  if ($is.ProxyEnable -eq 1 -and $is.ProxyServer) {
    $first = ($is.ProxyServer -split '[,;]')[0].Trim()
    if ($first -notmatch '^https?://') { $first = "http://$first" }
    $proxy = $first
  }
} catch {}
if (-not $proxy) { $proxy = "http://127.0.0.1:12334" }
$env:HTTPS_PROXY = $proxy; $env:HTTP_PROXY = $proxy
$env:https_proxy = $proxy; $env:http_proxy = $proxy
Write-Host "代理: $proxy"

# 3) 进入网站目录
Set-Location -Path $PSScriptRoot
Write-Host "目录: $PSScriptRoot"

# 4) 检查登录状态
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "[错误] GitHub 未登录，请先执行: gh auth login" -ForegroundColor Red
  exit 1
}

# 5) 有改动才提交
git add -A
$status = git status --porcelain
if (-not $status) {
  Write-Host "没有需要提交的改动，网站已是最新。" -ForegroundColor Yellow
  exit 0
}
Write-Host "检测到改动:"
Write-Output $status

$msg = "更新简历内容 $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git -c user.name="gj0139" -c user.email="gj0139@users.noreply.github.com" commit -m $msg
if ($LASTEXITCODE -ne 0) { Write-Host "[错误] 提交失败" -ForegroundColor Red; exit 1 }

# 6) 推送到 GitHub（用 gh 的凭据，不改动全局 git 配置）
git -c credential.helper= -c "credential.helper=!gh auth git-credential" push
if ($LASTEXITCODE -ne 0) { Write-Host "[错误] 推送失败" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "推送成功！GitHub Pages 约 1 分钟后自动更新" -ForegroundColor Green
Write-Host "预览地址: https://gj0139.github.io/gaoju-resume/"
