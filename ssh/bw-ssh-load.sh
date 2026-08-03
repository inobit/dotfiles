#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 用法:
#   bw-ssh-load.sh                          # 批量: SSH Key 全部入 agent (EXCLUDE_KEYS 可排除)
#   bw-ssh-load.sh "SSH Keys/A"             # 单 key: 私钥入 agent + 公钥存 ~/.ssh/A.pub
#   bw-ssh-load.sh "A" "custom.pub"         # 自定义公钥文件名
#   bw-ssh-load.sh "A" "/path/to/x.pub"     # 自定义路径/文件名, 目录须存在
#   bw-ssh-load.sh "A" --no-agent           # 只写公钥文件, 不碰 agent
#   bw-ssh-load.sh "A" --no-pub             # 只入 agent, 不写公钥文件
#   bw-ssh-load.sh "A" --no-agent --no-pub  # ✗ 无操作, 拒绝
#   bw-ssh-load.sh "A" --dry-run            # 预演
# ============================================================

# ============================================================
# 配置区
#
# FOLDER_NAMES: 限制只从这些 Bitwarden 文件夹中加载 SSH Key
#   填入文件夹名称（对应 BW UI 中的文件夹名），留空则加载全部
#
# PUB_KEY_NAMES: 无参数模式下，仅对这些条目生成 .pub 文件
#   格式: "条目名" 或 "文件夹名/条目名"（同名条目在不同文件夹时需指定文件夹）
#   留空则不生成任何 .pub 文件
#
# EXCLUDE_KEYS: 批量模式下不写入 ssh-agent 的条目
#   "文件夹/条目"  精确排除; "条目" 排除所有同名条目
# ============================================================
FOLDER_NAMES=(
	# "SSH Keys"
	# "Work"
)

PUB_KEY_NAMES=(
	# "GitHub Personal"
	# "Work/GitHub"          # 文件夹名/条目名 格式
	# "Company Server"
)

EXCLUDE_KEYS=(
	# "SSH Keys/Old Key"
	# "Legacy Key"
)
# ============================================================

DRY_RUN=false
NO_AGENT=false
NO_PUB=false

_pre_check() {
	command -v bw >/dev/null 2>&1 || {
		echo "✗ 'bw' 未安装。"
		exit 1
	}
	command -v jq >/dev/null 2>&1 || {
		echo "✗ 'jq' 未安装。"
		exit 1
	}
	command -v ssh-add >/dev/null 2>&1 || {
		echo "✗ 'ssh-add' 未安装。"
		exit 1
	}

	if [ "$DRY_RUN" = false ]; then
		_ret=0
		ssh-add -l >/dev/null 2>&1 || _ret=$?
		if [ $_ret -eq 2 ]; then
			echo "✗ ssh-agent 未运行或不可访问。"
			exit 1
		fi
		mkdir -p "$HOME/.ssh"
		chmod 700 "$HOME/.ssh"
	fi
}

_cleanup() {
	if [ -n "${BW_SESSION:-}" ]; then
		BW_SESSION="$BW_SESSION" bw lock >/dev/null 2>&1 || true
	fi
}
trap _cleanup EXIT

# 解析公钥输出路径: 缺省用条目名 sanitize + .pub; 自定义名支持 (路径)?文件名(.pub)?
_pub_path() {
	local out="$1" item="$2"
	local dir leaf
	if [ -n "$out" ]; then
		if [[ "$out" == */* ]]; then
			dir="${out%/*}"
			leaf="${out##*/}"
			[ -n "$leaf" ] || {
				echo "✗ 缺少文件名: $out" >&2
				return 1
			}
			[ -d "$dir" ] || {
				echo "✗ 目录不存在: $dir" >&2
				return 1
			}
		else
			dir="$HOME/.ssh"
			leaf="$out"
		fi
		[[ "$leaf" == *.?* ]] || leaf="${leaf}.pub"
	else
		dir="$HOME/.ssh"
		leaf=$(printf '%s' "$item" | tr ' ' '_' | tr -cd '[:alnum:]_.-')
		leaf="${leaf}.pub"
	fi
	printf '%s\n' "$dir/$leaf"
}

# ---- 参数解析 ----
ARGS=()
while [ $# -gt 0 ]; do
	case "$1" in
	--dry-run) DRY_RUN=true ;;
	--no-agent) NO_AGENT=true ;;
	--no-pub) NO_PUB=true ;;
	*) ARGS+=("$1") ;;
	esac
	shift
done

_pre_check

echo "Unlocking Bitwarden..."
BW_SESSION=$(bw unlock --raw) || {
	echo "✗ 解锁失败"
	exit 1
}
export BW_SESSION

if [ ${#ARGS[@]} -eq 0 ]; then
	# 无参数模式：加载 SSH Key（可按文件夹过滤）
	if [ ${#FOLDER_NAMES[@]} -gt 0 ]; then
		names_json=$(printf '%s\n' "${FOLDER_NAMES[@]}" | jq -R . | jq -s -c .)
		folder_ids_json=$(BW_SESSION="$BW_SESSION" bw list folders | jq -c --argjson names "$names_json" '[.[] | select(.name as $n | $names | index($n)) | .id]')
		items_json=$(BW_SESSION="$BW_SESSION" bw list items | jq -c --argjson folder_ids "$folder_ids_json" '[.[] | select(.type==5 and (.folderId // "") as $fid | $folder_ids | index($fid) != null)]')
	else
		items_json=$(BW_SESSION="$BW_SESSION" bw list items | jq -c '[.[] | select(.type==5)]')
	fi
	count=$(echo "$items_json" | jq 'length')
	[ "$count" -eq 0 ] && {
		echo "没有找到 SSH Key 类型条目。"
		exit 0
	}

	# 预先获取文件夹 id → name 映射
	declare -A _FOLDER_MAP
	while IFS=$'\t' read -r fid fname; do
		[ -n "$fid" ] && _FOLDER_MAP[$fid]="$fname"
	done < <(BW_SESSION="$BW_SESSION" bw list folders | jq -r '.[] | "\(.id)\t\(.name)"')

	declare -A _EX_MATCHED
	declare -A _PUB_WRITTEN

	while read -r item; do
		name=$(echo "$item" | jq -r '.name')
		private_key=$(echo "$item" | jq -r '.sshKey.privateKey // ""')
		public_key=$(echo "$item" | jq -r '.sshKey.publicKey // ""')

		fid=$(echo "$item" | jq -r '.folderId // ""')
		folder_name="${_FOLDER_MAP[$fid]:-}"

		# 应用排除列表 EXCLUDE_KEYS (精确 "文件夹/条目" 或宽松 "条目名")
		skip=false
		for ex in "${EXCLUDE_KEYS[@]}"; do
			if [[ "$ex" == */* ]]; then
				ex_folder="${ex%%/*}"
				ex_item="${ex#*/}"
				{ [ "$name" = "$ex_item" ] && [ "$folder_name" = "$ex_folder" ]; } || continue
			else
				[ "$name" = "$ex" ] || continue
			fi
			_EX_MATCHED["$ex"]=1
			echo "  ⏭ 排除: ${folder_name:+$folder_name/}$name"
			skip=true
			break
		done
		[ "$skip" = true ] && continue

		[ -z "$private_key" ] && {
			echo "  ⚠ $name: 无私钥，跳过"
			continue
		}

		if [ "$DRY_RUN" = false ]; then
			printf '%s' "$private_key" | ssh-add - 2>/dev/null && echo "  ✔ $name → agent" || echo "  ⚠ $name: 加载失败"
		else
			echo "  [DRY RUN] $name → agent"
		fi

		for pub_entry in "${PUB_KEY_NAMES[@]}"; do
			if [[ "$pub_entry" == */* ]]; then
				pub_folder="${pub_entry%%/*}"
				pub_item="${pub_entry#*/}"
			else
				pub_folder=""
				pub_item="$pub_entry"
			fi
			[ "$name" != "$pub_item" ] && continue
			[ -n "$pub_folder" ] && [ "$folder_name" != "$pub_folder" ] && continue
			[ -z "$public_key" ] && continue

			safe_name=$(echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_.-')
			if [ -n "${_PUB_WRITTEN[$safe_name]:-}" ]; then
				echo "✗ PUB_KEY_NAMES 冲突: '$safe_name.pub' 匹配到多个条目"
				echo "  - ${_PUB_WRITTEN[$safe_name]}"
				[ -n "$folder_name" ] && echo "  - $folder_name/$name" || echo "  - $name"
				echo "✗ 请用 '文件夹名/条目名' 格式消歧（如 \"$folder_name/$name\"）"
				exit 1
			fi
			[ -n "$folder_name" ] && _PUB_WRITTEN[$safe_name]="$folder_name/$name" || _PUB_WRITTEN[$safe_name]="$name"

			if [ "$DRY_RUN" = false ]; then
				printf '%s' "$public_key" >"$HOME/.ssh/${safe_name}.pub"
				echo "    → .pub: ~/.ssh/${safe_name}.pub"
			else
				echo "    [DRY RUN] .pub → ~/.ssh/${safe_name}.pub"
			fi
			break
		done
	done < <(echo "$items_json" | jq -c '.[]')

	for ex in "${EXCLUDE_KEYS[@]}"; do
		[ -n "${_EX_MATCHED[$ex]:-}" ] || echo "  ⚠ 排除项未命中任何条目: $ex"
	done
else
	# 单 key 模式：按名称（支持 文件夹名/条目名 格式）查找
	ITEM_NAME="${ARGS[0]}"
	if [[ "$ITEM_NAME" == */* ]]; then
		FOLDER_FILTER="${ITEM_NAME%%/*}"
		ITEM_NAME="${ITEM_NAME#*/}"
	else
		FOLDER_FILTER=""
	fi

	if [ -n "$FOLDER_FILTER" ]; then
		folder_id=$(BW_SESSION="$BW_SESSION" bw list folders | jq -r --arg name "$FOLDER_FILTER" '.[] | select(.name==$name) | .id')
		[ -z "$folder_id" ] && {
			echo "✗ 未找到文件夹: $FOLDER_FILTER"
			exit 1
		}
		matches=$(BW_SESSION="$BW_SESSION" bw list items --folderid "$folder_id" --search "$ITEM_NAME" | jq -c --arg name "$ITEM_NAME" '[.[] | select(.type==5 and .name==$name)]')
	else
		matches=$(BW_SESSION="$BW_SESSION" bw list items --search "$ITEM_NAME" | jq -c --arg name "$ITEM_NAME" '[.[] | select(.type==5 and .name==$name)]')
	fi

	count=$(echo "$matches" | jq 'length')
	if [ "$count" -eq 0 ]; then
		[ -n "$FOLDER_FILTER" ] && echo "✗ 文件夹 '$FOLDER_FILTER' 中未找到: $ITEM_NAME" || echo "✗ 未找到: $ITEM_NAME"
		exit 1
	elif [ "$count" -gt 1 ]; then
		echo "✗ 有 $count 个条目匹配 '$ITEM_NAME'，请用 '文件夹名/条目名' 格式消歧或修改名称使其唯一："
		echo "$matches" | jq -r '.[] | "  - \(.name)  [文件夹ID: \(.folderId // "无")]"'
		exit 1
	fi

	item=$(echo "$matches" | jq -c '.[0]')
	private_key=$(echo "$item" | jq -r '.sshKey.privateKey // ""')
	public_key=$(echo "$item" | jq -r '.sshKey.publicKey // ""')

	if [ "$NO_AGENT" = true ] && [ "$NO_PUB" = true ]; then
		echo "✗ --no-agent 且 --no-pub: 没有执行任何操作"
		exit 1
	fi
	[ "$NO_AGENT" = false ] && [ -z "$private_key" ] && {
		echo "✗ 条目缺少私钥"
		exit 1
	}
	[ "$NO_PUB" = false ] && [ -z "$public_key" ] && {
		echo "✗ 条目无公钥"
		exit 1
	}

	if [ "$NO_AGENT" = false ]; then
		if [ "$DRY_RUN" = false ]; then
			printf '%s' "$private_key" | ssh-add - && echo "✔ $ITEM_NAME → agent"
		else
			echo "[DRY RUN] $ITEM_NAME → agent"
		fi
	fi

	if [ "$NO_PUB" = false ]; then
		pub_path=$(_pub_path "${ARGS[1]:-}" "$ITEM_NAME") || exit 1
		if [ "$DRY_RUN" = false ]; then
			printf '%s' "$public_key" >"$pub_path"
			echo "✔ .pub → $pub_path"
		else
			echo "[DRY RUN] .pub → $pub_path"
		fi
	fi
fi

if [ "$DRY_RUN" = false ]; then
	ssh-add -l
fi
echo "Done."
