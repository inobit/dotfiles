# systemd 快捷操作 — 统一入口
# 用法: sc <action> [service...]
#   action: start|s  stop|x  restart|r  reload|re  enable|u  disable|d  status|i  list|l
# 示例:
#   sc s nginx          → sudo systemctl start nginx
#   sc x nginx sshd     → sudo systemctl stop nginx sshd
#   sc re nginx         → sudo systemctl reload nginx
#   sc i nginx          → systemctl status nginx (无需 sudo)
#   sc l                → systemctl list-units
#   sc l -a             → systemctl list-units --all
#   sc l -A             → systemctl list-unit-files
#   sc l -t socket      → 指定类型

sc() {
	[[ $# -eq 0 ]] && {
		cat >&2 <<'EOF'
Usage: sc <action> [service...]

Actions:
  start|s     Start service(s)
  stop|x      Stop service(s)
  restart|r   Restart service(s)
  reload|re   Reload service(s)
  enable|u    Enable service(s)
  disable|d   Disable service(s)
  status|i    Status of service(s)  (no sudo)
  list|l      List units  (supports -a / -A / -t <type>)
EOF
		return 1
	}

	local action=""
	case "$1" in
	start|s)    action=start   ;;
	stop|x)     action=stop    ;;
	restart|r)  action=restart ;;
	reload|re)  action=reload  ;;
	enable|u)   action=enable  ;;
	disable|d)  action=disable ;;
	status|i)   action=status  ;;
	list|l)     action=list    ;;
	*)
		echo "sc: unknown action '$1'" >&2
		echo "Valid: start|s stop|x restart|r reload|re enable|u disable|d status|i list|l" >&2
		return 1
		;;
	esac
	shift

	# list 有自己的选项解析
	if [[ "$action" == "list" ]]; then
		local all="" files="" type="service"
		while [[ $# -gt 0 ]]; do
		case "$1" in
		-a) all="--all" ;;
		-A) files="1" ;;
		-t)
			[[ -z "$2" || "$2" == -* ]] && {
				echo "sc list: -t requires a type value" >&2
				return 1
			}
			type="$2"
			shift
			;;
		*)
			echo "Usage: sc list [-a] [-A] [-t <type>]" >&2
			return 1
			;;
		esac
		shift
		done
		if [[ -n "$files" ]]; then
			systemctl list-unit-files --type="$type" $all
		else
			systemctl list-units --type="$type" $all
		fi
		return $?
	fi

	# 其余 action 需要服务名
	[[ $# -eq 0 ]] && {
		echo "sc $action: missing service name" >&2
		return 1
	}

	if [[ "$action" == "status" ]]; then
		systemctl status "$@"
	else
		sudo systemctl "$action" "$@"
	fi
}
