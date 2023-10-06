#!/usr/bin/python3
import requests
import json
import os

CONFIG_FILE = './config.json'

def get_public_ip():
    response = requests.get('https://api64.ipify.org?format=json')
    ip = json.loads(response.text)['ip']
    return ip

def update_dns_record(ip, api_key, email, domain, zone_id):
    url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records?type=AAAA&name={domain}"
    headers = {
        'X-Auth-Email': email,
        'X-Auth-Key': api_key,
        'Content-Type': 'application/json'
    }
    print("正在记录...")
    response = requests.get(url, headers=headers)
    result = json.loads(response.text)['result'][0]
    record_id = result['id']
    old_ip = result['content']
    if old_ip != ip:
        url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{record_id}"
        data = {
            'type': 'AAAA',
            'name': domain,
            'content': ip,
            'ttl': 1,
            'proxied': False
        }
        response = requests.put(url, headers=headers, data=json.dumps(data))
        if response.status_code == 200:
            print(f"更新成功 {domain} to {ip}")
        else:
            print(f"更新错误 {domain} to {ip}")
    else:
        print("IP没有变化")

def get_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
    else:
        config = {}
        config['api_key'] = input("请输入你的 Cloudflare API Key: ")
        config['email'] = input("请输入你的 Cloudflare 邮箱地址: ")
        config['domain'] = input("请输入你想要更新的域名: ")
        config['zone_id'] = input("请输入你的域名的 Zone ID: ")
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f)
    return config

def main():
    config = get_config()
    ip = get_public_ip()
    update_dns_record(ip, config['api_key'], config['email'], config['domain'], config['zone_id'])

if __name__ == "__main__":
    main()
