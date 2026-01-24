#!/bin/bash
#
# Query a property from the terminal, e.g. background color.
#
# XTerm Operating System Commands
#     "ESC ] Ps;Pt ST"

# 函数：计算亮度并判断深浅色
# 输入为 "RRRR/GGGG/BBBB" 格式的16位十六进制颜色值
# 输出 "dark" 或 "light"
calculate_theme() {
	local color_string="$1"

	# 使用awk进行解析和浮点数计算
	# 1. 将16位十六进制(RRRR)缩减为8位(RR)，并转换为十进制
	# 2. 将0-255的RGB值归一化到0-1
	# 3. 应用W3C推荐的亮度计算公式: Y = 0.2126*R + 0.7152*G + 0.0722*B
	# 4. 如果亮度 > 0.5，则为浅色背景
	awk -F'/' -v color="$color_string" '
    BEGIN {
        split(color, parts);
        r = "0x" substr(parts[1], 1, 2);
        g = "0x" substr(parts[2], 1, 2);
        b = "0x" substr(parts[3], 1, 2);
        
        luminance = 0.2126 * (r/255) + 0.7152 * (g/255) + 0.0722 * (b/255);
        
        if (luminance > 0.5) {
            print "light";
        } else {
            print "dark";
        }
    }'
}

get_tty_background() {
	oldstty=$(stty -g)

	# 11: text background
	Ps=${1:-11}

	stty raw -echo min 0 time 1
	printf "\033]%s;?\033\\" "$Ps" >/dev/tty
	# sleep 0.05
	read -r answer </dev/tty
	# echo $answer | cat -A
	result=${answer#*;}
	stty "$oldstty"
	# Remove escape at the end.
	rgb=$(echo "$result" | sed 's/[^rgb:0-9a-f/]\+$//' | awk -F ":" '{print $2}')
	color_mode=$(calculate_theme "$rgb")
	echo "$color_mode"
	export TTY_COLOR_MODE="$color_mode"
}
alias tcm=get_tty_background
