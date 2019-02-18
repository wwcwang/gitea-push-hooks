#!/bin/bash

#auto mirror local repository to remote git server:github/bitbucket

readonly ACTION=$1
#readonly REMOTE_SERVER=GITHUB
readonly REMOTE_SERVER=$2
REPO_NAME=$3
[ -n "${REPO_NAME}" ] || REPO_NAME="$(basename $(pwd) .git)"
readonly REPO_NAME

readonly BASE_DIR=/data
readonly HOOKS_DIR="${BASE_DIR}/hooks"
readonly API_DIR="${HOOKS_DIR}/api"
readonly CONF_DIR="${HOOKS_DIR}/conf"
readonly LOG_DIR="${HOOKS_DIR}/log"
readonly GITHUB_API="${API_DIR}/github-api.sh"
readonly GIT_PRVKEY="${CONF_DIR}/${REPO_NAME}_git_id_rsa"
readonly LOG_FILE="${LOG_DIR}/git-remote.log"

[ -d "${LOG_DIR}" ] && mkdir -p "${LOG_DIR}"

exec > >(tee -a "${LOG_FILE}") 2>&1

[ -f "${GIT_PRVKEY}" ] || {
    ssh-keygen -N "" -q -f "${GIT_PRVKEY}" || { printf "could not create private key\n"; exit 20; }
}

case ${REMOTE_SERVER:=github} in 
    GITHUB|github) REMOTE_API="${GITHUB_API}" ;;
    BITBUCKET) REMOTE_API="${BITBUCKET_API}" ;;
    GITEE|gitee) REMOTE_API="${GITEE_API}" ;;
esac 

function git_remote_repo {
    local readonly remote_server=$1
    git remote -v | grep -i "${remote_server}" | tail -1 | awk '{print $1}'
}

REMOTE_NAME=$(git_remote_repo "${REMOTE_SERVER}")
[ -n "${REMOTE_NAME}" ] || { 
    REMOTE_NAME=${REMOTE_SERVER}
    readonly REMOTE_REPO_SSH_URL=$("${REMOTE_API}" --action repo_info --key "${REPO_NAME}:ssh_url" --create )
    [ -n "${REMOTE_REPO_SSH_URL}" ] || { 
        printf "Could not access remote repository on ${REMOTE_SERVER}\n"
        exit 10
    }
    git remote add ${REMOTE_NAME} ${REMOTE_REPO_SSH_URL} && printf "added remote %s : %s\n" "${REMOTE_NAME}" "${REMOTE_REPO_SSH_URL}"

}

case ${ACTION:=push} in 
push|PUSH) git_cmd="git push  --mirror --atomic " ;;
pull|PULL) git_cmd="git pull " ;;
esac

GIT_SSH_COMMAND="ssh -i ${GIT_PRVKEY} -o StrictHostKeyChecking=no " ${git_cmd}  "${REMOTE_NAME}"  
if [ $? -eq 0 ]; then
    printf "\e[31mpush to %s successfully\e[39m\n" "${REMOTE_NAME}"
else
    printf "\e[31mpush to %s failed\e[39m\n" "${REMOTE_NAME}"
fi