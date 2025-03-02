# User management scripts

Additional python scripts inside server docker images to modify user keys

## Functionality

* List all/user keys
* Create user key
* Remove user keys

## Supported VPNs

* AmneziaWG VPN (inside [awg-server](../docker/Dockerfile-awg-server) docker image)
* Outline VPN (inside [outline-server](../docker/Dockerfile-outline-server) docker image)

### AmneziaWG VPN commands

#### List all keys:

```bash
docker exec awg-server .venv/bin/python3 usrmngr/main.py list
```

#### List user keys:

```bash
docker exec awg-server .venv/bin/python3 usrmngr/main.py list <User>
```

#### Add key to user:

```bash
docker exec awg-server .venv/bin/python3 usrmngr/main.py add <User>
```

#### Delete user keys:

```bash
docker exec awg-server .venv/bin/python3 usrmngr/main.py del <User>
```

#### Get server log:

```bash
docker exec awg-server cat awg.log
```

### Outline VPN commands

#### List all keys:

```bash
docker exec outline-server .venv/bin/python3 usrmngr/main.py list
```

#### List user keys:

```bash
docker exec outline-server .venv/bin/python3 usrmngr/main.py list <User>
```

#### Add key to user:

```bash
docker exec outline-server .venv/bin/python3 usrmngr/main.py add <User>
```

#### Delete user keys:

```bash
docker exec outline-server .venv/bin/python3 usrmngr/main.py del <User>
```
