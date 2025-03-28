# Dobby VPN server

Run VPN server on the machine.

## Setup:

```bash
git clone https://github.com/DobbyVPN/DobbyVPN-server.git
cd DobbyVPN-server
./setup.sh
```

## Documentation

* [How to run AmneziaWG server](./docs/AWG_VPS_SERVER_RUN.md)
* [Additional docker images](./docs/DOCKER_IMAGES.md)
* [User keys management](./docs/USER_MANAGEMENT_SCRIPTS.md)

## Outline

You will be asked to enter a domain name.

A domain name must be purchased in advance and assigned to your server's IP address.

## Cloak

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

## AWG

### Config modifications:

Adding user to AWG (in file `awg/wg0.conf`, only 3 lines per user):

```bash
[Peer]
PublicKey = ...
AllowedIPs = 10.9.9.<x>/32
```

`[interface]` is filled so:

```bash
[Interface]
PrivateKey = ...
ListenPort = ...
Address = 10.9.9.1/32
Jc = ...
Jmin = ...
Jmax = ...
S1 = ...
S2 = ...
H1 = ...
H2 = ...
H3 = ...
H4 = ...

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

AWG specific params (Jc, Jmin, Jmax, S1, S2, H1, H2, H3, H4) are located in `.env` file.

Environment variables are stored in `.env` file, all log information in `logs.txt` file.
Installation script: `setup.sh`. It works in an interactive mode without having to enter params via cli keys.

Warning: `setup.sh` should be executed at most once on one server, each execution after first one causes undefined behaviour.

