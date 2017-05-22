#!/bin/bash
function s
{
if [[ "$@" == *@* ]];
        then
               ssh -t "$@" "bash -i -o vi"
        else
               ssh -t root@"$@" "bash -i -o vi"
 fi
}
s "$@"


#https://github.com/Aricg/portable_env
#set session
session="$RANDOM"
 
#assume root if possible
if ! [[ "$@" == *@* ]]; then
  connect="root@"$@""
else
  connect="$@"
fi
 
#copy files.
for x in ~/.portable_env/*
  do
    scp "$x" "$connect":~/".""$session""$(basename "$x")" 2>&1 >/dev/null
  done
      
#Let's do this
ssh -t "$connect" "echo "$session" > ~/.session && bash --noprofile --rcfile ~/."$session"bashrc"


# 
###### Stuff needed for portable_env to work #######
if [[ -f ~/.session ]]; then
  session=$(< ~/.session)
  echo $session > ~/."$session"sessionid
  rm -f ~/.session
  session=$(< ~/."$session"sessionid)
fi
 
#trap all files on exit only trap if session is set
if ! [[ -z "$session" ]]; then
trap "rm -f ~/"."$session"* EXIT
fi
##### End Stuff needed for portable_env to work ####


#example alias (for your vimrc)
if [[ -f ~/."$session"vimrc ]]; then
    alias v="vim -u ~/."$session"vimrc"
fi