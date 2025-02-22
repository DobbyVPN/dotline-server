import re
import sys
import json
import decouple

from typing import List, Optional
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

def key_to_dict(outline_key):
	return {
		"key_id": outline_key.key_id,
		"name": outline_key.name,
		"access_url": outline_key.access_url
	}

def add_command(arguments):
	if len(arguments) > 1 or len(arguments) == 0:
		print_help()
		exit(1)
	else:
		user_name = arguments[0]
		connection_string = decouple.config("OUTLINE_API_LINE")
		search_result = re.search(r"{\"apiUrl\":\"(\S+)\",\"certSha256\":\"(\S.+)\"}", connection_string)

		if search_result is None:
			print("Invalid OUTLINE_API_LINE format")
			exit(1)
		else:
			apiUrl = search_result.group(1)
			certSha256 = search_result.group(2)
			result = add_command_logic(user_name, apiUrl, certSha256)
			print(json.dumps(result, indent=4))

def add_command_logic(user_name: str, apiUrl: str, certSha256: str):
	vpn_interface = OutlineVPN(api_url=apiUrl, cert_sha256=certSha256)
	new_key = vpn_interface.create_key(key_id=None, name=user_name)

	return key_to_dict(new_key)

def del_command(arguments):
	if len(arguments) > 1 or len(arguments) == 0:
		print_help()
		exit(1)
	else:
		user_name = arguments[0]
		connection_string = decouple.config("OUTLINE_API_LINE")
		search_result = re.search(r"{\"apiUrl\":\"(\S+)\",\"certSha256\":\"(\S.+)\"}", connection_string)

		if search_result is None:
			print("Invalid OUTLINE_API_LINE format")
			exit(1)
		else:
			apiUrl = search_result.group(1)
			certSha256 = search_result.group(2)
			result = del_command_logic(user_name, apiUrl, certSha256)
			print(json.dumps(result, indent=4))

def del_command_logic(user_name: str, apiUrl: str, certSha256: str):
	vpn_interface = OutlineVPN(api_url=apiUrl, cert_sha256=certSha256)
	
	keys_list = []

	for key in vpn_interface.get_keys():
		if key.name == user_name:
			keys_list.append(key_to_dict(key))
			vpn_interface.delete_key(key.key_id)

	output_dict = {
		"keys": keys_list
	}

	return output_dict

def list_command(arguments):
	if len(arguments) > 1:
		print_help()
		exit(1)
	
	if len(arguments) == 1:
		user_name = arguments[0]
	else:
		user_name = None

	connection_string = decouple.config("OUTLINE_API_LINE")
	search_result = re.search(r"{\"apiUrl\":\"(\S+)\",\"certSha256\":\"(\S.+)\"}", connection_string)

	if search_result is None:
		print("Invalid OUTLINE_API_LINE format")
		exit(1)
	else:
		apiUrl = search_result.group(1)
		certSha256 = search_result.group(2)
		result = list_command_logic(user_name, apiUrl, certSha256)
		print(json.dumps(result, indent=4))

def list_command_logic(user_name: Optional[str], apiUrl: str, certSha256: str):
	vpn_interface = OutlineVPN(api_url=apiUrl, cert_sha256=certSha256)
	
	keys_list = []

	for key in vpn_interface.get_keys():
		if user_name is None or key.name == user_name:
			keys_list.append(key_to_dict(key))

	output_dict = {
		"description": "All keys" if user_name is None else f"Keys for user \"{user_name}\"",
		"keys": keys_list
	}

	return output_dict

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
