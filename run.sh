#!/bin/bash

#LOGIN DATA
USR=username
PWD=pa$$word
#CHECK AND CREATE CONFIG
WORKDIR=/tmp/LF
ICON="$WORKDIR/favicon.ico"

if ! [ -d $WORKDIR ]; then
    mkdir $WORKDIR
fi

if ! [ -f $ICON ]; then
    wget http://linuxforum.ru/favicon.ico -O $ICON
fi

touch $WORKDIR/last_topic

while true
do
{

##AUTH
csrf=$(curl http://linuxforum.ru/login.php | grep csrf_token | sed 's/.*value="//' | sed 's/".*//')
curl -X POST -c cookie "http://linuxforum.ru/login.php" --data "form_sent=1&csrf_token=$csrf&req_username=$USR&req_password=$PWD&login=Войти"

##GET_DATA
GETINDEX=`curl -b cookie http://linuxforum.ru/search.php?action=show_recent`

MSGCOUNT=`echo "$GETINDEX" | grep main-first-item -A10 |\
           grep info-replies |\
            sed 's/.*<strong>//' |\
             sed 's/<\/strong.*//'`


TOPICNAME=`echo "$GETINDEX" | grep main-first-item -A10 |\
           grep 'class="item-num"' |\
           sed 's/.*viewtopic.php.*">//' |\
           sed 's/<.*//'`

LFUSER=`echo "$GETINDEX" | grep main-first-item -A10 |\
        grep info-lastpost |\
        sed 's/.*<cite>//' |\
        sed 's/<\/cite.*//'`

TOPICSTARTER=`echo "$GETINDEX" | grep main-first-item -A10 |\
              grep item-starter |\
              sed 's/.*<cite>//' |\
              sed 's/<\/.*//'`

ALINK=`echo "$GETINDEX" | grep main-first-item -A10 |\
         grep info-lastpost |\
          sed 's/.*<a.href="//' |\
           sed 's/">.*//'`

POST=`echo $ALINK | sed 's/.*#p//'`

PREMSGCOUNT=`head -n 1 $WORKDIR/last_topic`
PRETOPICNAME=`tail -n 1 $WORKDIR/last_topic`

{
if [ -z $MSGCOUNT ]
then
        echo "No connection"
        sleep 6
else
curl -b cookie $ALINK > $WORKDIR/ans

SHOWMSG ()
{
MESSAGE=`curl -b cookie $ALINK | grep "id=\"post$POST\"" -A1000 | grep 'class="postfoot"' -B1000 `

notify-send -t 0 --icon="$ICON" "$(echo -e "<b>@$LFUSER</b> $HEADER <br />$TOPICNAME")" "$(echo -e "$MESSAGE")"
                echo "$MSGCOUNT" > $WORKDIR/last_topic
                echo "$TOPICNAME" >> $WORKDIR/last_topic
                PREMSGCOUNT=`echo "$MSGCOUNT"`
                PRETOPICNAME=`echo "$TOPICNAME"`

}

##CHECK CHANGES AND SHOW MESSAGE
    if [ "$MSGCOUNT" = "0" ]
     then 
        HEADER="создал новую тему:"
     else
            HEADER="ответил в теме:"
    fi

    if [ "$MSGCOUNT" != "$PREMSGCOUNT" ]
    then    
         SHOWMSG
         sleep 6
    elif [ "$TOPICNAME" != "$PRETOPICNAME" ]
         then    
         SHOWMSG
     sleep 6
    else
     echo No changes
        sleep 6
    fi
fi
}
}
done
