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

AWG

Adding user to AWG (in file `awg/wg0.conf`, only 3 lines per user):

```bash
[Peer]
PublicKey = ...
AllowedIPs = 10.0.0.<x>/32
```

`[interface]` is filled so:

```bash
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = ...
Jc = ...
Jmin = ...
Jmax = ...
S1 = ...
S2 = ...
H1 = ...
H2 = ...
H3 = ...
H4 = ...

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```
All random values are generated according to rules of AmneziaWG. Public and private keys from awg server are located in `.env` file.

Environment variables are stored in `.env` file, all log information in `logs.txt` file.
Installation script: `setup.sh`. It works in an interactive mode without having to enter params via cli keys.

Warning: `setup.sh` should be executed at most once on one server, each execution after first one causes undefined behaviour.

