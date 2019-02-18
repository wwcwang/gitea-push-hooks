# git-hooks

hooks script for gitea webhooks to sync repo to github

Usage : 
    1. put all scripts in /data/hooks, and add your github token in /data/hooks/conf/github.cfg as follows : <br>
        GITHUB_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  <br>
    2. make sure . correct permmisons for the following dir:  <br>
        /data/hooks  <br> 
        /data/hooks/api  <br>
        /data/hooks/conf <br>
        /data/hooks/log <br>
    2. for gitea repository, set recieve hooks as follows : <br>
        /data/hooks/git-remote.sh push github <br>
    3. DO NOT USE FOR NEW CREATED and UNINITIALIZED REPO. Due to gitea bugs, uninitialized repo use this script will remain uninitialized forever. You must make a push before use this script. <br>
    4. Only githbub is supported now, BitBucket/Gitee will be supported later. <br>

    then, the post receive hooks of gitea will auto create new repository in github if not exist and sync gitea repo to github after each push <br>
