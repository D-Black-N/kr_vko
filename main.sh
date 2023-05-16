#!/bin/bash

TempDirectory="/tmp/GenTargets"
LogDirectory="./logs"
DirectoryTargets="$TempDirectory/Targets"
DestroyDirectory="$TempDirectory/Destroy"
PulseDirectory="./temp/pulse"
LogFile="$TempDirectory/GenTargets.log"

declare -a RLS  # x y a r fov
#1
RLS[0+5*0]=5000 # Координата X
RLS[1+5*0]=3000	# Координата Y
RLS[2+5*0]=270	# Азимут
RLS[3+5*0]=4000 # Дальность действия
RLS[4+5*0]=200  # Угол обзора	
#2
RLS[0+5*1]=3250
RLS[1+5*1]=3000
RLS[2+5*1]=270
RLS[3+5*1]=3000
RLS[4+5*1]=120
#3
RLS[0+5*2]=5000
RLS[1+5*2]=3000
RLS[2+5*2]=45
RLS[3+5*2]=7000
RLS[4+5*2]=90

declare -a ZRDN  # x y r
#1
ZRDN[0+4*0]=5100
ZRDN[1+4*0]=5250
ZRDN[2+4*0]=600
ZRDN[3+4*0]=20
#2
ZRDN[0+4*1]=2500
ZRDN[1+4*1]=2900
ZRDN[2+4*1]=400
ZRDN[3+4*1]=20
#3
ZRDN[0+4*2]=2800
ZRDN[1+4*2]=5750
ZRDN[2+4*2]=550
ZRDN[3+4*2]=20

declare -a SPRO  # x y r
#1
SPRO[0+4*0]=2500
SPRO[1+4*0]=3500
SPRO[2+4*0]=1700
SPRO[3+4*0]=10

declare -a TargetsId 				# Массив для целей

# Функция завершения работы системы
sigint_handler() { echo "";echo "Завершение работы системы $SubsystemType" ; exit 0;} 

function classify_target			# Функция классификации цели по скорости
{
  #0-ББ БР 1-Самолеты 2-Крылатые ракеты
  speedX=$1		# Скорость по Х
	speedY=$2		# скорость по Y
	speed=$(echo "sqrt ( (($speedX*$speedX+$speedY*$speedY)) )" | bc)		# Определяем скорость как гипотенузу

	if ((( $speed > 50 )) && (( $speed < 250 )))				# Если скорость 50-249, то Самолёт
  then
    return 1
  fi

	if ((( $speed > 249 )) && (( $speed < 1000 )))			# Если скорость 250-999, то К.ракета
  then
    return 2
  fi

  if ((( $speed > 7999 )) && (( $speed < 10000 )))		# Если скорость 8000-9999, то ББ БР
  then
    return 0
  fi

  return 100
}

function GetTargets				# Функция получения списка целей
{
	Targets=`ls -tr $DirectoryTargets 2>/dev/null | tail -n 25`	# Сортированные данные целей
	result=$?
	if (( $result != 0 ))
	then
		echo "Система не запущена!"
		exit 0
	fi
}