#!/bin/bash

#*******************************************************************************************************
#
#	File: PT-18B-Deshabilitar-usuaris.sh
#
#	Ús: ${0} [-d] [-a] [-r] 
#
#	Descripció: Aquest script desabil·lita, esborra i arxiva usuaris.
#
#	Author: By9Marti
#
#	Creat: 01-12-2020
#
#*******************************************************************************************************

#Enviem el missatge de com funciona el script
usage(){
cat <<EOF	
	Metoda d'ús: $0 [-d] [-a] [-r] nom_Usuari 
	-d S'encarrega de desabil·litar el usuari indicat.
	-a S'encarrega de fer un backup del /home de l'usuari indicat.
	-r S'encarrega de elimnar el usuari indicat.
EOF
}

#S'encarrega de guardar la id del usuari indicat.
id_user(){	
	id=$(id -u $1 )
	check=$?
	if [ "$check" == 1 ];then
		echo "ERROR: L'usuari "$1" no existeix"
		ERROR=1

	elif [ $id -gt 1000 ];then
		echo "Usuari "$1" té un id major de 1000"
		vulnerable=1

	elif [ $id -lt 1000 ];then
		echo "Usuari "$1" té un id menor de 1000."
		echo "Aquest usuari no pot ser bloquejat o esborrat."
	fi
}

#S'encarrega de desabil·litar el usuari indicat.
user_block(){
	usermod -L $1
	chage -E0 $1
	usermod -s /sbin/nologin $1
	echo "Usuari "$1" bloquejat satisfactoriament"
}

#S'encarrega d'esborrar l'usuari indicat i totes les seves dades dins el sistema.
user_del(){
	userdel $1
}

#S'encarrega de fer el backup del usuari indicat.
user_backup(){
	userdir=`eval echo ~$1`
	date=`date +"%y-%m-%d-%s"`
	filename=`echo $1"."$date".tar.gz"`
	path=`echo $userdir"/"$filename`
	`cd $userdir`
	`tar -czf $filename .`
	`mv $filename /archives/$filename`
	echo "Backup d'usuari "$1" fet a "$filename
}

#S'encarrega d'iniciar el getops.
while getopts ":d:r:a:" o; do
	case "${o}" in
	d)
		#S'encarrega de agafar el paremetre -d
		USUARI=$OPTARG
		id_user $USUARI
		if [ "$vulnerable" == 1 ];then
			user_block $USUARI
		fi
		;;
	r)
		#S'encarrega de agafar el paremetre -r
		USUARI=$OPTARG
		id_user $USUARI
		if [ "$vulnerable" == 1 ];then
			user_del $USUARI
		fi
		;;
	a)
		#S'encarrega de agafar el paremetre -a
		USUARI=$OPTARG
		user_backup $USUARI
		;;
	:)
		#S'encarrega d'activar-se quan no rep el paramentre correctament
		echo "-$OPTARG argument mal declarat" 1>&2
		xq=$OPTARG
		ERROR=1
		;;
	\?)
		#S'encarrega d'activarse quan rep una opcio no intruduida al getops.
		echo "Opció invalida -$OPTARG" 1>&2
		ERROR=1
		;;
	esac
done

#S'encarrega de notificar al usuari quan esta mal introduit
if [ -z $USUARI ] && [ "$xq" != "d" ] && [ "$xq" != "r"  ] && [ "$xq" != "a" ]; then
	echo "Has introduit las opcions malament." 1>&2
	ERROR=1
fi
#S'encarrega de enviar el funcionament complet del script 
if [ "$ERROR" == 1 ];then
	usage
	exit 1
fi