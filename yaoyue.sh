#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Current folder
cur_dir=`pwd`
def_dir="/root"
# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
operation=(init logs restart delete bbr Exit version)
doc_name="soga"
github_url="https://raw.githubusercontent.com/xiaoyaohanyue/soga_docker/main"
github_dw_url="https://github.com/xiaoyaohanyue/soga_docker/raw/main"
# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

#Check system
check_sys(){
    local checkType=$1
    local value=$2

    release=''
    systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

get_char(){
    echo "any key connutie and CTRL+C exit"
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}


install_check(){
    if check_sys packageManager yum || check_sys packageManager apt; then
        if centosversion 5; then
            return 1
        fi
        return 0
    else
        return 1
    fi
}

install_dependencies(){
    echo -e "[${green}Info${plain}] Setting TimeZone to Shanghai"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"
    echo "install curl"
    ${systemPackage} install -y curl
}
bbr(){
	bash <(curl -L sh.xdmb.xyz/tcp.sh)
	sleep 5s
	get_char
}

#show last 100 line log

show_docker(){
dc_num=$(docker ps|grep ${doc_name} |awk -F " " '{print $NF}'|wc -l)
echo "docker name:"
for ((i=1;i<=${dc_num};i++))
do
show_name=`docker ps |grep ${doc_name} |awk -F " " '{print $NF}'|sed -n ${i}p`
echo
echo ${i}. ${show_name}
done
echo "please choose a name:"
echo
read cs_num
cs_name=`docker ps |grep ${doc_name} |awk -F " " '{print $NF}'|sed -n ${cs_num}p`
echo "your choose is ${cs_name}:"
}

logs(){
    echo "Last 100 line logs"
    show_docker
    docker logs --tail=100 ${cs_name}
    get_char
}
restart(){
    echo "restart docker"
    show_docker
    docker restart ${cs_name}
    get_char
}

delete(){
    echo "delete docker"
    show_docker
    docker rm -f ${cs_name}
    get_char
}


check_ins(){
    if type $1 >/dev/null 2>&1 
    then
    ins_stats=1
    else
    ins_stats=0
    fi
}
docker_install_ba(){
    check_sys
    if [ ${systemPackage} == "yum" ]
    then
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum install docker-ce docker-ce-cli containerd.io
    elif [ ${release} == "debian" ];then
    apt-get update
    apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
    curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/debian/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/debian $(lsb_release -cs) stable"
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io
    else
    apt-get update
    apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/ $(lsb_release -cs) stable"
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io
    fi
}

docker_compose_install(){
    curl -L "https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod a+x /usr/local/bin/docker-compose
    rm -f `which dc`
    ln -s /usr/local/bin/docker-compose /usr/bin/dc
    systemctl start docker
    systemctl enable docker.service
}
docker_install(){
    check_sys
    check_ins curl
    if [ ${ins_stats} -eq 0 ]
    then
    ${systemPackage} install -y curl
    fi
    check_ins docker
    if [ ${ins_stats} -eq 0 ]
    then
    curl -fsSL https://get.docker.com | bash
    echo "check and install docker-compose"
    check_ins docker-compose
    if [ ${ins_stats} -eq 0 ]
    then
    docker_compose_install
    fi
    else
    check_ins docker-compose
    if [ ${ins_stats} -eq 0 ]
    then
    docker_compose_install
    fi
    fi
    check_ins docker
    if [ ${ins_stats} -eq 0 ]
    then
    docker_install_ba
    echo "check and install docker-compose"
    check_ins docker-compose
    if [ ${ins_stats} -eq 0 ]
    then
    docker_compose_install
    fi
    else
    check_ins docker-compose
    if [ ${ins_stats} -eq 0 ]
    then
    docker_compose_install
    fi
    fi
}

Exit(){
    exit
}

pre_install_docker_compose(){
    # Set ssrpanel_container_name
    if [ "${is_copy}" == "n" ];then
    echo "docker容器名字"
    read -p "(Default value: yyg ):" container_name
    [ -z "${container_name}" ] && container_name=yyg
    echo
    echo "---------------------------"
    echo "容器名 = ${container_name}"
    echo "---------------------------"
    echo
    fi
    echo "节点ID"
    read -p "(Default value: 0 ):" node_id
    [ -z "${node_id}" ] && node_id=0
    echo
    echo "---------------------------"
    echo "node_id = ${node_id}"
    echo "---------------------------"
    echo
}

config_soga_v2ray()
{
    echo "Writing docker-compose.yml"
    mkdir -p yaoyue/soga/v2ray/${container_name} 
    cd yaoyue/soga/v2ray/${container_name} 
    curl -L ${github_url}/soga/v2ray/docker-compose.yml > docker-compose.yml
    echo "enter your web url"
    echo
    read soga_web
    echo "enter your web token"
    echo
    read soga_key
    echo "enter your soga lisence"
    echo
    read soga_lisence
    sed -i "s|node_id:.*|node_id: ${node_id}|"  ./docker-compose.yml
    sed -i "s|container_name:.*|container_name: ${container_name}|"  ./docker-compose.yml
    sed -i "s|webapi_url:.*|webapi_url: ${soga_web}|" ./docker-compose.yml
    sed -i "s|webapi_key:.*|webapi_key: ${soga_key}|" ./docker-compose.yml
    sed -i "s|soga_key:.*|soga_key: ${soga_lisence}|" ./docker-compose.yml
    sed -i "s|- \"/etc/soga/:/etc/soga/\"|- \"/yaoyue/soga/v2ray/${container_name}/etc/soga/:/etc/soga/\"|" ./docker-compose.yml
    
}
init(){
    cd ${def_dir}
    docker_install
    config_soga_v2ray
    docker-compose up -d
    if [ ${systemPackage} == "apt" ]
    then
    echo "0 4 * * * /usr/bin/docker restart ${container_name}" >> /var/spool/cron/crontabs/root
    else
    echo "0 4 * * * /usr/bin/docker restart ${container_name}" >> /var/spool/cron/root
    fi
}

yyver(){
    echo "The version: yaoyue 20220507A"
    echo "return after 5s"
    sleep 5s
}

# Initialization step
initial(){
    clear
    while true
    do
    echo "---------------------------"
    echo "welcome to 妖月脚本"
    echo "built by @xyhy919"
    echo "---------------------------"
    echo  "Which operation you'd select:"
    for ((i=1;i<=${#operation[@]};i++ )); do
        hint="${operation[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Please enter a number (Default ${operation[0]}):" selected
    [ -z "${selected}" ] && selected="1"
    case "${selected}" in
        1|2|3|4|5|6|7)
        echo
        echo "You choose = ${operation[${selected}-1]}"
        echo
        ${operation[${selected}-1]}
        break
        ;;
        *)
        echo -e "[${red}Error${plain}] Please only enter a number [1-${#operation[@]}]"
        ;;
    esac
    done
}

install_dependencies
while true
do
initial
done
