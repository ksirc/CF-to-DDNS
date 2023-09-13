## CF-to-DDNS (CTD)
> ### CF 自建 DDNS

为了方便各位小伙伴做动态域名转发，自己编写一份基于CloudFlare的自建DDNS脚本 (这里感谢另一个作者 [@yulewang](https://github.com/yulewang/cloudflare-api-v4-ddns) 提供的开源代码参考)

目前代码还在不断完善，为了大家方便使用，将不断优化逻辑和增加不同平台

欢迎各位小伙伴提出意见和建议！

---

## 使用方法
> ### PC版

使用 *PowerShell* 运行下方命令：

    wget -O https://raw.githubusercontent.com/ksirc/CF-to-DDNS/main/pc/ctd.ps1

运行脚本： `pwsh ctd.sh`

## 配置文件
> ### Config.ini
首次运行脚本会生成配置文件，后续需要更改配置参考如下信息

    # Key 自行前往 https://dash.cloudflare.com/profile/api-tokens 创建令牌，不可用Global API Key
    Key=sEZ************kq3

    # ZoneName 填写你的主域名，也就是一级域名(xxx.eu.org也是一级域名)
    ZoneName=test.eu.org

    # RecordName 填写记录名，也就是域名前缀(例如：www、test、@、abc等，不可填写完整域名！)
    RecordName=pc

    # RecordType 填写 'A' 或 'AAAA'，也就是记录IPv4填 'A' ,IPv6填 'AAAA'
    RecordType=AAAA

    # TTL 记录时间，由于解析的是动态IP，时间就填短一点，默认60就好
    TTL=60

    # Force 是否强制更新解析IP，false否 ture是，推荐flase
    Force=False

    # WANIPSite 用于获取你的当前IP的网址，获取IPv4：https://ipv4.icanhazip.com/   获取IPv6：https://ipv6.icanhazip.com/
    WANIPSite=https://ipv6.icanhazip.com/

## 常见问题
