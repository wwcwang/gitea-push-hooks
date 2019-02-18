# git-hooks

hooks script for gitea webhooks to sync repo to github

Usage : 
    1. put all scripts in /data/hooks, and add your github token in /data/hooks/conf/github.cfg as follows :
        GITHUB_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    2. make sure . correct permmisons for the following dir:
        /data/hooks
        /data/hooks/api
        /data/hooks/conf
        /data/hooks/log
    2. for gitea repository, set recieve hooks as follows :
        /data/hooks/git-remote.sh push github
    3. DO NOT USE FOR NEW CREATED and UNINITIALIZED REPO. Due to gitea bugs, uninitialized repo use this script will remain uninitialized forever. You must make a push before use this script.
    4. Only githbub is supported now, BitBucket/Gitee will be supported later.

    then, the post receive hooks of gitea will auto create new repository in github if not exist and sync gitea repo to github after each push