#!/usr/bin/env pwsh
# 配置文件(config.ini)

##  里面的内容修改成你自己的，(如果手抖把格式误改了删掉重新运行即可生成正确格式)

##  'Key' 自行前往 https://dash.cloudflare.com/profile/api-tokens 创建令牌，不可用Global API Key

##  'ZoneName' 填写你的主域名，也就是一级域名(xxx.eu.org也是一级域名)

##  'RecordName' 填写记录名，也就是域名前缀(例如：www、test、@、abc等，不可填写完整域名！)

##  'RecordType' 填写 'A' 或 'AAAA'，也就是记录IPv4填 'A' ,IPv6填 'AAAA'

##  'TTL' 记录时间，由于解析的是动态IP，时间就填短一点，默认60就好

##  'Force' 是否强制更新解析IP，false否 ture是，推荐flase

##  WANIPSite 用于获取你的当前IP的网址，获取IPv4：https://ipv4.icanhazip.com/   获取IPv6：https://ipv6.icanhazip.com/

if (!(Test-Path -Path .\config.ini)) {
    #要求用户输入一个值，并将其存储在变量中
    $CFKey = Read-Host "请输入CFKey"
    $CFZoneName = Read-Host "请输入CFZoneName"
    $CFRecordName = Read-Host "请输入CFRecordName"

    $CFRecordType = "AAAA"
    $CFTTL = 60
    $Force = $false
    $WANIPSite = "https://ipv6.icanhazip.com/"
    #写入配置文件
    $Config = @"
[CF]
# API Key, 请参考 https://dash.cloudflare.com/profile/api-tokens
Key=$CFKey

# 主域名，例：test.com
ZoneName=$CFZoneName

# 记录名，例：www
RecordName=$CFRecordName

# 记录类型，A 或 AAAA
RecordType=$CFRecordType

# TTL 60就好
TTL=$CFTTL

# 是否强制刷新，推荐false
Force=$Force

# 获取外网IP的网站，推荐 https://ipv6.icanhazip.com/
WANIPSite=$WANIPSite
"@
    $Config | Out-File -FilePath config.ini -Encoding utf8
}


else {
    #读取配置文件config.ini
    $Config = Get-Content -Path config.ini
    $CFKey = $Config.Split("`n") | Select-String "Key" | Select-Object -ExpandProperty Line
    $CFKey = $CFKey.Split("=") | Select-Object -Last 1
    $CFZoneName = $Config.Split("`n") | Select-String "ZoneName" | Select-Object -ExpandProperty Line
    $CFZoneName = $CFZoneName.Split("=") | Select-Object -Last 1
    $CFRecordName = $Config.Split("`n") | Select-String "RecordName" | Select-Object -ExpandProperty Line
    $CFRecordName = $CFRecordName.Split("=") | Select-Object -Last 1
    $CFRecordType = $Config.Split("`n") | Select-String "RecordType" | Select-Object -ExpandProperty Line
    $CFRecordType = $CFRecordType.Split("=") | Select-Object -Last 1
    $CFTTL = $Config.Split("`n") | Select-String "TTL" | Select-Object -ExpandProperty Line
    $CFTTL = $CFTTL.Split("=") | Select-Object -Last 1
    $WANIPSite = $Config.Split("`n") | Select-String "WANIPSite" | Select-Object -ExpandProperty Line
    $WANIPSite = $WANIPSite.Split("=") | Select-Object -Last 1
}

if ($CFRecordType -ne "A" -and $CFRecordType -ne "AAAA") {
    Write-Error "记录类型仅 A(IPv4) 或 AAAA(IPv6)"
    exit 2
}

if ($CFRecordName -notmatch "^$CFZoneName$") {
    $CFRecordName = "$CFRecordName.$CFZoneName"
    Write-Information "=> 你的域名是： $CFRecordName"
}

$WAN_IP = Invoke-WebRequest -Uri $WANIPSite -Method Get | Select-Object -ExpandProperty Content
Write-Host "=> 你的公网IP是：$WAN_IP"

$WAN_IP_File = "./ip/$CFRecordName.txt"
if (Test-Path $WAN_IP_File) {
    $OLD_WAN_IP = Get-Content -Path $WAN_IP_File -TotalCount 1
write-host "=> 之前记录的IP是：$OLD_WAN_IP"
}
else {
    #创建一个名为 ip 的路径
    New-Item -ItemType Directory -Force -Path "./ip"
    Write-Warning "=> 没有IP记录，正在记录。。。"
    $OLD_WAN_IP = ""
}
if ($WAN_IP.Trim(" .-`t`n`r") -like $OLD_WAN_IP.Trim(" .-`t`n`r") ) {
    Write-Warning "=> 你的IP没有变化，无需更新"
    exit 0
}

$CFZoneID = (Invoke-WebRequest -Uri "https://api.cloudflare.com/client/v4/zones?name=$CFZoneName" -Headers @{
        "Authorization" = "Bearer $CFKey"
        "Content-Type"  = "application/json"
    }).Content | ConvertFrom-Json
$CFZoneID = $CFZoneID.result.id

$CFRecordID = (Invoke-WebRequest -Uri "https://api.cloudflare.com/client/v4/zones/$CFZoneID/dns_records?name=$CFRecordName" -Headers @{
        "Authorization" = "Bearer $CFKey"
        "Content-Type"  = "application/json"
    }).Content | ConvertFrom-Json
$CFRecordID = $CFRecordID.result.id

if ($CFZoneID -and $CFRecordID) {
    Invoke-WebRequest -Uri "https://api.cloudflare.com/client/v4/zones/$CFZoneID/dns_records/$CFRecordID" -Method PUT -Headers @{
        "Authorization" = "Bearer $CFKey"
        "Content-Type"  = "application/json"
    } -Body (@{
            "id"      = $CFZoneID
            "type"    = $CFRecordType
            "name"    = $CFRecordName
            "content" = $WAN_IP
            "ttl"     = $CFTTL
        } | ConvertTo-Json)

    if ($?) {
        Write-Host "IP记录成功！"
        Set-Content -Path $WAN_IP_File -Value $WAN_IP
        exit
    }
    else {
        Write-Error '遇到一个错误 :('
        exit 1
    }
}
else {
    Write-Error "Updating zone_identifier & record_identifier"
    exit 1
}
