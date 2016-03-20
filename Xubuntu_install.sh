#!/bin/bash
#Author: kashu
#My Website: https://kashu.org
#Date: 2016-03-21
#Filename: Xubuntu_install.sh
#Description: Things I must to do after fresh installation of Xubuntu 14.04.x amd64.

#This shell script will install many programs and do some very IMPORTANT settings.
#Some applications you may not want to install, so you need to modify this script to meet your needs. 
#All of these apps are very useful for me. I believe you will like it too.

# Help info
help_info(){
	cat <<- 'END'
	Usage:
	$ sudo ./xubuntu.app.install.sh [-h|-H|-help|--help]
	
	Error exit codes with special meanings:
	100    User ${u_name} add failed. 
	101    apt-fast download failed! --> https://github.com/ilikenwf/apt-fast/archive/master.zip
	102    aria2 install failed! --> apt-get install -y aria2
	103    apt-fast install failed!
	END
}

case "$*" in
  "")
    : ;;
  -h|-H|-help|--help|*)
    help_info
    exit ;;
esac

# Check the privileges
if [[ "$UID" -ne "0"  ]]; then
  echo "Super-user privileges are required."
  exit
fi

# Check the current OS version
if ! `lsb_release -ds | grep -sq '14.04'`; then
  grep -sq 14.04 /etc/issue || {
  echo "Current OS is `awk '{print $1" "$2}' /etc/issue`"
  echo "Recommand OS: Xubuntu 14.04.x"
  exit
  }
fi

# Check the architechture
if [ "`uname -m`" != "x86_64" ]; then
  echo "uname -a:  `uname -a`"
  echo "The OS is not 64-bit"
  exit
fi

# Specify an user that you usually use
echo -e "\nPlease give me an username that you usually use."
echo -e "Attention: Some settings will apply to that user which provided by you."
echo -e "If that user dosen't exist on the system, it will be create automatically\n"
read -p 'Enter an username: ' u_name

if ! `cut -d: -f1 /etc/passwd | grep -sq "${u_name}"`; then
  if ! `useradd "${u_name}"`; then
    echo "User ${u_name} add failed"
    exit 100
  else
    if `cut -d':' -f1 /etc/passwd | grep -sq "${u_name}"`; then
      mkdir -m 755 /home/${u_name} /home/${u_name}/bin
      cp /etc/skel/.bashrc /home/${u_name}/
      chown -R ${u_name}.${u_name} /home/${u_name}
    fi
  fi
else
  mkdir -m 755 /home/${u_name}/bin
  chown -R ${u_name}.${u_name} /home/${u_name}/
fi

# Installation log file
LOG=/tmp/installation_`date +%Y.%m.%d_%T`.log
echo "START: `date +%Y.%m.%d_%T`" > "$LOG"


# 1. Some configuration
############################################################################
# /etc/sysctl.conf 
# More: https://www.howtoforge.com/tutorial/linux-swappiness/
# http://www.binarytides.com/disable-ipv6-ubuntu/
if ! `grep -sqm1 "^vm.swappiness" /etc/sysctl.conf`; then
	cat >> /etc/sysctl.conf <<- 'SYSCTL'
	vm.swappiness=0
	
	# IPv6 disabled
	net.ipv6.conf.all.disable_ipv6 = 1
	net.ipv6.conf.default.disable_ipv6 = 1
	net.ipv6.conf.lo.disable_ipv6 = 1
	
	# increase TCP max buffer size settable using setsockopt()
	net.core.rmem_max = 16777216 
	net.core.wmem_max = 16777216 
	# increase Linux autotuning TCP buffer limit 
	net.ipv4.tcp_rmem = 4096 87380 16777216
	net.ipv4.tcp_wmem = 4096 65536 16777216
	# increase the length of the processor input queue
	net.core.netdev_max_backlog = 30000
	# recommended default congestion control is htcp 
	net.ipv4.tcp_congestion_control=htcp
	# recommended for hosts with jumbo frames enabled
	net.ipv4.tcp_mtu_probing=1
	# disable ping response
	net.ipv4.icmp_echo_ignore_all=1
	SYSCTL
	/sbin/sysctl -p/etc/sysctl.conf
fi

# SSD TRIM (More: http://www.howtogeek.com/176978/ubuntu-doesnt-trim-ssds-by-default-why-not-and-how-to-enable-it-yourself)
for DISK in $(fdisk -l 2> /dev/null | grep -i "^Disk /" | awk -F'[ |:]' '{print $2}'); do
  hdparm -I ${DISK} | grep -sqim1 "TRIM supported" && { trim_enable=1; break; }
done

if [ "${trim_enable}" -eq 1 ]; then
  if `grep -m1 "^exec fstrim-all" /etc/cron.weekly/fstrim | grep -sqv "no-model-check"`; then
    sed -i 's/^exec/#exec/g' /etc/cron.weekly/fstrim
    echo 'exec fstrim-all --no-model-check' >> /etc/cron.weekly/fstrim
  fi
fi

# Use RAM storage for /tmp. My laptop RAM is 12GB (More: https://wiki.archlinux.org/index.php/Tmpfs)
grep -sqm1 "^tmpfs /tmp" /etc/fstab ||\
echo "tmpfs /tmp tmpfs defaults,sync,noatime,nosuid,nodev,mode=1777,size=75% 0 0" >> /etc/fstab

# Disable Apport at startup (More: http://howtoubuntu.org/how-to-disable-stop-uninstall-apport-error-reporting-in-ubuntu)
sed -i 's/enabled=1/enabled=0/g' /etc/default/apport

#/etc/rc.local
if ! grep -sq ChromiumCacheDir /etc/rc.local; then
	sed -i '/exit 0/d' /etc/rc.local
	cat >> /etc/rc.local <<- 'END'
	#Change the screen brightness
	#echo 9 > /sys/class/backlight/acpi_video0/brightness

	mkdir -p /tmp/ChromiumCacheDir/firefox /tmp/ChromiumCacheDir/chrome /tmp/linux
	#/bin/chown kashu.kashu -R /tmp/ChromiumCacheDir/ /tmp/linux

	# Disable Wi-Fi at startup
	#/usr/bin/nmcli nm wifi off
	#rfkill block wifi
	exit 0
	END
fi
#Move the Chromium cache directory to /tmp/ChromiumCacheDir
mkdir -p /home/${u_name}/.cache/chromium/ /tmp/ChromiumCacheDir/firefox /tmp/ChromiumCacheDir/chrome /tmp/linux
ln -s /home/${u_name}/.cache/chromium/Default /tmp/ChromiumCacheDir/
chown -R ${u_name}.${u_name} /home/${u_name}/.cache/chromium/ /tmp/ChromiumCacheDir/ /tmp/linux
#rmdir /var/lib/libvirt/images
#ln -s /var/lib/libvirt/images /tmp/linux

# Download the latest hosts file from github.com (For 跳墙)
DATE=`date +%Y%m%d_%H%M%S`
wget -r --retry-connrefused --no-check-certificate https://raw.githubusercontent.c\
om/racaljk/hosts/master/hosts -O /tmp/hosts."$DATE"
if [ $? -eq 0 ]; then
  mv -f /etc/hosts /etc/hosts."$DATE"
  if [ -f /etc/hosts.base ]; then
    cat /etc/hosts.base >| /etc/hosts
  else
    :>| /etc/hosts
  fi
  cat /tmp/hosts."$DATE" >> /etc/hosts
fi

# ~/.bashrc
if ! `grep -sqm1 "My alias" /home/${u_name}/.bashrc`; then
	cat >> "/home/${u_name}/.bashrc" <<- 'BASHRC'
	# My alias
	alias ..="cd .."        #go to parent dir
	alias ...="cd ../.."    #go to grandparent dir
	alias hd='od -Ax -tx1z -v'  # what most people want from od (hexdump)
	#alias aria2c='aria2c -c -d /tmp -t 300 -m 30 -s10 -k5M -x10'
	alias cleancache='echo 123 | sudo -S sync && sleep 3 && sudo sysctl -w vm.drop_caches=1'
	alias cleanswap='echo 123 | sudo -S swapoff -a && sudo sh -c "sync && sleep 3 && sysctl -w vm.drop_caches=1" && sudo swapon -a'
	alias ishadowsocks='wget -q html http://ishadowsocks.com -O - | grep 密码: | cut -d: -f2 | cut -d\< -f1'
	#alias dstat='echo 123 | sudo -S dstat -lcdnmspyt -N eth0 -D total,sda,sdb'
	alias dstat='dstat -cdnmpy -N eth0 -D total,sda,sdb --top-bio-adv'
	alias calc='gnome-calculator &'
	alias apt-get='/usr/bin/apt-fast'
	alias TTY='sudo miniterm.py -p /dev/ttyUSB0 --lf'

	# append to the history file, don't overwrite it
	shopt -s histappend
	# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
	# Set the maximum number of lines contained in the history file
	HISTFILESIZE=30000
	# Set the number of commands to remember in the command history
	HISTSIZE=15000
	PROMPT_COMMAND="history -a"
	HISTTIMEFORMAT="%Y-%m-%d_%H:%M:%S "
	# Don't store duplicate adjacent items in the history
	HISTCONTROL=ignoreboth

	# export
	export PS4='+{$LINENO:${FUNCNAME[0]}} '
	export PS1="\e[01;34m\h\[\e[m:\e[01;32m\w\e[m$ "
	export EDITOR=vim
	export GREP_OPTIONS='--color=auto'
	export GST_ID3_TAG_ENCODING=GBK:UTF-8:GB18030:GB2312
	export GST_ID3V2_TAG_ENCODING=GBK:UTF-8:GB18030:GB2312

	# 1. Set colors for man pages
	man() {
		env \
		LESS_TERMCAP_mb=$(printf "\e[1;31m") \
		LESS_TERMCAP_md=$(printf "\e[1;31m") \
		LESS_TERMCAP_me=$(printf "\e[0m") \
		LESS_TERMCAP_se=$(printf "\e[0m") \
		LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
		LESS_TERMCAP_ue=$(printf "\e[0m") \
		LESS_TERMCAP_us=$(printf "\e[1;32m") \
		man "$@"
	}

	# 2. Dictionary for command line environment
	function s()
	{ 
		local word=$(echo "$*" | tr ' ' '+');
		local prefix='https'
		local dotflg='.'
		local andflg='&'
		local qmflg='?'
		lynx -accept_all_cookies -cache=50 -source "$prefix://www${dotflg}bing${dotflg}com/dict/search${qmflg}q=$word${andflg}qs=n${andflg}form=CM${andflg}pq=$word${andflg}sc=0-0${andflg}sp=-1${andflg}sk=" | html2text | sed '1,12d' | ccze -A | less -R
	}

	# 3. Print mount output info friendly
	nicemount(){ (echo "DEVICE PATH TYPE OPTIONS" && mount | awk '$2=$4="";1') | column -t; }

	# 4. Currency Converter. Usage: currency 1 usd cny
	currency(){ curl -s "https://www.google.com/finance/converter?a=$1&from=$2&to=$3" | sed '/res/!d;s/<[^>]*>//g'; }

	# 5. Update specific PPA. Usage: ppaupdate ppa:plushuang-tw/uget-stable
	ppaupdate(){ sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/$1" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"; }
	# Debian user-defined completion
	_ppa_lists(){
		local cur
		_init_completion || return
		COMPREPLY=( $( find /etc/apt/sources.list.d/ -name "*$cur*.list" -exec basename {} \; 2> /dev/null ) )
		return 0
	} &&
	complete -F _ppa_lists ppaupdate

	# 6. Change the screen brightness
	bri(){
		local a=${1:-9}
		echo 123 | sudo -S sh -c "echo ${a} > /sys/class/backlight/acpi_video0/brightness" &> /dev/null
	}

	# 7. Get the state of my battery
	_status(){
		#cat /sys/class/power_supply/BAT1/uevent
		local _path=/sys/class/power_supply/BAT1/
		cd $_path || { echo "$_path dosen\'t exist"; exit 1; }
		echo "Model_Name: `tr ' ' '_' < model_name`"
		echo "Status: `cat status`"
		echo "Capacity: `cat capacity`%"
		echo "Energy_Full_Desigh: $((`cat energy_full_design`/1000))mAh"
		echo "Energy_Full: $((`cat energy_full`/1000))mAh"
		echo "Energy_Now: $((`cat energy_now`/1000))mAh"
	}
	battery(){ _status | column -t; }
	BASHRC
fi


# Resolve the issue that vim can not display Chinese characters properly in the English lanuage system.
if ! `grep -sqi "zh_CN.GB18030" /var/lib/locales/supported.d/local`; then
	echo 'zh_CN.GBK GBK' >> /var/lib/locales/supported.d/local
	echo 'zh_CN.GB2312 GB2312' >> /var/lib/locales/supported.d/local
	echo 'zh_CN.GB18030 GB18030' >> /var/lib/locales/supported.d/local
fi

if ! `grep -sqi "gb2312" /etc/vim/vimrc`; then
	echo 'set fileencodings=utf-8,gb2312,gbk,gb18030' >> /etc/vim/vimrc
	echo 'set termencoding=utf-8' >> /etc/vim/vimrc
	echo 'set encoding=prc' >> /etc/vim/vimrc
fi


# ~/.inputrc
if [ ! -s "/home/${u_name}/.inputrc" ]; then
	cat > /home/${u_name}/.inputrc <<- 'INPUTRC'
	#set match-hidden-files off (do not show hidden files in the list: really useful when working in your home directory)
	#set show-all-if-ambiguous on (show the list at first TAB, instead of beeping and and waiting for a second TAB to do that)
	#set completion-query-items 1000 (show the "Display all 123 possibilities? (y or n)" prompt only for really long lists)
	#set page-completions off (removes the annoying "-- more --" prompt for long lists)
	#
	# More:
	# http://www.pixelbeat.org/settings/.inputrc
	# https://wiki.ubuntu.com/Spec/EnhancedBash
	# https://www.gnu.org/software/bash/manual/html_node/Readline-Init-File-Syntax.html

	# do not show hidden files in the list
	set match-hidden-files off

	# Don't echo ^C etc (new in bash 4.1)
	# Note this only works for the command line itself,
	# not if already running a command.
	set echo-control-characters off

	# Enable coloring for tab completions with bash >= 4.3
	set colored-stats on

	# auto complete ignoring case
	set completion-ignore-case on
	set show-all-if-ambiguous on

	#show the "Display all 123 possibilities? (y or n)" prompt only for really long lists
	set completion-query-items 300

	# By default up/down are bound to previous-history
	# and next-history respectively. The following does the
	# same but gives the extra functionality where if you
	# type any text (or more accurately, if there is any text
	# between the start of the line and the cursor),
	# the subset of the history starting with that text
	# is searched (like 4dos for e.g.).
	# Note to get rid of a line just Ctrl-C
	"\e[A": history-search-backward
	"\e[B": history-search-forward
	INPUTRC
fi


# ~/.conkyrc
if [ ! -s "/home/${u_name}/.conkyrc" ]; then
	cat > /home/${u_name}/.conkyrc <<- 'CONKYRC'
	############ - Text settings - ###########
	background no
	own_window yes
	##if own_window is yes, you may specify type normal, desktop, dock, panel or override (default: normal). Desktop windows are special windows that have no window decorations; are always visible on your desktop; do not appear in your pager or taskbar; and are sticky across all workspaces. Panel windows reserve space along a desktop edge, just like panels and taskbars, preventing maximized windows from overlapping them. The edge is chosen based on the alignment option. Override windows are not under the control of the window manager. Hints are ignored. This type of window can be useful for certain situations.
	#own_window_type desktop
	#own_window_type normal
	own_window_type overide
	own_window_transparent yes
	own_window_hints undecorated,below,sticky,skip_taskbar,skip_pager
	use_xft yes
	override_utf8_locale yes
	#font WenQuanYi Micro Hei:size=10
	xftfont Roboto:size=9
	xftalpha 1
	update_interval 1.0 
	total_run_times 0
	double_buffer yes 
	draw_shades no
	draw_outline no
	draw_borders no
	draw_graph_borders no
	###调整个CONKY的最小最大宽度值###
	minimum_size 220 768
	maximum_width 220
	alignment top_right
	text_buffer_size 380
	###相对于右上角的偏移量###
	gap_x 8
	gap_y 15
	no_buffers yes 
	cpu_avg_samples 2
	# set to yes if you want all text to be in uppercase
	uppercase no
	use_spacer none
	out_to_console no
	default_color grey
	default_shade_color black
	default_outline_color white
	##################################################################################
	TEXT
	${font style=Bold:size=10}${time %F    %H:%M    %a}
	${color }${font }$uptime${alignr}https://kashu.org${font }
	### CPU
	${color }CPU      ${color red}${freq_g}       ${cpu}%       ${color }${acpitemp}°C
	#${color }CUP1: ${freq_g 1}GHz ${cpubar cpu1 3}
	#CUP2: ${freq_g 2}GHz ${cpubar cpu2 3}
	#CUP3: ${freq_g 3}GHz ${cpubar cpu3 3}
	#CUP4: ${freq_g 4}GHz ${cpubar cpu4 3}
	### Memory
	${color }MEM  ${color pink}$cached  ${color yellow}$buffers  ${color green}$memfree
	${color }${membar 3 80}
	### Swap
	SWAP    ${swapperc}%${alignr}${swap} / ${swapmax}
	${swapbar 3 160} 
	Kernel:$alignr${kernel}
	#Load(1 5 15m): $loadavg
	## Processes info
	Processes:$alignr$processes  ($running_processes running)
	${color #ddaa00}Highest CPU$alignr PID    CPU%
	${color lightgrey}${top name 1}$alignr${top pid 1}  ${top cpu 1}
	${top name 2}$alignr${top pid 2}  ${top cpu 2}
	${top name 3}$alignr${top pid 3}  ${top cpu 3}
	#${top name 4}$alignr${top pid 4}  ${top cpu 4}
	${color #ddaa00}Highest MEM$alignr PID   MEM%
	${color lightgrey}${top_mem name 1}$alignr${top_mem pid 1}  ${top_mem mem 1}
	${top_mem name 2}$alignr${top_mem pid 2}  ${top_mem mem 2}
	${top_mem name 3}$alignr${top_mem pid 3}  ${top_mem mem 3}
	#${top_mem name 4}$alignr${top_mem pid 4}  ${top_mem mem 4}
	### Network Info
	${color green}Network Info${alignr}TCP_Conn: ${tcp_portmon 1 65535 count}
	### Eth0
	${if_up eth0}${color white}${font style:bold}eth0${font}${alignr}IP: ${color #dcff82}${addr eth0}${color}
	${color white}U:${color #dcff82} ${upspeedf eth0} KB/s${alignr}${color white}D:${color dcff82} ${downspeedf eth0} KB/s
	${downspeedgraph eth0 25,100 000000 ff0000} ${alignr}${upspeedgraph eth0 25,100 000000 00ff00}$endif
	#${color white}U_Total: ${color #dcff82}${totalup eth0}$alignr${color white}D_Total:${color #dcff82}${totaldown eth0}
	### PPP0
	#${if_up ppp0}
	#${color white}${font style=Bold}PPP0${font}${alignr}IP: ${color #dcff82}${addr ppp0}${color}
	#${color white}U:${color #dcff82} ${upspeedf ppp0} KB/s${alignr}${color white}D:${color dcff82} ${downspeedf ppp0} KB/s
	#${downspeedgraph ppp0 25,100 000000 ff0000} ${alignr}${upspeedgraph ppp0 25,100 000000 00ff00}
	#${color white}U_Total: ${color #dcff82}${totalup ppp0}$alignr${color white}D_Total:${color #dcff82}${totaldown ppp0}
	#$endif
	### Wlan0
	${if_up wlan0}${color white}${font style:Bold}wlan0${font}${alignr}IP: ${color #dcff82}${addr wlan0}${color}
	${color yellow}ESSID:${wireless_essid wlan0}${alignr}${wireless_link_qual_perc wlan0}%
	${voffset 1}${color white}U:${color #dcff82} ${upspeedf wlan0} KB/s${alignr}${color white}D:${color dcff82} ${downspeedf wlan0} KB/s
	${downspeedgraph wlan0 25,100 000000 ff0000} ${alignr}${upspeedgraph wlan0 25,100 000000 00ff00}
	${color white}U_Total: ${color #dcff82}${totalup wlan0}$alignr${color white}D_Total:${color #dcff82}${totaldown wlan0}$endif
	### /dev/sda
	${color white}${font style:bold}sda${font}: ${color #dcff82}${hddtemp /dev/sda}°C   ${color white}W: ${color #dcff82}${diskio_write /dev/sda}$alignr${color white}R: ${color #dcff82}${diskio_read /dev/sda}
	${diskiograph_write /dev/sda 25,100 000000 ff0000}${alignr}${diskiograph_read /dev/sda 25,100 000000 00ff00}
	### /dev/sdb
	${color white}${font style:bold}sdb${font}: ${color #dcff82}${hddtemp /dev/sdb}°C   ${color white}W: ${color #dcff82}${diskio_write /dev/sdb}$alignr${color white}R: ${color #dcff82}${diskio_read /dev/sdb}
	${diskiograph_write /dev/sdb 25,100 000000 ff0000}${alignr}${diskiograph_read /dev/sdb 25,100 000000 00ff00}
	### mount point
	${color }/tmp$alignr${color}${fs_used /tmp} / ${fs_free /tmp}
	${fs_bar 3 /tmp}
	#${color }/home$alignr${color}${fs_used /home} / ${fs_free /home}
	#${fs_bar 3 /home}
	#${color lightgreen}$stippled_hr
	#${color green}RSS Reading
	#${color white}${rss http://rss.cnbeta.com/rss 20 item_titles 10}
	#${tcp_portmon 1 1024 count}
	${font style:size=7}
	echo "pkg hold" | dpkg --set-selections
	yum update --exclude=pkg_name
	#git add -A; git status; git commit -m 'XXX'
	#git remote -v; git push origin master
	grep -sqm1o a.txt
	ffmpeg -f concat -i list -c copy a.flv
	rfkill block wifi
	sync; sudo sysctl -w vm.drop_caches=1
	
	dstat -cdnmpy -Neth0 -Dtotal,sda --top-bio-adv -t
	enca -L zh -x UTF-8 a.txt
	wget -O - URL > a.txt
	sed -ie 's/UTC=yes/UTC=no/g' /etc/default/rcS
	lsof -p $(echo `ps aux|fgrep chromium|awk '{print $2}'`|tr ' ' ',')|ccze -A|less -R
	awk -F':' '{print $(NF-1)}' file
	youtube-dl -f 266+140 --merge-output-format mp4 http://url
	CONKYRC
fi


# 2. Uninstall some unnecessary applications (blueman, 蓝牙支持也会删除，因为我笔记本没蓝牙 :P )
############################################################################
apt-get -y autoremove printer-driver* abiword* gnumeric* thunderbird xfce4-dict xchat* pidgin* xfburn gnome-mines gnome-sudoku parole gmusicbrowser transmission* simple-scan blueman


# 3. Install apt-fast (IMPORTANT)
############################################################################
if [ ! -x "/usr/bin/apt-fast" ]; then
  wget -qO "$PWD"/apt-fast.zip https://github.com/ilikenwf/apt-fast/archive/master.zip
  
  if [ -s "apt-fast.zip" ]; then
    unzip -o "$PWD"/apt-fast.zip
  else
    echo "apt-fast download failed! --> https://github.com/ilikenwf/apt-fast/archive/master.zip"
    exit 101
  fi
  
  apt-get install -y aria2
  
  if [ ! -s "/usr/bin/aria2c" ]; then
    echo "aria2c install failed! --> apt-get install -y aria2"
    exit 102
  fi
  
  cp "$PWD"/apt-fast-master/apt-fast /usr/bin/
  chmod +x /usr/bin/apt-fast
  cp "$PWD"/apt-fast-master/apt-fast.conf /etc/
  cp "$PWD"/apt-fast-master/man/apt-fast.8 /usr/share/man/man8
  cp "$PWD"/apt-fast-master/man/apt-fast.conf.5 /usr/share/man/man5
  gzip -f9 /usr/share/man/man8/apt-fast.8
  gzip -f9 /usr/share/man/man5/apt-fast.conf.5
  
  if [ ! -x "/usr/bin/apt-fast" ]; then
    echo "apt-fast install failed!"
    exit 103
  fi
fi

# Change the software sources and add Canonical Partners in it.
if `grep -F archive.canonical.com/ubuntu /etc/apt/sources.list | grep -Esq "^[[:space:]]?+#"`; then
  if [ -x "/usr/bin/lsb_release" ]; then
    sed -ri 's@^[[:space:]]?+#.*://archive.canonical.com/ubuntu.*@@g' /etc/apt/sources.list
    echo "deb http://archive.canonical.com/ubuntu `lsb_release -cs` partner" >> /etc/apt/sources.list
    echo "deb-src http://archive.canonical.com/ubuntu `lsb_release -cs` partner"  >> /etc/apt/sources.list
  fi
fi

apt-get clean
apt-fast update
apt-fast dist-upgrade -y


# 4. Install apps.     ## Stage 1 ##
############################################################################
#apt-fast install vim gedit ssh conky openssh-server dstat htop curl iotop iptraf nethogs sysv-rc-conf rdesktop shutter p7zip-full p7zip-rar preload meld ccze lynx html2text gparted optipng parallel proxychains wavemon sox audacity convmv xchm hddtemp hostapd isc-dhcp-server bum byzanz sysstat enca filezilla ntpdate exfat-fuse exfat-utils dconf-tools pv tftpd-hpa tftp-hpa dsniff xubuntu-restricted-extras shellcheck git virt-manager virt-viewer qemu-kvm lxc python-setuptools python3-setuptools remmina cmake gksu font-manager gnome-font-viewer samba cifs-utils nfs-common libnss3-tools trickle nrg2iso rar unrar cpulimit
#docker.io qemu-system
echo -e "\n\n# Install apps.     ## Stage 1 ##" >> $LOG
for a in vim gedit ssh conky openssh-server dstat htop curl iotop iptraf nethogs sysv-rc-conf rdesktop shutter p7zip-full p7zip-rar preload meld ccze lynx html2text gparted optipng parallel proxychains wavemon sox audacity convmv xchm hddtemp hostapd isc-dhcp-server bum byzanz sysstat enca filezilla ntpdate exfat-fuse exfat-utils dconf-tools pv tftpd-hpa tftp-hpa dsniff shellcheck git virt-manager virt-viewer qemu-kvm lxc python-setuptools python3-setuptools remmina cmake gksu font-manager gnome-font-viewer samba cifs-utils nfs-common libnss3-tools trickle nrg2iso rar unrar cpulimit; do
  dpkg -s ${a} &> /dev/null || { 
  apt-fast install -y ${a} || echo "Software: ${a} install failed" >> ${LOG}
  }
done
apt-get clean

# For gedit Chinese character support
gsettings set org.gnome.gedit.preferences.encodings auto-detected "['UTF-8','GB18030','GB2312','GBK','BIG5','CURRENT','UTF-16']"

if ! `grep -sq ^http /etc/proxychains.conf`; then
  sed -ri 's/(^socks)(.*)/#\1\2/g' /etc/proxychains.conf
  echo 'http 127.0.0.1 8787' >> /etc/proxychains.conf
fi


# 5.1 Add PPAs.
# Attention: If your network got fucked by GFW(The Great Firewall of China) or ISP, some PPAs may be failed to add and some APPs will not be installed.
# But don't worry about it, we'll try the best, just go ahead and forget it.
############################################################################
#add-apt-repository -y ppa:fcitx-team/nightly
#add-apt-repository -y ppa:linrunner/tlp
#add-apt-repository -y ppa:pi-rho/security
#add-apt-repository -y ppa:nilarimogard/webupd8
#add-apt-repository -y ppa:ubuntu-wine/ppa
#add-apt-repository -y ppa:coolwanglu/pdf2htmlex
#add-apt-repository -y ppa:diodon-team/stable
#add-apt-repository -y ppa:gezakovacs/ppa
#add-apt-repository -y ppa:mc3man/trusty-media
#add-apt-repository -y ppa:lzh9102/qwinff
#add-apt-repository -y ppa:maarten-baert/simplescreenrecorder
#add-apt-repository -y ppa:otto-kesselgulasch/gimp
#add-apt-repository -y ppa:plushuang-tw/uget-stable
#add-apt-repository -y ppa:stebbins/handbrake-releases
#add-apt-repository -y ppa:team-xbmc/ppa
#add-apt-repository -y ppa:webupd8team/y-ppa-manager
#add-apt-repository -y ppa:wseverin/ppa
#add-apt-repository -y ppa:thomas-schiex/blender
#add-apt-repository -y ppa:pinta-maintainers/pinta-stable
#add-apt-repository -y ppa:zanchey/asciinema
#add-apt-repository -y ppa:caffeine-developers/ppa
#add-apt-repository -y ppa:indicator-multiload/stable-daily

#add-apt-repository -y ppa:notepadqq-team/notepadqq
#apt-fast update
#apt-fast install notepadqq

#sudo add-apt-repository ppa:anton+/dnscrypt
#sudo apt-get update
#sudo apt-get install dnscrypt-proxy

#支持安装在15.04及以后的版本上
#add-apt-repository -y ppa:osmoma/audio-recorder
#新PPA是这个：ppa:audio-recorder/ppa
#apt-fast update
#apt-fast install audio-recorder

#more: http://ppsspp.org/downloads.html
#sudo add-apt-repository ppa:ppsspp/stable
#sudo apt-get update
#sudo apt-get install ppsspp
#sudo apt-get install ppsspp-qt

#more: http://pipelight.net/cms/install/installation-ubuntu.html
#add-apt-repository ppa:pipelight/stable
#apt-get update
#apt-get install --install-recommends pipelight-multi
#pipelight-plugin --update
#pipelight-plugin --enable unity3d
#pipelight-plugin --enable silverlight5.1

#Calibre EBook Management
#more: http://calibre-ebook.com/download_linux
#sudo -v && wget -nv -O- https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | sudo python -c "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"

#more: https://www.playonlinux.com/en/download.html
#wget -q "http://deb.playonlinux.com/public.gpg" -O- | sudo apt-key add -
#sudo wget http://deb.playonlinux.com/playonlinux_trusty.list -O /etc/apt/sources.list.d/playonlinux.list
#sudo apt-get update
#sudo apt-get install playonlinux

#TeamViewer
#aria2c http://download.teamviewer.com/download/teamviewer_amd64.deb
#On newer 64-bit DEB-systems with Multiarch-support (Debian 7) teamviewer_linux_x64.deb cannot be installed because the package ia32-libs is not available anymore on these systems. In this case you can use teamviewer_i386.deb instead. (https://www.teamviewer.com/en/help/363-How-do-I-install-TeamViewer-on-my-Linux-distribution.aspx)
#dpkg -i ./teamviewer_amd64.deb

###teamviewer_i386.deb may be better...###
#aria2c http://download.teamviewer.com/download/teamviewer_i386.deb
#dpkg -i ./teamviewer_i386.deb
#apt-get -f install

#variety (wallpaper switch)
#/usr/bin/apt-fast install variety -y

#安装bleachbit清理工具
#More：http://bleachbit.sourceforge.net/download/linux
#For Xubuntu 14.04:
#dpkg -i ./bleachbit_1.6_all_ubuntu1404.deb
#apt-get -f install -y

#The Brain (MindMap)
#More: http://www.thebrain.com/products/thebrain/download/
#http://assets.thebrain.com/downloads/TheBrain_unix_8_0_1_6.sh

#深度截图
#wget http://packages.linuxdeepin.com/deepin/pool/main/d/deepin-scrot/deepin-scrot_2.0-0deepin_all.deb
#python依赖
#sudo apt-get install python-xlib
#sudo dpkg -i deepin-scrot_2.0-0deepin_all.deb
#终端下启动
#$ deepin-scort

#XnConvert（图片处理神器）
#More：http://www.xnview.com/en/xnconvert/
#dpkg -i ./XnConvert-linux-x64.deb
#if [ "$?" != "0" ]; then echo "XnConvert install failed!" && exit 1; fi

#Google Earth（谷歌地球）
#官网：http://www.google.com/intl/en/earth/download/ge/agree.html
#aria2c -c https://dl.google.com/dl/earth/client/current/google-earth-stable_current_amd64.deb
#sudo dpkg -i google-earth-stable_current_amd64.deb
#sudo apt-get -f install（若执行上面的安装后提示有依赖包要装，就执行此命令安装即可）
#sudo dpkg -i google-earth-stable_current_amd64.deb（若执行了上面那条命令，需重新执行此安装命令）

#虾米电台
#官网：https://launchpad.net/~timxx/+archive/ubuntu/xmradio
#sudo add-apt-repository ppa:timxx/xmradio
#sudo apt-get update
#sudo apt-get install xmradio

#XAMPP（集成了Apache+Mysql+PHP+Perl环境，提供了一个现成的建站环境）
#官网：http://sourceforge.net/projects/xampp/files/XAMPP%20Linux/
#把软件移动到/opt目录里：sudo mv ./sudo mv xampp-linux-x64-1.8.3-1-installer.run /opt
#添加可执行权限：sudo chmod +700 xampp-linux-x64-1.8.3-1-installer.run
#安装：sudo ./xampp-linux-x64-1.8.3-1-installer.run

#Gis Weather天气预报（很漂亮的一款桌面挂件式天气预报）
#More：http://sourceforge.net/projects/gis-weather/files/gis-weather/
#aria2c -c http://jaist.dl.sourceforge.net/project/gis-weather/gis-weather/0.7.5/gis-weather_0.7.5_all.deb
#dpkg -i ./gis-weather_0.7.7_all.deb
#apt-fast -f install -y

#Xtreme Download Manager（极速下载，非常优秀的一款下载管理器）
#More：http://sourceforge.net/projects/xdman/files/?source=navbar
#dpkg -i xdman.deb
#apt-fast -f install -y

echo -e "\n\n# 5.1 Add PPAs." >> $LOG
for b in ppa:fcitx-team/nightly ppa:linrunner/tlp ppa:pi-rho/security ppa:nilarimogard/webupd8 ppa:ubuntu-wine/ppa ppa:coolwanglu/pdf2htmlex ppa:diodon-team/stable ppa:gezakovacs/ppa ppa:mc3man/trusty-media ppa:lzh9102/qwinff ppa:maarten-baert/simplescreenrecorder ppa:otto-kesselgulasch/gimp ppa:plushuang-tw/uget-stable ppa:stebbins/handbrake-releases ppa:team-xbmc/ppa ppa:webupd8team/y-ppa-manager ppa:wseverin/ppa ppa:thomas-schiex/blender ppa:pinta-maintainers/pinta-stable ppa:zanchey/asciinema ppa:caffeine-developers/ppa ppa:indicator-multiload/stable-daily; do
  B="$(echo ${b} | awk -F'[:|/]' '{print $2}')"
  if ! `ls -1 /etc/apt/sources.list.d/ | grep -sq ${B}`; then
    add-apt-repository -y ${b} || echo "PPA: ${b} add failed" >> ${LOG}
  fi
done


# 5.2 Install APPs.     ## Stage 2 ##
############################################################################
#apt-fast install fcitx-table-wbpy tlp tlp-rdw nmap hydra audacious indicator-multiload caffeine pdf2htmlex diodon unetbootin vlc vlc-plugin-libde265 ffmpeg qwinff simplescreenrecorder uget handbrake-gtk kodi y-ppa-manager linssid blender pinta ppa-purge asciinema php5-fpm
echo -e "\n\n# 5.2 Install APPs.     ## Stage 2 ##" >> $LOG

# Install Stable version of Nginx
if [ ! -x "/usr/sbin/nginx" ]; then
  wget http://nginx.org/keys/nginx_signing.key
  apt-key add nginx_signing.key
  echo "deb http://nginx.org/packages/ubuntu/ `lsb_release -cs` nginx" >> /etc/apt/sources.list.d/nginx-trusty.list
  echo "deb-src http://nginx.org/packages/ubuntu/ `lsb_release -cs` nginx" >> /etc/apt/sources.list.d/nginx-trusty.list
  #apt-get update -o Dir::Etc::sourcelist="sources.list.d/nginx-trusty.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
  apt-fast update
  apt-fast install -y nginx
  dpkg -s nginx &> /dev/null || echo "Software: nginx install failed" >> ${LOG}
else
  apt-fast update
fi

for c in fcitx-table-wbpy tlp tlp-rdw nmap hydra audacious indicator-multiload caffeine pdf2htmlex diodon unetbootin vlc vlc-plugin-libde265 ffmpeg qwinff simplescreenrecorder uget handbrake-gtk kodi y-ppa-manager linssid blender pinta ppa-purge asciinema php5-fpm; do
  dpkg -s ${c} &> /dev/null || {
  apt-fast -y install ${c} || echo "Software: ${c} install failed" >> ${LOG}
  }
done
apt-get clean

if [ -x "/usr/bin/kodi" ]; then
	echo "For Kodi(XBMC): wget https://github.com/taxigps/xbmc-addons-chinese/raw/master/repo/\
	repository.xbmc-addons-chinese/repository.xbmc-addons-chinese-1.2.0.zip" >> ${LOG}
fi

apt-fast install --only-upgrade gimp -y

#导入uGet的配置: --enable-rpc=true -D --check-certificate=false --disable-ipv6=true
if [ -s "/home/${u_name}/.config/uGet/Setting.json" ]; then
  sed -i 's/[[:space:]]*"arguments.*/\t\t"arguments": "\-c \-\-enable\-rpc\=true \-D \-\-check\-certificate\=false \-\-disable\-ipv6\=true \-\-disk\-cache\=128M \-j 10",/g' /home/${u_name}/.config/uGet/Setting.json
fi


# 5.3 Install APPs.     ## Stage 3 ## 
############################################################################
echo -e "\n\n# 5.3 Install APPs.     ## Stage 3 ## " >> $LOG
# PAC Manager (Perl Auto Connector)
# More: http://sourceforge.net/projects/pacmanager/files/pac-4.0/
if [ ! -x "/usr/bin/pac" ]; then
  wget http://netix.dl.sourceforge.net/project/pacmanager/pac-4.0/pac-4.5.5.7-all.deb
  dpkg -i ./pac*.deb
  apt-get -f -y install
fi

# More: https://github.com/getlantern/lantern
# https://raw.githubusercontent.com/getlantern/lantern-binaries/master/lantern-installer-beta-32-bit.deb
if [ ! -x "/usr/bin/lantern" ]; then
  wget https://raw.githubusercontent.com/getlantern/lantern-binaries/master/lantern-installer-beta-64-bit.deb
  dpkg -i lantern-installer-beta-64-bit.deb
  if ! `grep -sq '0.0.0.0' /usr/share/applications/lantern.desktop`; then
		cat > /usr/share/applications/lantern.desktop <<- 'END'
		[Desktop Entry]
		Type=Application
		Categories=Network
		Name=Lantern
		Exec=nohup lantern -addr 0.0.0.0:8787 -startup=true &> /dev/null &
		Icon=lantern
		Terminal=false
		END
  fi
fi
# Start Lantern
if [ -x "/usr/lib/lantern/lantern.sh" ]; then
  if ! pgrep lantern; then
    nohup /home/${u_name}/.lantern/bin/lantern -addr 0.0.0.0:8787 -startup=true &> /dev/null &
  fi
fi

# Master PDF Editor（PDF编辑器）
# More: http://code-industry.net/free-pdf-editor.php
if [ ! -x "/usr/bin/masterpdfeditor3" ]; then
  #aria2c -c http://get.code-industry.net/public/master-pdf-editor-3.5.81_i386.deb
  aria2c -c http://get.code-industry.net/public/master-pdf-editor-3.5.81_amd64.deb
  dpkg -i ./master-pdf-editor*.deb
fi

# krop（PDF裁剪神器）
# More: http://arminstraub.com/software/krop
if [ ! -x "/usr/bin/krop" ]; then
  wget http://arminstraub.com/downloads/krop/krop_0.4.9-1_all.deb
  dpkg -i ./krop*.deb
  apt-get -y -f install
fi

# SpeedTest Python Script（A network speed test script）
wget -O - https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest_cli.py > /home/${u_name}/bin/speedtest_cli.py
chmod +x /home/${u_name}/bin/speedtest_cli.py &> /dev/null

# 百度网盘
# More: https://github.com/LiuLang/bcloud-packages
if [ ! -x "/usr/bin/bcloud-gui" ]; then
  wget https://github.com/LiuLang/bcloud-packages/raw/master/bcloud_3.8.2-1_all.deb
  dpkg -i bcloud*.deb
  apt-fast -f install -y
fi

# you-get
# More: https://github.com/soimort/you-get
if [ ! -x "/usr/bin/you-get" ]; then
  wget -O - https://github.com/soimort/you-get/archive/master.zip > "you-get.zip"
  7z x "you-get.zip" -o/opt
  find /opt/you-get-master/ -type d -exec chmod 755 {} \;
  echo 'you-get(){ python3 /opt/you-get-master/you-get $*; }' >> /home/${u_name}/.bashrc
fi

# TeamViewer QuickSupport
# More: http://www.teamviewer.com/en/download/linux/ 
if [ ! -x "/opt/teamviewerqs/tv_bin/script/teamviewer" ]; then
	wget http://download.teamviewer.com/download/teamviewer_qs.tar.gz
	tar -zxf teamviewer*.tar.gz -C /opt
	cat > /usr/share/applications/TeamViewerQS.desktop <<- 'END'
	[Desktop Entry]
	Encoding=UTF-8
	Name=TeamViewerQS 11
	Comment=TeamViewer Remote Control Application
	Exec=/opt/teamviewerqs/tv_bin/script/teamviewer
	Icon=/opt/teamviewerqs/tv_bin/desktop/teamviewer.png
	Type=Application
	Categories=Network;
	#Categories=Network;RemoteAccess;
	END
fi

# youtube-dl
# More: https://github.com/rg3/youtube-dl
#if [ ! -x "/usr/bin/youtube-dl" ]; then
  ULINK="$(wget --no-check-certificate -qO - https://rg3.github.io/youtube-dl/download.html|grep 'youtube-dl -O ' -|sed 's/\(.*\)\(http.*dl\ \)\(.*\)/\2/g')"
  wget --no-check-certificate -T 10 "${ULINK}" -O /usr/bin/youtube-dl
  if [ $? -ne 0 ] && pgrep lantern; then
    /usr/bin/proxychains wget --no-check-certificate -T 10 "${ULINK}" -O /usr/bin/youtube-dl
    chmod 755 /usr/bin/youtube-dl
  fi
#fi

#SoundWire(手机当电脑的移动音箱)
#More: http://georgielabs.net/ (可能要跳墙才能下载)
#For 32-bit: http://georgielabs.altervista.org/SoundWire_Server_linux32.tar.gz
#Andriod: https://play.google.com/store/apps/details?id=com.georgie.SoundWireFree
if [ ! -x "/opt/SoundWireServer/SoundWireServer" ]; then
	if pgrep lantern; then
		/usr/bin/proxychains wget http://georgielabs.altervista.org/SoundWire_Server_linux64.tar.gz
		tar -C /opt -xf SoundWire_Server_linux64.tar.gz

		if [ -x "/opt/SoundWireServer/SoundWireServer" ]; then
			cat > /usr/share/applications/SoundWire-Server.desktop <<- 'END'
			[Desktop Entry]
			Name=SoundWire Server
			Comment=Server program for SoundWire Android app
			Exec=/opt/SoundWireServer/SoundWireServer
			Icon=/opt/SoundWireServer/sw-icon.xpm
			Terminal=false
			Type=Application
			Categories=AudioVideo;Audio
			END

			chmod 644 /usr/share/applications/SoundWire-Server.desktop
			#sudo nice --19 ./SoundWireServer
			#sudo nice --19 ./SoundWireServer -nogui
			#configuration -- Built-in Audio -- Analog Stereo Input
		fi
	fi
fi

# 抓虾，命令行下高速下载网易云音乐，虾米的音乐
#wget -O - https://github.com/sk1418/zhuaxia/archive/master.zip > /tmp/zhuaxia.zip
#7z x /tmp/zhuaxia.zip -o/tmp/
#python /tmp/zhuaxia-master/setup.py install
#local commander_path="`find /usr/local/lib/python2.7/dist-packages -iname commander.py`"
#sed -ri 's/sleep\([[:digit:]]+\)/sleep\(0\)/g' ${commander_path}
#mkdir -p /home\/${u_name}/zhuaxia
#sed -i "s/^download\.dir.*/download\.dir\=\/home\/${u_name}\/zhuaxia/g" /home/${u_name}/.zhuaxia/zhuaxia.conf

# 酷我音乐盒
#wget -O - https://github.com/LiuLang/kwplayer-packages/archive/master.zip > kwplayer.zip
#7z x kwplayer.zip
#dpkg -i ./kwplayer-packages-master/python3-keybinder*.deb
#dpkg -i ./kwplayer-packages-master/kwplayer*.deb
#apt-fast install -f

# 网易云音乐命令行版本
# More: https://github.com/darknessomi/musicbox
#apt-fast install -y python-pip
#pip2 install NetEase-MusicBox
#apt-fast install mpg123

# Dropbox uploader (shell script)
# More: https://github.com/andreafabrizi/Dropbox-Uploader
#curl "https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh" -o dropbox_uploader.sh
#chmod +x dropbox_uploader.sh
#./dropbox_uploader.sh

##cow. https://github.com/cyfdecyf/cow (已安装Lantern，所以不装cow。个人实测cow没有Lantern好用)
#curl -L git.io/cow | bash
#mv ./cow /usr/local/bin/ && chmod +x /usr/local/bin/cow
#wget https://github.com/cyfdecyf/cow/raw/master/doc/init.d/cow -O /etc/init.d/cow
#chmod +x /etc/init.d/cow
##Should be check before running
#sed -i "s/=usr/=${u_name}/g" /etc/init.d/cow
#sed -i "s/=grp/=${u_name}/g" /etc/init.d/cow
#update-rc.d cow defaults
#sed -i 's/^listen.*//g' /home/${u_name}/.cow/rc
#echo "listen = http://127.0.0.1:8787" >> /home/${u_name}/.cow/rc
#echo "proxy = http://127.0.0.1:8788" >> /home/${u_name}/.cow/rc


# 5.4 Install APPs.     ## The last stage ## 
# Put the applications that slow download speeds and slow installation progress at the last stage.
############################################################################
echo -e "\n\n# 5.4 Install APPs.     ## The last stage ## " >> $LOG
for d in xubuntu-restricted-extras wireshark tshark wine1.8 chromium-browser pepperflashplugin-nonfree; do
  dpkg -s ${d} &> /dev/null || {
  apt-fast -y install ${d} || echo "Software: ${d} install failed" >> ${LOG}
  }
done

# Install MariaDB version 10.0
if [ ! -x "/usr/bin/mysql" ]; then
  apt-fast install software-properties-common -y
  apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
  add-apt-repository "deb http://mirrors.hustunique.com/mariadb/repo/10.0/ubuntu `lsb_release -cs` main"
  apt-fast update
  apt-fast install mariadb-server -y
  echo "You should do some settings manually to secure the MariaDB: " >> ${LOG}
  echo "sudo service mysql start" >> ${LOG}
  echo "sudo mysql_secure_installation" >> ${LOG}
fi

if ! `dpkg -s libdvdcss? &> /dev/null`; then
  /usr/share/doc/libdvdread4/install-css.sh
fi

# Set up wireshark to run without root privileges
if [ -x "/usr/bin/wireshark" ]; then
  groupadd -r wireshark
  usermod -a -G wireshark ${u_name}
  chgrp wireshark /usr/bin/dumpcap
  chmod 4755 /usr/bin/dumpcap
fi

# Some users find that they need to tell Chromium about the plugin.
if [ -s "/usr/sbin/update-pepperflashplugin-nonfree" ]; then
  if [ "$(/usr/sbin/update-pepperflashplugin-nonfree --status | awk '{print $NF}' | uniq | wc -l)" -eq 2 ]; then
    update-pepperflashplugin-nonfree --install
  fi
else
  echo "/usr/sbin/update-pepperflashplugin-nonfree dosen\'t exist" >> $LOG
fi

# Install the latest VirtualBox
if [ ! -x "/usr/bin/VBox" ]; then
  vb_ver="$(curl -q http://download.virtualbox.org/virtualbox/LATEST.TXT |cut -d. -f-2)"
  if `echo "${vb_ver}" + 3 | bc`; then
    echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" >> /etc/apt/sources.list.d/virtualbox.list
    wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
    apt-get update -o Dir::Etc::sourcelist="sources.list.d/virtualbox.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
    apt-fast install virtualbox-${vb_ver}
  fi
fi

#Foxit PDF Reader
#More: https://www.foxitsoftware.com/downloads/
#http://cdn01.foxitsoftware.com/pub/foxit/reader/desktop/linux/1.x/1.0/en_us/FoxitReader1.01.0925_Server_x64_enu_Setup.run.tar.gz
#aria2c -c 'https://www.foxitsoftware.com/downloads/latest.php?product=Foxit-Reader&platform=Linux-64-bit&version=1.0.1.0925&package_type=run&language=English'

#More: http://pad.haroopress.com/user.html (haroopad, Not only Markdown editor)
#if [ ! -x "/usr/bin/haroopad" ]; then
#  #aria2c -c https://bitbucket.org/rhiokim/haroopad-download/downloads/haroopad-v0.13.1-ia32.deb
#  aria2c -c https://bitbucket.org/rhiokim/haroopad-download/downloads/haroopad-v0.13.1-x64.deb
#  sudo dpkg -i ./haroopad*.deb
#fi

# User autostart config: /home/${u_name}/.config/autostart/
mkdir -p /home/${u_name}/.config/autostart
chown ${u_name}.${u_name} /home/${u_name}/.config/autostart

if [ ! -s "/home/${u_name}/.config/autostart/hddtemp.desktop" ]; then
	cat > /home/${u_name}/.config/autostart/hddtemp.desktop <<- 'END'
	[Desktop Entry]
	Encoding=UTF-8
	Version=0.9.4
	Type=Application
	Name=hddtemp
	Comment=Monitor hard drive temperature
	Exec=/usr/bin/nohup sh -c "/bin/sleep 120 && /usr/sbin/hddtemp -4 -d -l 127.0.0.1 /dev/sda /dev/sdb"
	OnlyShowIn=XFCE;
	StartupNotify=false
	Terminal=false
	Hidden=false
	END
fi

if [ ! -s "/home/${u_name}/.config/autostart/conky.desktop" ]; then
	cat > /home/${u_name}/.config/autostart/conky.desktop <<- 'END'
	[Desktop Entry]
	Encoding=UTF-8
	Version=0.9.4
	Type=Application
	Name=Conky
	Comment=conky
	Exec=/usr/bin/nohup sh -c "/bin/sleep 2 && /usr/bin/conky -qdc /home/kashu/.conkyrc"
	OnlyShowIn=XFCE;
	StartupNotify=false
	Terminal=false
	Hidden=false
	END
fi

if [ ! -s "/home/${u_name}/.config/autostart/caffeine-1.desktop" ]; then
	cat > /home/${u_name}/.config/autostart/caffeine-1.desktop <<- 'END'
	[Desktop Entry]
	Encoding=UTF-8
	Version=0.9.4
	Type=Application
	Name=caffeine
	Comment=deactivate the screensaver and sleep mode
	Exec=/usr/bin/nohup sh -c "/bin/sleep 600 && /usr/bin/caffeine-indicator &> /dev/null"
	OnlyShowIn=XFCE;
	StartupNotify=false
	Terminal=false
	Hidden=false
	END
fi

if [ ! -s "/home/${u_name}/.config/autostart/lantern.desktop" ]; then
	cat > /home/${u_name}/.config/autostart/lantern.desktop <<- 'END'
	[Desktop Entry]
	Encoding=UTF-8
	Version=0.9.4
	Type=Application
	Name=Lantern
	Comment=Lantern
	Exec=/usr/bin/nohup sh -c "/bin/sleep 7 && /usr/lib/lantern/lantern.sh -addr 0.0.0.0:8787 -startup=true &> /dev/null"
	OnlyShowIn=XFCE;
	StartupNotify=false
	Terminal=false
	Hidden=false
	END
fi

if [ ! -s "/home/${u_name}/.config/autostart/indicator-multiload.desktop" ]; then
	cat > /home/${u_name}/.config/autostart/indicator-multiload.desktop <<- 'END'
	[Desktop Entry]
	Encoding=UTF-8
	Name=System Load Indicator
	Name[en_GB]=System Load Indicator
	Comment[en_CA]=A system load monitor capable of displaying graphs for CPU, RAM, and swap space usage, plus network traffic.
	Exec=/usr/bin/nohup sh -c "/bin/sleep 3 && /usr/bin/indicator-multiload &> /dev/null &"
	Terminal=false
	Type=Application
	Icon=utilities-system-monitor
	Categories=GNOME;System;
	X-GNOME-Autostart-enabled=false
	END
fi

if [ -e "/usr/share/applications/indicator-multiload.desktop" ]; then
  sed -i '/^Exec/d' /usr/share/applications/indicator-multiload.desktop
  echo 'Exec=indicator-multiload --trayicon' >> /usr/share/applications/indicator-multiload.desktop
fi

chown -R ${u_name}.${u_name} /home/${u_name}/
chmod 664 /home/${u_name}/.config/autostart/*

#QQ
#Office

apt-fast update
apt-fast upgrade -y
apt-get autoremove -y
apt-get clean

### Discarded ###
## Disable some auto-start services
#for i in *mysql *nginx *hddtemp *speech-dispatcher *saned; do
#  find /etc/rc2.d/ -name "${i}" | rename 's/S/K/g'
#done
#
## Disable cups and cups-browsed services
#if ! `grep -Em1 ".*started.*runlevel" /etc/init/cups.conf | grep -sqE "^[[:space:]]?+#"`; then
#  sed -ri 's@(.*started.*runlevel)(.*)@\#\1\2@g' /etc/init/cups.conf
#  sed -i  '/^start on/a and (runlevel []))' /etc/init/cups.conf
#fi
#
#if ! `grep -Em1 ".*started.*runlevel" /etc/init/cups-browsed.conf | grep -sqE "^[[:space:]]?+#"`; then
#  sed -ri 's@(.*started.*runlevel)(.*)@\#\1\2@g' /etc/init/cups-browsed.conf
#  sed -i '/^start on/a and (runlevel []))' /etc/init/cups-browsed.conf
#fi
#
## Disable TFTP service
#if ! `grep -Em1 ".*start.*runlevel" /etc/init/tftpd-hpa.conf | grep -sqE "^[[:space:]]?+#"`; then
#  sed -ri 's/(.*start.*runlevel)(.*)/#\1\2/g' /etc/init/tftpd-hpa.conf
#  sed -ri '/.*start.*runlevel.*/a start on runlevel []' /etc/init/tftpd-hpa.conf
#fi
#
#update-rc.d -f hddtemp remove
#update-rc.d -f in.tftpd remove
#update-rc.d -f hostapd remove
#update-rc.d -f php5-fpm remove

# To toggle some services from starting or stopping permanently (you can start services manually when you need)
update-rc.d -f mysql remove
update-rc.d -f nginx remove
for SRV in nmbd smbd samba rpcbind hddtemp speech-dispatcher saned cups cups-browsed tftpd-hpa hostapd php5-fpm; do
  echo "manual" > /etc/init/${SRV}.override
done

echo "END: `date +%Y.%m.%d_%T`" >> $LOG
clear && ccze -A < $LOG
if pgrep lantern; then
  echo "Lantern is running:"
  ps -eo args | grep lantern | sort -u | grep '0.0.0.0'
fi

