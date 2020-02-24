#https://wiki.mozilla.org/ReleaseEngineering/Tips_And_Tricks#Shell
# set an ssh key expiry within your agent
renew_ssh_agent ()
{
    (umask 066; ssh-agent > ~/.ssh/ssh-agent)
    eval "$(<~/.ssh/ssh-agent)" >/dev/null
}

start_ssh_agent ()
{
    if [ ! -f ~/.ssh/ssh-agent ]; then
        renew_ssh_agent
    else
        eval "$(<~/.ssh/ssh-agent)" >/dev/null
    fi

    ssh-add -l &>/dev/null
    ssh_add_rc="$?"
    if [ $ssh_add_rc = 1 ] || [ $ssh_add_rc = 2 ]; then
       if [ $ssh_add_rc = 2 ]; then
           # ssh-agent defined in ~/.ssh/ssh-agent doesn't exist, recreate
           renew_ssh_agent
       fi
       # set timelimit to 4 hours
       ssh-add -t 14400
   fi
}
start_ssh_agent
