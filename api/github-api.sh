#!/bin/bash


function github_username {
    local api_url="${GITHUB_BASE_EDP}/user"
    local ok_code="200"
    curl -is -H "Authorization: token ${GITHUB_TOKEN}" ${api_url} | http_success "${ok_code}" | awk '
        BEGIN { ret=100 }
        /login/ { 
            user_name=$2
            gsub(/[",]/, "", user_name)
            printf("%s\n", user_name)
            ret=0
        }
        END {
            exit ret
        }
    '
    

}

function http_success {
    awk -v OK_CODE="$1" '
        BEGIN { ret=100 }
        { print $0 }
        /Status: / {
            status=$2
            ret = (OK_CODE==status) ? 0 : 100;
        }
        END { exit ret }
    '
}

function github_list_repo {
    local api_url="https://api.github.com/user/repos"
    local ok_code="200"
    curl -is -H "Authorization: token ${GITHUB_TOKEN}" ${api_url} | http_success "${ok_code}"
}

function fetch_repo_info {
    local repo=$1
    local item=$2
    awk -v FS='"[ ]*:' -v REPO="${repo}" -v ITEM="${item}" '
            function trim(str) {
                gsub(/^[ "]*|[" ,]*$/, "", str)
                return str
            }
            BEGIN { ret=100 }
            {
                # gsub(/[\",]/, "")
                # gsub(/^[ \s\t]*|[ \s\t]*$/, "")
                # gsub(/[ \s\t]*:|:[ \s\t]*/, "")
                key=trim($1)
                value=trim($2)
                # printf("name=[%s] value=[%s]\n", key, value)
                if("name"==key) repo_name=value
                if(key==ITEM && repo_name==REPO) {
                    printf("%s\n", value)
                    ret=0
                }

            }
            END { exit ret }
    '
}

function github_repoinfo {
    local repo_name=$1
    local key=$2
    github_list_repo | fetch_repo_info "${repo_name}" "${key}"

}

function get_pub_key {
    local repo_name=$1
    local PUB_KEY_FILE="${CONF_DIR:=/data/hooks/conf}/${repo_name}_git_id_rsa.pub"
    local GIT_PRVKEY="${CONF_DIR}/${repo_name}_git_id_rsa"
    [ -f "${GIT_PRVKEY}" ] || {
        ssh-keygen -N "" -q -f "${GIT_PRVKEY}" || { printf "could not create private key\n"; exit 20; }
    }
    GIT_PUBKEY="$(cat ${PUB_KEY_FILE})"
    [ -n "${GIT_PUBKEY}" ] || { printf "could not access public key\n"; exit 50; }
}

function github_repo_addkey {
    local repo_name=$1
    local key=$2
    local user=$(github_username)
    local ok_code="201"
    get_pub_key "${repo_name}"
    [ -n "${user}" ] || { printf "could not access user info\n"; exit 30; }
    local api_url="${GITHUB_BASE_EDP}/repos/${user}/${repo_name}/keys"
    local data="{\"title\": \"github-api\", \"key\": \"${GIT_PUBKEY}\", \"read_only\": false}"
    curl -is -d "${data}" -H "Authorization: token ${GITHUB_TOKEN}" -X POST ${api_url} | http_success "${ok_code}"  > /dev/null 2>&1
    
}


function github_create_repo {
    local repo_name=$1
    local api_url="https://api.github.com/user/repos"
    local data="{ \"name\": \"${repo_name}\", \"private\": true }"
    local ok_code=201
    curl -is -d "${data}" -H "Authorization: token ${GITHUB_TOKEN}" ${api_url} | http_success "${ok_code}"
}

function init_param {
    CONF_FILE="${CONF_DIR:=/data/hooks/conf}/github.cfg"
    GITHUB_BASE_EDP="https://api.github.com"
    [ -f "${CONF_FILE}" ] && . "${CONF_FILE}"

    
    # [ -n "${GITHUB_TOKEN}" ] || GITHUB_TOKEN=
    # [ -f "${GITHUB_TOKEN}" ] && read GITHUB_TOKEN < "${GITHUB_TOKEN}"
    # local token="Authorization: token ${GITHUB_TOKEN}"
    # CURL_CMD="curl -is -H \"${token}\" "
}

function usage() {
    { 
        echo 'Usage :' 
        echo "${EXECFILE} [COMMON_OPT] [ACTION] [REPO]    " 
        echo "COMMON_OPT :                                                                                " 
        echo '  -a|--action ACTION      : action to do                                                    ' 
        echo '  -t|--token API_TOKEN    : github private token                                            ' 
        echo '  -r|--repo REPOSITORY    : repository name                                                 ' 
    } 1>&2
    exit 2
}


function parse_param {
    LEFT_ARGS=""
    TEMP=`getopt -a -o a:t:r:k:i: --long action:,token:,repo:,key:,item:,create,help -- "$@"` || usage
    eval set -- "$TEMP"
    while true; do
        case "$1" in
            -a|--action) ACTION="$2"; shift 2;;
            -t|--token) TOKEN="$2"; shift 2;;
            -r|--repo)  REPO="$2"; shift 2;;
            -i|--item) ITEM_KEY="$2"; shift 2;;
            -k|--key) KEY="$2"; shift 2;;
            --create) CREATE_ON_NOTFOUND=1; shift 1;;
            --) shift; break;;
            *) usage ; break;;
        esac
    done

    #LEFT_ARGS="$@"
    for i in "$@"; do
        LEFT_ARGS="${LEFT_ARGS} '${i}' "
    done
}


## parse arguments and opt


[[ "$1" =~ ^- ]] && {
    parse_param "$@" || exit 2
    #printf "param : %s\n"  "${param_str}"
    eval set -- ${LEFT_ARGS}
}

ARGC=$#
[ -n "${ACTION}" ] || ACTION="$1"
[ -n "${REPO}" ] || REPO="$2"

init_param

case ${ACTION} in 
repo_info) {
        if [ -z "${REPO}" ] || [ -z "${ITEM_KEY}" ];  then
            REPO=${KEY%%:*}
            ITEM_KEY=${KEY##*:}
        fi
        github_repoinfo "${REPO}" "${ITEM_KEY:=ssh_url}" || {
            [ -n "${CREATE_ON_NOTFOUND}" ] && { github_create_repo "${REPO}" | fetch_repo_info "${REPO}" "${ITEM_KEY}" ; } && github_repo_addkey "${REPO}"
        }
    }  ;;
repo_create) {
    github_create_repo "${REPO}" 
} ;;
repo_addkey) {
    github_repo_addkey "${REPO}"
} ;;
username) {
    github_username 
} ;;
*) ;;
esac