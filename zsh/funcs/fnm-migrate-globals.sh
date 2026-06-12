#!/usr/bin/env bash
# 从指定 fnm Node 版本的 global 包安装或迁移到当前版本
#
# 用法:
#   fnm_migrate_globals <version>               # 列出: 带序号输出 source 版本的全局包（默认）
#   fnm_migrate_globals -l <version>            # 同上（显式 list）
#   fnm_migrate_globals --list <version>
#   fnm_migrate_globals -i <version>            # 安装: 交互式选择，安装到当前版本（默认）
#   fnm_migrate_globals -m <version>            # 迁移: 交互式选择，安装后从 source 删除
#   fnm_migrate_globals -r <version>            # 删除: 交互式选择从 source 删除的包
#
# 选项:
#   -h, --help      显示帮助信息
#   -l, --list      列出 source 版本的全局包，无副作用
#   -i, --install   交互式选择包，安装到当前版本
#   -m, --migrate   交互式选择包，安装到当前版本后从 source 删除
#   -r, --remove    交互式选择从 source 删除的包，不安装到当前版本

# ---- 辅助函数：解析用户输入的编号选择 ----
# 输入: "1,3-5,7"  →  输出: "1 3 4 5 7"
_fnmt_parse_indices() {
  local input="$1"
  local total="$2"

  # 处理 "all"
  if [[ "$input" == "all" ]]; then
    local i
    for ((i = 1; i <= total; i++)); do
      echo "$i"
    done
    return 0
  fi

  # 拆分逗号分隔的输入（兼容 bash/zsh）
  local -a parts=()
  local _tmp_input="${input},"
  local _part
  while IFS= read -r -d ',' _part; do
    parts+=("$_part")
  done <<< "$_tmp_input"

  local part
  for part in "${parts[@]}"; do
    # 跳过空字段（例如 "1,,3" 中的空字段）
    [[ -z "$part" ]] && continue

    if [[ "$part" =~ ^[0-9]+-[0-9]+$ ]]; then
      # 范围: 1-3（用参数展开替代 BASH_REMATCH/message，兼容 zsh）
      local start="${part%-*}"
      local end="${part#*-}"
      if (( start <= end && start >= 1 && end <= total )); then
        local i
        for ((i = start; i <= end; i++)); do
          echo "$i"
        done
      else
        >&2 echo "Warning: 忽略无效范围 $part (1-$total)"
      fi
    elif [[ "$part" =~ ^[0-9]+$ ]]; then
      # 单个数字
      if (( part >= 1 && part <= total )); then
        echo "$part"
      else
        >&2 echo "Warning: 忽略无效编号 $part (1-$total)"
      fi
    else
      >&2 echo "Warning: 忽略无法识别的输入 '$part'"
    fi
  done
}

# ---- 辅助函数：带序号显示包列表 ----
# 从 stdin 读取每行一个包，格式化为带序号的列表
_fnmt_display_packages() {
  local title="$1"
  echo ""
  echo "$title"
  local idx=0
  local pkg
  while IFS= read -r pkg; do
    ((idx++))
    printf "  %2d)  %s\n" "$idx" "$pkg"
  done
  echo ""
}

# ---- 辅助函数：提取包名（去掉末尾 @version） ----
_fnmt_pkg_name() {
  local spec="$1"
  # ${var%@*} 删除最后一个 @ 及之后的内容，正确处理 @scope/pkg@1.0.0 → @scope/pkg
  echo "${spec%@*}"
}

# ---- 主函数 ----
fnm_migrate_globals() {
  local mode=""
  local source_version=""

  # ---- 解析参数 ----
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        echo "用法: fnm_migrate_globals [-h] [-l|--list|-i|--install|-m|--migrate|-r|--remove] <version>"
        echo ""
        echo "从指定 fnm Node 版本的 global 包安装或迁移到当前版本。"
        echo ""
        echo "选项:"
        echo "  -h, --help      显示此帮助信息"
        echo "  -l, --list      列出 source 版本的全局包，无副作用"
        echo "  -i, --install   交互式选择包，安装到当前版本"
        echo "  -m, --migrate   交互式选择包，安装到当前版本后从 source 删除"
        echo "  -r, --remove    交互式选择从 source 删除的包，不安装到当前版本"
        echo ""
        echo "示例:"
        echo "  fnm_migrate_globals 22          # 列出 v22 的全局包（默认 list）"
        echo "  fnm_migrate_globals -i 20       # 交互式选择并安装 v20 的全局包"
        echo "  fnm_migrate_globals -m 18       # 交互式选择要迁移的包（安装+删除）"
        echo "  fnm_migrate_globals -r 16       # 交互式选择要删除的包"
        return 0
        ;;
      -l|--list)     mode="list";     shift ;;
      -i|--install)  mode="install";  shift ;;
      -m|--migrate)  mode="migrate";  shift ;;
      -r|--remove)   mode="remove";   shift ;;
      -*)
        >&2 echo "Error: 未知选项 $1"
        >&2 echo "用法: fnm_migrate_globals [-h] [-l|--list|-i|--install|-m|--migrate|-r|--remove] <version>"
        return 1
        ;;
      *) source_version="$1"; shift ;;
    esac
  done

  if [[ -z "$source_version" ]]; then
    >&2 echo "Error: 缺少版本参数"
    >&2 echo "用法: fnm_migrate_globals [-h] [-l|--list|-i|--install|-m|--migrate|-r|--remove] <version>"
    return 1
  fi

  # ---- 1. 检查 fnm 是否存在 ----
  if ! command -v fnm &>/dev/null; then
    >&2 echo "Error: fnm 未安装或不在 PATH 中"
    return 1
  fi

  # ---- 2. 检查 jq 是否存在 ----
  if ! command -v jq &>/dev/null; then
    >&2 echo "Error: jq 未安装，请先安装 jq (brew install jq / apt install jq)"
    return 1
  fi

  # ---- 3. 解析 source 版本别名（22 → 22.11.0） ----
  local resolved_source
  resolved_source="$(fnm exec --using="$source_version" node -v 2>/dev/null | sed 's/^v//')" || true
  if [[ -z "$resolved_source" ]]; then
    >&2 echo "Error: fnm 中未找到版本 '$source_version'，请先用 fnm install $source_version"
    return 1
  fi

  # ---- 4. 获取当前版本 ----
  local current_version
  current_version="$( { fnm current 2>/dev/null || node -v 2>/dev/null; } | sed 's/^v//')" || true
  if [[ -z "$current_version" ]]; then
    >&2 echo "Error: 无法获取当前 Node 版本，请确认 fnm 已加载 (fnm env) 或 Node 已安装"
    return 1
  fi

  # ---- 5. 输出版本信息 ----
  echo "Source version:  $resolved_source"
  echo "Current version: $current_version"

  # ---- 6. 版本一致检查（仅 install / migrate 模式） ----
  if [[ "$mode" == "install" || "$mode" == "migrate" ]]; then
    if [[ "$resolved_source" == "$current_version" ]]; then
      echo "Warning: 源版本与当前版本一致，无需操作"
      return 0
    fi
  fi

  # ---- 7. 获取 source 版本的 global 包列表 ----
  local raw_json
  raw_json="$(fnm exec --using="$resolved_source" npm ls --global --json 2>/dev/null)" || true
  local packages
  packages="$(echo "$raw_json" \
    | jq -r '.dependencies | to_entries[]? | select(.key != "corepack" and .key != "npm") | .key+"@"+.value.version' 2>/dev/null)" || true

  if [[ -z "$packages" ]]; then
    echo "Source 版本 ($resolved_source) 没有全局 npm 包，无需操作"
    return 0
  fi

  # ---- 8. 默认模式：无 flag 时为 list ----
  if [[ -z "$mode" ]]; then
    mode="list"
  fi

  # ---- 9. 按模式分支 ----
  case "$mode" in
    remove|migrate|install)
      # ====== remove / migrate / install 共用：交互式选择 ======
      # 包列表转数组
      local -a pkg_array
      local -a name_array
      local line
      while IFS= read -r line; do
        pkg_array+=("$line")
        name_array+=("$(_fnmt_pkg_name "$line")")
      done <<< "$packages"

      # bash 数组 0-indexed / zsh 数组 1-indexed，用偏移量统一
      local _arr_off=1
      [[ -n "$ZSH_VERSION" ]] && _arr_off=0

      local total=${#pkg_array[@]}

      _fnmt_display_packages "Source 版本 ($resolved_source) 的全局包:" <<< "$packages"

      # 根据模式确定文案和后续操作
      local _action_name _do_install _do_delete
      case "$mode" in
        install) _action_name="安装"; _do_install=1; _do_delete=0 ;;
        migrate) _action_name="迁移"; _do_install=1; _do_delete=1 ;;
        remove)  _action_name="删除"; _do_install=0; _do_delete=1 ;;
      esac

      # 提示用户选择
      echo "输入要${_action_name}的包编号（支持格式: 1,3  1-3  1,3-5,7  all，留空取消）:"
      printf "> "
      read -r selection

      if [[ -z "$selection" ]]; then
        echo "已取消"
        return 0
      fi

      # 解析编号
      local -a selected_indices
      while IFS= read -r idx; do
        selected_indices+=("$idx")
      done <<< "$(_fnmt_parse_indices "$selection" "$total")"

      if [[ ${#selected_indices[@]} -eq 0 ]]; then
        >&2 echo "Error: 未选中任何有效包"
        return 1
      fi

      # 显示将要操作的包
      local -a selected_pkgs
      local -a selected_names
      for idx in "${selected_indices[@]}"; do
        selected_pkgs+=("${pkg_array[$((idx - _arr_off))]}")
        selected_names+=("${name_array[$((idx - _arr_off))]}")
      done

      echo ""
      echo "将${_action_name}以下包:"
      local p
      for p in "${selected_pkgs[@]}"; do
        printf "  - %s\n" "$p"
      done

      # 二次确认
      printf "确认%s? [y/N] " "$_action_name"
      read -r confirm
      if [[ ! "${confirm:-}" =~ ^[Yy]$ ]]; then
        echo "已取消${_action_name}"
        return 0
      fi

      # 安装到当前版本（install / migrate）
      if (( _do_install )); then
        echo ""
        echo ">>> 安装到当前版本 ($current_version) ..."
        if ! printf '%s\0' "${selected_pkgs[@]}" | xargs -0 -r npm i -g; then
          >&2 echo "Error: npm install -g 执行失败，请检查网络和 npm 状态"
          >&2 echo "（peer dependency 警告也可能导致非零退出码，请手动验证包是否已安装）"
          return 1
        fi
        echo "安装完成"
      fi

      # 从 source 版本删除（remove / migrate）
      if (( _do_delete )); then
        echo ""
        echo ">>> 从 source 版本 ($resolved_source) 删除选定包 ..."
        if ! printf '%s\0' "${selected_names[@]}" | xargs -0 -r fnm exec --using="$resolved_source" npm rm -g; then
          >&2 echo "Error: npm rm -g 执行失败，请检查权限和包名称"
          return 1
        fi
        echo "删除完成"
      fi
      ;;

    list)
      # ====== list 模式：仅列出，无副作用 ======
      _fnmt_display_packages "Source 版本 ($resolved_source) 的全局包:" <<< "$packages"
      ;;
  esac

  echo ""
  echo "Done."
}
