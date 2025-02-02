import re
import sys
import json
import decouple

from outline_vpn.outline_vpn import OutlineVPN

def print_help():
	program_name = sys.argv[0]
	help_message = f"""python3 {program_name} help
	prints script informations
python3 {program_name} add <user_name>
	add new user to the Outline and return key and cloak client config
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

		# TODO

def del_command(arguments):
	if len(arguments) > 1 or len(arguments) == 0:
		print_help()
		exit(1)
	else:
		user_name = arguments[0]

		# TODO

def list_command(arguments):
	if len(arguments) == 1:
		user_name = arguments[0]
		connection_string = decouple.config("OUTLINE_API_LINE")
		search_result = re.search(r"{\"apiUrl\":\"(\S+)\",\"certSha256\":\"(\S.+)\"}", connection_string)

		if search_result is None:
			print("Invalid OUTLINE_API_LINE format")
			exit(1)
		else:
			apiUrl = search_result.group(1)
			certSha256 = search_result.group(2)
			vpn_interface = OutlineVPN(api_url=apiUrl, cert_sha256=certSha256)
			
			keys_list = []

			for key in vpn_interface.get_keys():
				if key.name == user_name:
					key_dict = {
						"key_id": key.key_id,
						"name": key.name,
						"access_url": key.access_url
					}
					
					keys_list.append(key_dict)

			output_dict = {
				"type": f"user {user_name}",
				"keys": keys_list
			}

			print(json.dumps(output_dict, indent=4))
	elif len(arguments) == 0:
		connection_string = decouple.config("OUTLINE_API_LINE")
		search_result = re.search(r"{\"apiUrl\":\"(\S+)\",\"certSha256\":\"(\S.+)\"}", connection_string)

		if search_result is None:
			print("Invalid OUTLINE_API_LINE format")
			exit(1)
		else:
			apiUrl = search_result.group(1)
			certSha256 = search_result.group(2)
			vpn_interface = OutlineVPN(api_url=apiUrl, cert_sha256=certSha256)
			
			keys_list = []

			for key in vpn_interface.get_keys():
				key_dict = {
					"key_id": key.key_id,
					"name": key.name,
					"access_url": key.access_url
				}

				keys_list.append(key_dict)

			output_dict = {
				"type": "all",
				"keys": keys_list
			}

			print(json.dumps(output_dict, indent=4))
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
