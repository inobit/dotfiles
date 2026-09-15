# git_status_open — 按行号或名称正则从 git status 中打开文件（nvim）
# Usage:
#   git_status_open           打开所有已变更文件
#   git_status_open 3         打开第 3 行对应的文件
#   git_status_open -1        打开倒数第 1 个文件
#   git_status_open 1,3,5     打开第 1、3、5 行对应的文件
#   git_status_open -1,-2     打开倒数第 1、2 个文件（最后 2 个）
#   git_status_open 2-5       打开第 2~5 行对应的文件
#   git_status_open -3--1     打开倒数第 3 到倒数第 1 个文件
#   git_status_open -1-1      打开倒数第 1 到第 1 行（即全部）
#   git_status_open foo       打开路径匹配正则 foo 的文件
#   git_status_open '\.md$'   打开所有 Markdown 文件
#
# 建议别名: alias gsn=git_status_open
#
# 在 .zshrc 中 source 即可使用：
#   source ~/ask/git-status-open.sh

git_status_open() {
	# porcelain 输出的是仓库根相对路径，必须拼成绝对路径，
	# 否则在子目录中 nvim 会按当前目录解析而打不开
	local root
	root=$(git rev-parse --show-toplevel 2>/dev/null) || {
		echo "git_status_open: 不在 git 仓库中" >&2
		return 1
	}
	# ---- 帮助函数：将可能为负数的索引转为正向行号 ----
	_to_pos() {
		local n=$1 total=$2
		if (( n < 0 )); then
			echo $(( total + n + 1 ))   # -1 → total, -2 → total-1
		else
			echo $n
		fi
	}
	# ---- 帮助函数：确保有文件可打开 ----
	_ensure_files() {
		local total
		total=$(git status --porcelain | wc -l | tr -d ' ')
		if (( total == 0 )); then
			echo "git_status_open: 没有已变更的文件" >&2
			return 1
		fi
		echo "$total"
	}

	# ---- 帮助函数：porcelain 行 → 根相对路径 ----
	# 去状态位，重命名取新路径，去引号；逐行一对一转换，行号不变
	_relpaths() {
		awk '{
			s = substr($0, 4)
			if ((i = index(s, " -> ")) > 0) s = substr(s, i + 4)
			if (s ~ /^".*"$/) { sub(/^"/, "", s); sub(/"$/, "", s) }
			print s
		}'
	}
	# ---- 帮助函数：根相对路径 → 绝对路径 ----
	_to_abs() {
		awk -v r="$1" '{print r "/" $0}'
	}

	if [[ $# -eq 0 ]]; then
		# 无参数：打开所有文件
		git status --porcelain | _relpaths | _to_abs "$root" | xargs -r -d '\n' -o nvim --

	# === 逗号分隔: n,m（n/m 可为正数或负数）===
	elif [[ "$1" =~ ^(-?[0-9]+)(,-?[0-9]+)+$ ]]; then
		local total
		total=$(_ensure_files) || return 1

		local -a raw_nums pos_arr
		IFS=',' read -rA raw_nums <<< "$1"
		local valid=0
		for n in "${raw_nums[@]}"; do
			local pos
			pos=$(_to_pos "$n" "$total")
			if (( pos >= 1 && pos <= total )); then
				pos_arr+=($pos)
				((valid++))
			fi
		done

		if (( valid == 0 )); then
			echo "git_status_open: 所有索引都超出范围 (共 $total 个文件)" >&2
			return 1
		fi

		local -a sorted
		sorted=($(printf '%d\n' "${pos_arr[@]}" | sort -nu))
		git status --porcelain | awk -v lines=" ${sorted[*]} " 'index(lines, " "NR" ")' \
			| _relpaths | _to_abs "$root" | xargs -r -d '\n' -o nvim --

	# === 范围: n-m（n/m 可为正数或负数）===
	elif [[ "$1" =~ ^(-?[0-9]+)-(-?[0-9]+)$ ]]; then
		local total
		total=$(_ensure_files) || return 1

		local s e
		s=$(_to_pos "${match[1]}" "$total")
		e=$(_to_pos "${match[2]}" "$total")

		# 确保 s ≤ e，且不越界
		if (( s > e )); then local tmp=$s; s=$e; e=$tmp; fi
		(( s < 1 )) && s=1
		(( e > total )) && e=$total

		if (( s > total || e < 1 )); then
			echo "git_status_open: 索引范围 '$1' 超出范围 (共 $total 个文件)" >&2
			return 1
		fi

		git status --porcelain | awk -v s="$s" -v e="$e" 'NR>=s && NR<=e' \
			| _relpaths | _to_abs "$root" | xargs -r -d '\n' -o nvim --

	# === 单数字: n 或 -n ===
	elif [[ "$1" =~ ^-?[0-9]+$ ]]; then
		local total n="$1" pos
		total=$(_ensure_files) || return 1

		pos=$(_to_pos "$n" "$total")
		if (( pos < 1 || pos > total )); then
			echo "git_status_open: 索引 $n 超出范围 (共 $total 个文件)" >&2
			return 1
		fi

		git status --porcelain | awk -v n="$pos" 'NR==n' \
			| _relpaths | _to_abs "$root" | xargs -r -d '\n' -o nvim --

	# === 正则匹配 ===
	else
		# 按名称/正则匹配：先取路径，再匹配，避免状态标记(如 M、??)干扰
		local pattern="$1"
		local matched
		matched=$(git status --porcelain | _relpaths | grep -iE -- "$pattern")
		if [[ -z "$matched" ]]; then
			echo "git_status_open: 没有匹配 '$pattern' 的记录" >&2
			return 1
		fi
		echo "$matched" | _to_abs "$root" | xargs -r -d '\n' -o nvim --
	fi
}
