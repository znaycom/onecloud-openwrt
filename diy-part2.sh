#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
 
# Modify default IP
sed -i 's/192.168.1.1/192.168.10.99/g' package/base-files/files/bin/config_generate
 
# Modify hostname
sed -i 's/LEDE/OneCloud/g' package/base-files/files/bin/config_generate
 
# 替换终端为bash
sed -i 's/\/bin\/ash/\/bin\/bash/' package/base-files/files/etc/passwd
 
# ============ 集成 OpenClash 插件（按官方说明拷贝 luci-app-openclash 目录）============
git clone -b master --depth 1 https://github.com/vernesong/OpenClash /tmp/OpenClash \
  && cp -a /tmp/OpenClash/luci-app-openclash package/luci-app-openclash \
  && echo "OK: OpenClash 插件已集成"
 
# ============ 预置 Meta 内核（mihomo 官方二进制，ARMv7）============
# 固化到固件里，设备开机即可用，无需联网下载内核
mkdir -p files/etc/openclash/core
MIHOMO_TAG=$(curl -sL --connect-timeout 30 --retry 2 "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)
echo "mihomo 内核版本: ${MIHOMO_TAG}"
if [ -n "${MIHOMO_TAG}" ]; then
  curl -fL --connect-timeout 30 --retry 3 -o /tmp/mihomo.gz \
    "https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_TAG}/mihomo-linux-armv7-${MIHOMO_TAG}.gz" \
    && gunzip -f /tmp/mihomo.gz \
    && mv /tmp/mihomo files/etc/openclash/core/clash_meta \
    && chmod +x files/etc/openclash/core/clash_meta \
    && echo "OK: Meta 内核已预置"
else
  echo "WARN: 内核版本号获取失败，编译会继续；装好系统后可在 OpenClash 界面手动更新内核"
fi
 
# ============ 预置分流数据库（运行时文件名以 OpenClash 约定为大写开头）============
dl_geo() {
  curl -fL --connect-timeout 30 --retry 3 -o "files/etc/openclash/$2" \
    "https://github.com/MetaCubeX/meta-rules-dat/releases/latest/download/$1" \
    && echo "OK: $2 已预置" || echo "WARN: $2 下载失败，不影响编译"
}
dl_geo geoip.dat GeoIP.dat
dl_geo geosite.dat GeoSite.dat
dl_geo country.mmdb Country.mmdb
