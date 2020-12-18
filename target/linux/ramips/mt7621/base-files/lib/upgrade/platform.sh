#
# Copyright (C) 2010 OpenWrt.org
#

PART_NAME=firmware
REQUIRE_IMAGE_METADATA=1

RAMFS_COPY_BIN='fw_printenv fw_setenv'
RAMFS_COPY_DATA='/etc/fw_env.config /var/lock/fw_printenv.lock'

platform_check_image() {
	return 0
}

platform_do_upgrade() {
	local board=$(board_name)

	case "$board" in
	alfa-network,quad-e4g)
		[ "$(fw_printenv -n dual_image 2>/dev/null)" = "1" ] &&\
		[ -n "$(find_mtd_part backup)" ] && {
			PART_NAME=backup
			if [ "$(fw_printenv -n bootactive 2>/dev/null)" = "1" ]; then
				fw_setenv bootactive 2 || exit 1
			else
				fw_setenv bootactive 1 || exit 1
			fi
		}
		;;
	mikrotik,routerboard-750gr3|\
	mikrotik,routerboard-760igs|\
	mikrotik,routerboard-m11g|\
	mikrotik,routerboard-m33g)
		[ -z "$(rootfs_type)" ] && mtd erase firmware
		;;
	asus,rt-ac65p|\
	asus,rt-ac85p)
		echo "Backing up firmware"
		dd if=/dev/mtd4 bs=1024 count=4096  > /tmp/backup_firmware.bin
		dd if=/dev/mtd5 bs=1024 count=52224 >> /tmp/backup_firmware.bin
		mtd -e firmware2 write /tmp/backup_firmware.bin firmware2
		;;
	esac

	case "$board" in
	asus,rt-ac65p|\
	asus,rt-ac85p|\
	dlink,dir-1960-a1|\
	dlink,dir-2640-a1|\
	dlink,dir-2660-a1|\
	hiwifi,hc5962|\
	linksys,ea7300-v1|\
	linksys,ea7300-v2|\
	linksys,ea7500-v2|\
	netgear,r6220|\
	netgear,r6260|\
	netgear,r6350|\
	netgear,r6700-v2|\
	netgear,r6800|\
	netgear,r6850|\
	netgear,wac104|\
	netgear,wac124|\
	netis,wf2881|\
	xiaomi,mi-router-3g|\
	xiaomi,mi-router-3-pro|\
	xiaomi,mi-router-ac2100|\
	xiaomi,redmi-router-ac2100)
		nand_do_upgrade "$1"
		;;
	iodata,wn-ax1167gr2|\
	iodata,wn-ax2033gr|\
	iodata,wn-dx1167r)
		iodata_mstc_upgrade_prepare
		nand_do_upgrade "$1"
		;;
	ubnt,edgerouter-x|\
	ubnt,edgerouter-x-sfp)
		platform_upgrade_ubnt_erx "$1"
		;;
	zyxel,wap6805)
		local kernel2_mtd="$(find_mtd_part Kernel2)"
		[ "$(hexdump -n 4 -e '"%x"' $kernel2_mtd)" = "56190527" ] &&\
		[ "$(hexdump -n 4 -s 104 -e '"%x"' $kernel2_mtd)" != "0" ] &&\
		dd bs=4 count=1 seek=26 conv=notrunc if=/dev/zero of=$kernel2_mtd 2>/dev/null &&\
		echo "Kernel2 sequence number was reset to 0"
		CI_KERNPART="Kernel"
		nand_do_upgrade "$1"
		;;
	*)
		default_do_upgrade "$1"
		;;
	esac
}