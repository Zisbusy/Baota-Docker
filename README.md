# Baota-Docker
Docker中运行宝塔面板


## 概述
宝塔官方的镜像似乎没有稳定版本，参考已有的项目基于Debian12进项自动化构建Docker镜像

## 镜像信息
 - 可自由挂载/www及其之下的任何目录
 - 建议直接挂载到/www，包含全部的运行环境，方便全息备份，迁移数据，重新部署
 - 也可按需最小化挂载
 - 容器里面的网站数据目录：/www/wwwroot
 - MySQL数据目录：/www/server/data
 - vhost文件路径：/www/server/panel/vhost
 - 面板管理地址：http://您的ip地址:8888/btpanel
 - 默认用户：username
 - 默认密码：password
