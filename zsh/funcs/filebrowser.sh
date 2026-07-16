fb() {
    local base="/srv/ftp"
    [ -d "$base" ] || echo "提示: $base 目录不存在，执行 add 前请先创建: sudo mkdir -p $base" >&2
    case "${1:-}" in
        list)
            local mounts
            mounts=$(mount | grep " on ${base}/" | sed 's/.* on //;s/ type .*//')
            [ -z "$mounts" ] && return
            local i=1
            while IFS= read -r m; do
                printf "%d: %s\n" "$((i++))" "$m"
            done <<< "$mounts"
            ;;

        add)
            local src
            src=$(realpath "$2" 2>/dev/null) || { echo "ERROR: $2 无法解析为有效路径" >&2; return 1; }
            [ -d "$src" ] || { echo "ERROR: $src 不存在或不是目录" >&2; return 1; }
            local name
            name=$(basename "$src")
            local dst="${base}/${name}"
            sudo mkdir -p "$dst"
            sudo mount --bind "$src" "$dst" && echo "mounted: $src -> $dst"
            ;;

        rm)
            local mounts
            mounts=$(mount | grep " on ${base}/" | sed 's/.* on //;s/ type .*//')
            local -a arr
            while IFS= read -r m; do
                arr+=("$m")
            done <<< "$mounts"
            local total=${#arr[@]}

            if [ -z "$2" ]; then
                if [ "$total" -eq 0 ]; then
                    echo "no mounts to remove"
                    return
                fi
                for m in "${arr[@]}"; do
                    sudo umount "$m" && sudo rmdir "$m"
                done
                echo "removed all ($total) mounts"
                return
            fi

            local -a to_remove=()
            for idx in "${(@s:,:)2}"; do
                if [[ "$idx" =~ ^-[0-9]+$ ]]; then
                    local abs=$(( -idx ))
                    (( abs > total )) && { echo "ERROR: index $idx out of range (total: $total)" >&2; return 1; }
                    to_remove+=($(( total - abs + 1 )))
                elif [[ "$idx" =~ ^[0-9]+$ ]]; then
                    (( idx > total )) && { echo "ERROR: index $idx out of range (total: $total)" >&2; return 1; }
                    to_remove+=("$idx")
                else
                    echo "ERROR: invalid index: $idx" >&2; return 1
                fi
            done

            local has_removed=0 i=1
            for m in "${arr[@]}"; do
                for ridx in "${to_remove[@]}"; do
                    if (( i == ridx )); then
                        sudo umount "$m" && sudo rmdir "$m" && has_removed=1
                    fi
                done
                (( i++ ))
            done
            (( has_removed == 0 )) && { echo "no matching index to remove" >&2; return 1; }
            echo "removed: $2"
            ;;

        *)
            cat >&2 << 'HELP'
Usage:
  fb list               列出所有 bind mount
  fb add <path>         bind mount 到 /srv/ftp/<dirname>
  fb rm                 移除所有 bind mount
  fb rm <N>             按序号移除（序号见 fb list）
  fb rm <N,M>           移除多个
  fb rm <-N>            移除倒数第 N 个
HELP
            return 1
            ;;
    esac
}
