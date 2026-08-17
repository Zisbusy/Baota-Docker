#!/bin/bash
# ==========================================
# 宝塔面板 Docker 容器入口脚本 (bt.sh)
# 功能：初始化环境、恢复面板数据、启动 MySQL 及其他服务
# ==========================================

echo "Docker 版本宝塔面板启动..."
echo "设置系统变量..."
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 定义基础路径变量
init_path=/etc/init.d
Root_Path=`cat /var/bt_setupPath.conf`
Setup_Path=$Root_Path/server/mysql
Data_Path=$Root_Path/server/data

# 备份数据库
backup_database() {
  if [ -d "${Data_Path}" ] && [ ! -z "$(ls -A ${Data_Path})" ]; then
    if [ ! -d "${Setup_Path}" ] || [ -z "$(ls -A ${Setup_Path})" ]; then
      timestamp=$(date +"%s")
      tar czf /www/server/data_backup_$timestamp.tar.gz -C ${Data_Path} .
    fi
  fi
}

# 初始化面板逻辑
restore_panel_data() {
  if [ ! -f /www/.panel_restored ]; then
      echo "首次启动，初始化面板数据..."
      # 直接覆盖写入，已有文件自动跳过，绝不删除任何现有数据
      tar xzf /tmp/www.tar.gz -C / --skip-old-files
      # 创建标记文件
      touch /www/.panel_restored
      echo ""
      echo "=============================================="
      echo "  宝塔面板初始化成功"
      echo "=============================================="
      echo "  管理地址: http://<您的IP>:8888/btpanel"
      echo "  默认用户: btpanel"
      echo "  默认密码: btpaneldocker"
      echo "=============================================="
      echo ""
  fi
}

# 扫描并启动所有服务
soft_start(){
    echo "扫描并启动所有服务..."
    init_scripts=$(ls ${init_path})
    for script in ${init_scripts}; do
        case "${script}" in
        "bt"|"mysqld"|"nginx"|"httpd")
            continue
            ;;
        esac

        ${init_path}/${script} start
    done

    if [ -f ${init_path}/nginx ]; then
        ${init_path}/nginx start
    elif [ -f ${init_path}/httpd ]; then
        ${init_path}/httpd start
    fi

    ${init_path}/bt stop
    ${init_path}/bt start

    pkill crond
    /sbin/crond

    chmod 600 /etc/ssh/ssh_host_*
    /usr/sbin/sshd -D &
}

# 初始化 MySQL
init_mysql(){
    echo "初始化 MySQL..."
    if [ "${O_pl}" != "docker_btlamp_d12" ] && [ "${O_pl}" != "docker_btlnmp_d12" ];then
        return
    fi
    if [ -d "${Data_Path}" ]; then
        check_z=$(ls "${Data_Path}")
        echo "check_z:"
        echo ${check_z}
        if [[ ! -z "${check_z}" ]]; then
            echo "check_z is not empty"
            return
        fi
    fi
    if [ -f /init_mysql.sh ] && [ -d "${Setup_Path}" ];then
        sh /init_mysql.sh
        rm -f /init_mysql.sh
    fi
}

is_empty_Data(){
    return "$(ls -A ${Data_Path}/|wc -w)"
}

start_mysql(){
    if [ -d "${Setup_Path}" ] && [ -f "${init_path}/mysqld" ];then
        chown -R mysql:mysql ${Data_Path}
        chgrp -R mysql ${Setup_Path}/.
        ${init_path}/mysqld start
    fi
}

restore_panel_data > 2>/dev/null
O_pl=$(cat /www/server/panel/data/o.pl)
backup_database > 2>/dev/null
is_empty_Data > 2>/dev/null
init_mysql > 2>/dev/null
start_mysql > 2>/dev/null
soft_start > 2>/dev/null
#tail -f 2>/dev/null
${init_path}/bt log
