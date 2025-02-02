# User management

This folder provides several script to manage users for the different supported VPN interfaces

## Installation

### Prerequisites

* Python 3
* Pip (python package installer)

### Installation steps

#### 1. Clone repository
```bash
git clone https://github.com/DobbyVPN/DobbyVPN-server.git
cd DobbyVPN-server
```

#### 2. Install required python libraries

```bash
pip install users/requirements.txt
```

## Run

For each supported vpn interface there is separate `.py` script, that should be run at the root repository directory.
Scripts have the same call arguments format:

```bash
python3 users/<vpn interface>_management.py ARGS
```

`ARGS` defines command and required parameters

### Supported commands

#### Add key command

Add keys to the VPN to the provided user.

```
ARGS=add <user name>
```

#### Delete key command

Remove keys from the VPN for the provided user.

```
ARGS=del <user name>
```

#### List keys

Print all user keys if the user is given, othervise prints all keys

```
ARGS=list <optional user name>
```

## Supported VPNs

* Outline VPN
* AmneziaWG
