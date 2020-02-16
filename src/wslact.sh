version="01"

help_short="wslact [flags] [command] ..."

function gen_startup {
	local help_short="wslact gen_startup [-S <Service> | <Command> ]\n\nGenerate a WSL startup Task using Windows Task Schduler."
	isService=0
	name=""
	nname=""
	while [ "$1" != "" ]; do
		case "$1" in
			-S|--service) isService=1; shift;;
			-h|--help) help "wslact" "$help_short"; exit;;
			*) name="$*";break;;
		esac
	done

	if [[ "$name" != "" ]]; then
		tmp_location="$(wslvar -s TMP)"
		up_location="$(wslvar -s USERPROFILE)"
		tpath="$(double_dash_p "$tmp_location")" # Windows Temp, Win Double Sty.
		tpath_linux="$(wslpath "$tmp_location")" # Windows Temp, Linux WSL Sty.
		script_location="$(wslpath "$up_location")/wslu" # Windows wslu, Linux WSL Sty.
		script_location_win="$up_location\\wslu" #  Windows wslu, Win Double Sty.

		# Check presence of sudo.ps1 and 
		wslu_file_check "$script_location" "sudo.ps1"
		wslu_file_check "$script_location" "runHidden.vbs"

		# check if it is a service or a 
		if [[ $isService -eq 1 ]]; then
			nname="wsl.exe -d $WSL_DISTRO_NAME -u root service $name start"
		else
			echo # TODO: handle normåal command
		fi

		echo "Import-Module 'C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\Modules\\Microsoft.PowerShell.Utility\\Microsoft.PowerShell.Utility.psd1'; \$action = New-ScheduledTaskAction -Execute 'C:\\Windows\\System32\\wscript.exe'  -Argument '$script_location_win\\runHidden.vbs $nname'; \$trigger =  New-ScheduledTaskTrigger -AtLogOn -User \$env:userdomain\\\$env:username; \$task = New-ScheduledTask -Action \$action -Trigger \$trigger -Description \"Start service $name from $WSL_DISTRO_NAME when computer start up; Generated By WSL Utilities\"; Register-ScheduledTask -InputObject \$task -TaskPath '\\' -TaskName 'WSLUtilities_Actions_Startup_$name';" > "$(wslpath "$(wslvar -s TMP)")"/tmp.ps1
		echo "${warn} WSL Utilities is adding $name to Task Scheduler; A UAC Prompt will show up later. Allow it if you know what you are doing."
		if winps_exec "$script_location_win"\\sudo.ps1 "$tpath"\\tmp.ps1; then
			rm -rf "$tpath_linux/tmp.ps1"
			echo "${info} Startup added."

		else
			rm -rf "$tpath_linux/tmp.ps1"
			echo "${error} Adding Startup failed."
			exit 1
		fi
	else
		echo "${error} No input, aborting"
		exit 21
	fi

	unset name
	unset nname
}

function time_sync {

	while [ "$1" != "" ]; do
		case "$1" in
			-h|--help) help "wslact" "$help_short"; exit;;
			*) echo "${error} Invalid Input. Aborted."; exit 22;;
		esac
	done
	echo "${info} Before Sync: $(date +"%d %b %Y %T %Z")"
	if sudo date -s "$(winps_exec "Get-Date -UFormat \"%d %b %Y %T %Z\"" | tr -d "\r")" >/dev/null; then
		echo "${info} After Sync: $(date +"%d %b %Y %T %Z")"
		echo "${info} Manual Time Sync Complete."
	else
		echo "${error} Time Sync failed."
		exit 1
	fi
}


while [ "$1" != "" ]; do
	case "$1" in
		gen-startup) shift; gen_startup "$@"; exit;;
		time-sync) time_sync; exit;;
		-h|--help) help "$0" "$help_short"; exit;;
		-v|--version) echo "wslu v$wslu_version; wslact v$version"; exit;;
		*) echo "${error} Invalid Input. Aborted."; exit 22;;
	esac
done