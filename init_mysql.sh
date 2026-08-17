#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

Root_Path=`cat /var/bt_setupPath.conf`
Setup_Path=$Root_Path/server/mysql
Data_Path=$Root_Path/server/data

Mysql_Initialize(){
    if [ -d "${Data_Path}" ]; then
        check_z=$(ls "${Data_Path}")
        if [[ ! -z "${check_z}" ]]; then
            return
        fi
    fi

    mkdir -p ${Data_Path}
    chown -R mysql:mysql ${Data_Path}
    chgrp -R mysql ${Setup_Path}/.

    ${Setup_Path}/bin/mysqld --initialize-insecure --basedir=${Setup_Path} --datadir=${Data_Path} --user=mysql

    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
${Setup_Path}/lib
EOF
    ldconfig
    ln -sf ${Setup_Path}/lib/mysql /usr/lib/mysql
    ln -sf ${Setup_Path}/include/mysql /usr/include/mysql
    /etc/init.d/mysqld start
    sleep 3

    echo "设置 MySQL 密码..."
    # 生成随机密码
    mysqlpwd=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 16)
    # 调用 bt 命令设置 MySQL密码
    # ${Setup_Path}/bin/mysqladmin -u root password "${mysqlpwd}"
bt <<EOF
7
${mysqlpwd}
EOF

    # 清理安装残留
    cd "${Setup_Path}"
    rm -f src.tar.gz
    rm -rf src
}

Mysql_Initialize
