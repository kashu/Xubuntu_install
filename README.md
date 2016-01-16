#脚本功能（最佳运行环境：Xubuntu 14.04.x 64-bit）：
###脚本运行的时间取决于你的网速的快慢，网速越快，脚本越快跑完
1. /etc/sysctl.conf  ~/.bashrc  ~/.inputrc（脚本会自动给这几个用户配置文件添加一些设置，里面浓缩了很多精华）
2. 自动检测电脑中SSD硬盘是否支持TRIM，并开启系统对TRIM的支持
3. 把/tmp放到内存中能极大提升系统运行，取内存75%的容量作为/tmp的使用空间
4. 自动下载github上最新的hosts文件（一直在用，妥妥的），用于跳墙
5. 自动解决英文语言系统中的vim无法完美显示中文的问题
6. 自动生成~/.conkyrc配置文件
7. 自动删除系统中不需要的应用程序（蓝牙支持我也删了，因为我笔记本没蓝牙 :P  。 注，如果你要用蓝牙，那就把blueman删除）
printer-driver* abiword* gnumeric* thunderbird xfce4-dict xchat* pidgin* xfburn gnome-mines gnome-sudoku parole gmusicbrowser transmission* simple-scan blueman
8. 安装apt-fast，大幅提升软件安装、系统更新、升级的速度，提高效率节约时间
9. 启用Canonical Partners的软件源（系统自动默认是未启用的）
11. 更新、升级整个系统
12. 自动检测以下软件是否已安装，如果没安装，则自动安装（注：这里安装了KVM，我自己是碰不到不支持64位指令集的CPU了。没关系，装不了就跳过）：
vim ssh conky openssh-server dstat htop curl iotop iptraf nethogs sysv-rc-conf rdesktop shutter p7zip p7zip-full p7zip-rar preload meld ccze lynx html2text gparted optipng parallel proxychains wavemon sox audacity convmv xchm hddtemp hostapd isc-dhcp-server bum byzanz sysstat enca filezilla ntpdate exfat-fuse exfat-utils dconf-tools pv tftpd-hpa tftp-hpa dsniff lxc shellcheck git virt-manager qemu-system qemu-kvm lxc python-setuptools python3-setuptools remmina cmake gksu
13. 生成/etc/proxychains.conf代理配置文件，默认使用http://127.0.0.1:8787（是的，Lantern），给后续软件的安装提供方便
14. 自动检测以下PPA是否已添加，如果没添加，则自动添加（如果你的网络被GFW或ISP给fuck了，那可能会有一两个PPA添加不成功，相应的软件可能无法安装，这个也不好说，即使被fuck了，可能也能正常安装。别管那么多，后面会自动跳墙的）：
ppa:fcitx-team/nightly ppa:linrunner/tlp ppa:pi-rho/security ppa:nilarimogard/webupd8 ppa:noobslab/indicators ppa:ubuntu-wine/ppa ppa:coolwanglu/pdf2htmlex ppa:diodon-team/stable ppa:gezakovacs/ppa ppa:mc3man/trusty-media ppa:lzh9102/qwinff ppa:maarten-baert/simplescreenrecorder ppa:otto-kesselgulasch/gimp ppa:plushuang-tw/uget-stable ppa:stebbins/handbrake-releases ppa:team-xbmc/ppa ppa:webupd8team/y-ppa-manager ppa:wseverin/ppa ppa:thomas-schiex/blender ppa:pinta-maintainers/pinta-stable ppa:zanchey/asciinema
15. 自动检测并安装Nginx
16. 自动检测以下软件是否已安装，如果没安装，则自动安装：
fcitx-table-wbpy tlp tlp-rdw nmap hydra audacious indicator-multiload indicator-sensors caffeine pdf2htmlex diodon unetbootin vlc ffmpeg qwinff simplescreenrecorder uget handbrake-gtk kodi y-ppa-manager linssid blender pinta ppa-purge asciinema php5-fpm
17. 升级gimp，把旧版本升级成新版本
18. 自动更改uGet的配置文件，让它默认使用aria2c………
19. 安装PAC Manager, Lantern, Master PDF Editor, krop, speedtest_cli.py, bcloud, you-get, youtube-dl, SoundWire, 优化Lantern的启动设置并自动启动Lantern
20. 安装xubuntu-restricted-extras, wireshark, wine1.8, chromium-browser, pepperflashplugin-nonfree, MariaDB 10.0， VirtualBox
21. 自动添加用户的开机自启动项，让它们在合理的时间里自动起来（避免所有自启动程序挤在一块启动，这会导致用户登陆慢或开机慢的体验。这里我分散了启动时间……）：hddtemp， conky， caffeine， lantern， indicator-multiload（还有一些，只能让用户根据自己的需要来设置了）

22. 最后，显示安装的日志内容在当前屏幕上，你看着办吧： /tmp/installation_`date +%Y.%m.%d_%T`.log
一切顺利的话，你根本看不到什么有用的日志内容
不太顺利的话，你可能会看到那么几行有用的，此时你可选择重新执行脚本（脚本可反复执行，功能不受影响），可选择跳墙并重新执行脚本。

如果你想了解这个脚本，可以放在虚拟机运行体验一下……

脚本看着用点乱，其实整体结构还是挺清晰的，几大块的功能所对应的代码都有组织有次序的堆放在相应的区块中。可以快速地修改，添加，删除。

##如果脚本中有什么错误或遗漏的地方，或者你有更好的想法、绝招，请给我留言，我会不断完善的，谢谢！
