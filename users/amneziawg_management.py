import re
import sys
import json
import decouple

from awg.awg import InterfaceConfig, PeerConfig, AmneziaWGConfig


AWG_CONFIG = "awg/wg0.conf"


def print_help():
	program_name = sys.argv[0]
	help_message = f"""python3 {program_name} help
	prints script informations
python3 {program_name} add <user_name>
	add new user key
python3 {program_name} list [user_name]
	print list of all user keys or list of all possible keys if no user name provided
python3 {program_name} del <user_name>
	remove user keys"""

	print(help_message)

def help_command(arguments):
	print_help()

	if len(arguments) > 0:
		exit(1)
	else:
		exit(0)

def add_command(arguments):
	if len(arguments) > 1 or len(arguments) == 0:
		print_help()
		exit(1)
	else:
		user_name = arguments[0]
		config = AmneziaWGConfig.from_file(AWG_CONFIG)
		config.add_key(user_name)
		config.dump_to(AWG_CONFIG)

def del_command(arguments):
	if len(arguments) > 1 or len(arguments) == 0:
		print_help()
		exit(1)
	else:
		user_name = arguments[0]
		config = AmneziaWGConfig.from_file(AWG_CONFIG)
		config.del_key(user_name)
		config.dump_to(AWG_CONFIG)

def list_command(arguments):
	if len(arguments) == 1:
		user_name = arguments[0]
		config = AmneziaWGConfig.from_file(AWG_CONFIG)
		result = []

		for peer in config.peers:
			if peer.name == user_name:
				key_dict = {
					"server_config": peer.server_config(),
					"client_config": peer.client_config(config.interface)
				}

				result.append(key_dict)

		result_dics = {
			"type": f"user {user_name}",
			"keys": result
		}

		print(json.dumps(result_dics, indent=4))
	elif len(arguments) == 0:
		config = AmneziaWGConfig.from_file(AWG_CONFIG)
		result = []

		for peer in config.peers:
			key_dict = {
				"server_config": peer.server_config(),
				"client_config": peer.client_config(config.interface)
			}

			result.append(key_dict)

		result_dics = {
			"type": "all",
			"keys": result
		}

		print(json.dumps(result_dics, indent=4))
	else:
		print_help()
		exit(1)

SUPPORTED_COMMANDS = {
	"help": help_command,
	"add": add_command,
	"del": del_command,
	"list": list_command,
}

if __name__ == "__main__":
	if len(sys.argv) <= 1:
		print_help()
		exit(1)

	command_name = sys.argv[1]

	if command_name not in SUPPORTED_COMMANDS.keys():
		print_help()
		exit(1)

	SUPPORTED_COMMANDS[command_name](sys.argv[2:])
