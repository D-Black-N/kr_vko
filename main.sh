#!/bin/bash

TempDirectory="/tmp/GenTargets"
LogDirectory="./logs"
DirectoryTargets="$TempDirectory/Targets"
DestroyDirectory="$TempDirectory/Destroy"
PulseDirectory="temp/pulse"
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

# Функция получения списка целей
function read_targets
{
	targets=`ls -tr $DirectoryTargets 2>/dev/null | tail -n 25`	# Сортированные данные целей
	result=$?
	if (( $result != 0 ))
	then
		echo "Система не запущена!"
		exit 0
	fi
}

# Функция проверки на новизну цели (Если цель новая, возвращается -1, иначе возвращается индекс элемента)
return_target_id=0;
function check_new_target
{
  elem_size=8			                              # Количество характеристик одной цели
  current_id="$2"					                      # Идентификатор цели

  ((elem_count=${#TargetsId[@]}/elem_size));    # TargetsId - это массив целей, elem_size - количество характеристик одной цели
  return_target_id=-1
  i=0
  while (( "$i" < "$elem_count" ))
  do
    if [[ "${TargetsId[0+$elem_size*$i]}" == "$current_id" ]]
    then
      return_target_id=$i
      break;
    fi
    let i+=1
  done
  return $return_target_id
}

# Функция классификации цели по скорости
function classify_target
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

# Метод инициализации пульса систем (для контроля жизни) 
function pulse_init
{
	type="$1"
	pulse_file="$PulseDirectory/$type"
	echo "0" >$pulse_file
	case $type in
  "rls")
		pulse_rls=0
    ;;
  "spro")
		pulse_spro=0
    ;;
  "zrdn")
		pulse_zrdn=0
  esac
}

# Метод контроля пульса (для увеличения пульса на 1)
function pulse
{
	type="$1"

	case $type in
  "rls")
		let pulse_rls+=1
		echo "$pulse_rls" >$pulse_file
    ;;
  "spro")
 		let pulse_spro+=1
		echo "$pulse_spro" >$pulse_file
    ;;
  "zrdn")
		let pulse_zrdn+=1
		echo "$pulse_zrdn" >$pulse_file
  esac
}

function processing_old_targets
{
  old=("${Targets[@]}")
	if ((${#old_targets[@]} != 0))											# Если массив предыдущих целей не пуст, то ...
	then
		for target in $old_targets												# Проходим по прошлым целям
		do
			if [ "$target" ]
			then
				i=0
				while (( "$i" < "${#Targets[@]}" ))				# Цикл по количеству элементов в массиве текущих целей
				do
					if [[ "$target" == "${Targets[$i]}" ]]	# Если в текущей выборке попался файл цели, который уже рассматривался в прошлый раз
					then	
						Targets[$i]="ERROR"										# Заменяем название этого файла на ERROR
						break;
					fi
					let i+=1
				done
			fi
		done
	fi

	((elem_count=${#TargetsId[@]}/8)) 							# Количество элементов в массиве целей
	if (($elem_count > 0)) 												# Если есть известные цели (массив целей не пустой)
	then
		for target in $Targets												# Проходим по полученным от генератора целям
		do
			if [ "$target" ] && [ "$target" != "ERROR" ]
			then 
				IDTarget=`expr substr $target 13 6`;			# Получение ID цели
				target_file=`cat $DirectoryTargets/$target 2>/dev/null`;result=$?;	# Читаем файл
				if (( $result == 0 ))
				then
					XTarget=`echo $target_file | cut -d',' -f 1 | cut -d'X' -f 2`;		# Координата X цели
					YTarget=`echo $target_file | cut -d',' -f 2 | cut -d'Y' -f 2`;		# Координата Y цели
					i=0
					while (( "$i" < "$elem_count" ))					# Цикл по количеству элементов в массиве целей
					do
						if [[ "${TargetsId[0+8*$i]}" == "$IDTarget" ]] && ((${TargetsId[6+8*$i]} == 1)) && (((TargetsId[1+8*$i]!=$XTarget)) || ((TargetsId[2+8*$i]!=$YTarget))) # Если мы стреляли по цели и её координаты изменились
						then
							date=`date +'%F %T'`
							echo "-$date- Промах по цели ID:${TargetsId[0+8*$i]}" | base64  >> $log_file		# Выдаём сообщение о промахе и сбрасываем флаг того, что стреляли
							let TargetsId[6+8*$i]=0
							break;
						fi
						let i+=1
					done
				fi
			fi
		done

		i=0
		while (( "$i" < "$elem_count" ))			# Цикл по количеству элементов в массиве целей
		do
			if ((${TargetsId[6+8*$i]} == 1))		# Если после предыдущего цикла остались цели с установленным флагом, что по ним стреляли
			then
				date=`date +'%F %T'`
				echo "-$date- Цель ID:${TargetsId[0+8*$i]} уничтожена" | base64  >>$log_file		# Выдаём сообщение об уничтожении и устанавливаем флаг "уничтожен"
				let TargetsId[6+8*$i]=2
			fi
			let i+=1
		done
	fi

	old_targets=$old												# Обновляем массив старых целей
}

function system_sleep
{
	sleep 0.8
}
