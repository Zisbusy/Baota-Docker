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
O_pl=$(cat /www/server/panel/data/o.pl)

# 备份数据库
backup_database() {
  if [ -d "${Data_Path}" ] && [ ! -z "$(ls -A ${Data_Path})" ]; then
    if [ ! -d "${Setup_Path}" ] || [ -z "$(ls -A ${Setup_Path})" ]; then
      timestamp=$(date +"%s")
      tar czf /www/server/data_backup_$timestamp.tar.gz -C ${Data_Path} .
    fi
  fi
}

# 恢复面板数据：如果 /www 目录为空或缺失，则从压缩包解压
restore_panel_data() {
  if [ -f /www.tar.gz ]; then
    if [ ! -d /www ] || [ -z "$(ls -A /www)" ] || [ ! -d /www/server/panel ] || [ -z "$(ls -A /www/server/panel)" ] || [ ! -d /www/server/panel/pyenv ] || [ -z "$(ls -A /www/server/panel/pyenv)" ]; then
      echo "恢复面板数据..."
      tar xzf /www.tar.gz -C / --skip-old-files
      # rm -rf /www.tar.gz
    fi
  fi
}

soft_start(){
    # 扫描并启动所有服务
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

restore_panel_data > /dev/null
backup_database > /dev/null
is_empty_Data > /dev/null
init_mysql > /dev/null
start_mysql > /dev/null
soft_start > /dev/null
#tail -f /dev/null
${init_path}/bt log
