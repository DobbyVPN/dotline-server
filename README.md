Setup:

```bash
git clone https://github.com/DobbyVPN/DobbyVPN-server.git
cd DobbyVPN-server
./setup.sh
```

<details>
<summary>Cloak client config</summary>

  ```json
  {
    "Transport": "CDN",
    "ProxyMethod": "shadowsocks",
    "EncryptionMethod": "plain",
    "UID": "<your-UID-here>",
    "PublicKey": "<your-public-key-here>",
    "ServerName": "<your-server-name-here>",
    "NumConn": 8,
    "BrowserSig": "chrome",
    "StreamTimeout": 300,
    "RemoteHost": "<your-remote-host-here>",
    "RemotePort": "<your-remote-port-here>",
    "CDNWsUrlPath": "<your-cdn-ws-url-path-here>",
    "CDNOriginHost": "<your-cdn-origin-host-here>"
  }
  ```
  
  **ServerName** and **CDNWsUrlPath** have the same value, in particular, the domain name.

</details>

<details>
<summary>Xray client config</summary>

```json
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "inboundTag": ["inbound-12345"],
                "outboundTag": "proxy-out-vless"
            }
        ]
    },
    "inbounds": [
        {
            "tag": "inbound-12345",
            "listen": "127.0.0.1", 
            "port": 12345, 
            "protocol": "http",
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        }
    ],
    "outbounds": [
        {
            "tag": "proxy-out-vless",
            "protocol": "vless",
            "settings": {
                "vnext": [
                    {
                        "address": "<your-domain-name>", 
                        "port": 443, 
                        "users": [
                            {
                                "id": "<your-xray-client-uuid>", 
                                "encryption": "none",
                                "flow": "xtls-rprx-vision"
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "serverName": "<your-domain-name>", 
                    "allowInsecure": false,
                    "fingerprint": "chrome" 
                }
            }
        },
        {
            "protocol": "freedom",
            "tag": "direct"
        }
    ]
}
```
</details>

Environment variables are stored in `.env` file, all log information in `logs.txt` file.
Installation script: `setup.sh`. It works in an interactive mode without having to enter params via cli keys.

Warning: `setup.sh` should be executed at most once on one server, each execution after first one causes undefined behaviour.

