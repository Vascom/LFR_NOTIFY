#!/bin/bash

#####==CONFIG==##############################################################
USR=diablopc ##You username
PWD=Grizli1711 ##You password
CHECKUSERS=1 ##Valid values 0 (don't check), 1 (check)
#####==CONFIG==##############################################################

#CHECK AND CREATE CONFIG
WORKDIR=/tmp/LF
ICON="$WORKDIR/favicon.ico"
touch $WORKDIR/last_topic

if ! [ -d $WORKDIR ]; then
	mkdir $WORKDIR
fi

if ! [ -f $ICON ]; then
	wget http://linuxforum.ru/favicon.ico -O $ICON
fi


##FUNC-----------------------------------------------------------------------------------------
#AUTENTICATION
AUTH ()
		{
		csrf=$(curl http://linuxforum.ru/login.php | grep csrf_token | sed 's/.*value="//' | sed 's/".*//')
		curl -X POST -c cookie "http://linuxforum.ru/login.php" --data "form_sent=1&csrf_token=$csrf&req_username=$USR&req_password=$PWD&login=Войти"
		}

#GET AND SHOW USER INFO
SHOWUSER ()
			{
			LASTUSERDATA=`curl -b cookie "$LASTULINK" |\
								grep 'h2 class="hn"' -A35 |\
								sed 's/.*<div.*//g' |\
								sed 's/<.*\/div.*>//g' |\
								sed 's/.*<ul.*//g' |\
								sed 's/.*<\/ul>.*//g' |\
								sed 's/<li>//g' |\
								grep -v "^$" |\
								sed 's/<h2 class="hn">//' |\
								sed 's/<\/h2>//'`
			notify-send -t 0 --icon="$ICON" "$(echo -e "<b>Регистрация нового пользователя</b>")" "$(echo -e "$LASTUSERDATA")"
			echo "$LASTUNAME" > $WORKDIR/last_user
			PRELASTUNAME=`echo "$LASTUNAME"`
			}

#CREATE AND SHOW MESSAGE
SHOWMSG ()
			{	
			MESSAGE=`curl -b cookie $ALINK | grep "id=\"post$POST\"" -A1000 | grep 'class="postfoot"' -B1000 `
			notify-send -t 0 --icon="$ICON" "$(echo -e "<b>@$LFUSER</b> $HEADER <br />$TOPICNAME")" "$(echo -e "$MESSAGE")"
         echo "$MSGCOUNT" > $WORKDIR/last_topic
         echo "$TOPICNAME" >> $WORKDIR/last_topic
         PREMSGCOUNT=`echo "$MSGCOUNT"`
         PRETOPICNAME=`echo "$TOPICNAME"`
			}

while true
do
{
##CHECK AUTH AND AUTENTICATE
		CHECKAUTH=`curl -b cookie http://linuxforum.ru/index.php |\
					grep "Пожалуйста, войдите или зарегистрируйтесь."`

		if [ "$CHECKAUTH" != "" ]; then
			AUTH
		fi

##GET NEW USERS DATA
		if [ "$CHECKUSERS" == "1" ]; then
				LASTUSERREG=`curl -b cookie http://linuxforum.ru/index.php | grep "Последним зарегистрировался"`
				LASTUNAME=`echo "$LASTUSERREG" | sed 's/.*profile.php?id=.*">//' | sed 's/<\/a>.*//'`
				LASTULINK=`echo "$LASTUSERREG" | sed 's/.*href="//' | sed 's/">.*//'`
		fi

##GET DATA
		GETINDEX=`curl -b cookie http://linuxforum.ru/search.php?action=show_recent`

##SORT DATA
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
	if [ -z $MSGCOUNT ]; then
		echo "No connection"
		sleep 6
	else

##SHOW NEW USERS
		if [ "$CHECKUSERS" == "1" ]; then
			if [ "$PRELASTUNAME" != "$LASTUNAME" ]; then
				SHOWUSER
			fi
		fi

##CHECK CHANGES AND SHOW MESSAGE
		if [ "$MSGCOUNT" = "0" ]; then 
			HEADER="создал новую тему:"
		else
			HEADER="ответил в теме:"
		fi

		if [ "$MSGCOUNT" != "$PREMSGCOUNT" ]; then    
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
