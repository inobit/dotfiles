# git_status_open — 按行号从 git status 中打开文件（nvim）
# Usage:
#   git_status_open         打开所有已变更文件
#   git_status_open 3       打开第 3 行对应的文件
#   git_status_open 2-5     打开第 2~5 行对应的文件
#
# 建议别名: alias gsn=git_status_open
#
# 在 .zshrc 中 source 即可使用：
#   source ~/ask/git-status-open.sh

git_status_open() {
  if [[ $# -eq 0 ]]; then
    git status --porcelain | awk '{print $NF}' | xargs -r -o nvim
  elif [[ "$1" =~ ^[0-9]+$ ]]; then
    git status --porcelain | awk -v n="$1" 'NR==n {print $NF}' | xargs -r -o nvim
  elif [[ "$1" =~ ^[0-9]+-[0-9]+$ ]]; then
    local s="${1%-*}"
    local e="${1#*-}"
    git status --porcelain | awk -v s="$s" -v e="$e" \
      'NR>=s && NR<=e {print $NF}' | xargs -r -o nvim
  else
    echo "Usage: git_status_open [N|N-M]"
    return 1
  fi
}
