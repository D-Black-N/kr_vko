#!/bin/bash

source "main.sh" 2>/dev/null

#-------------- Проверка параметров запуска --------------

args=$# # Количество аргументов, переданных в скрипт
rls_id=$1 # Передаем ID РЛС

if (( args != 1 )) || (( rls_id > 2 )) || (( rls_id < 0 ))
then
	echo "Параметры запуска системы заданы неверно(1)!"
	exit 1
fi

check_start

#-------------- Методы проверки нахождения цели в секторе -------------------

function check_sector_coverage
{
	((X=$1/1000))
	((Y=$2/1000))

	((x1=-1*${RLS[0+5*$rls_id]}+$X))	# Получение координаты X относительно РЛС
	((y1=-1*${RLS[1+5*$rls_id]}+$Y)) # Получение координаты Y относительно РЛС

	local r1=$(echo "sqrt ( (($x1*$x1+$y1*$y1)) )" | bc) # Высчитываем расстояние цели до РЛС

	if (( $r1 <= ${RLS[3+5*$rls_id]} ))
	then
	  local fi=$(echo | awk " { x=atan2($y1,$x1)*180/3.14; print x}"); fi=(${fi/\.*}); # Рассчитываем угол от -pi до pi для цели
	  if [ "$fi" -lt "0" ]
	  then
	   	((fi=360+$fi))	   # Если меньше нуля, то добавляем 360 градусов
	  fi

 	  ((fimax=${RLS[2+5*$rls_id]}+${RLS[4+5*$rls_id]}/2-90)); # Получаем углы сектора обзора
	  ((fimin=${RLS[2+5*$rls_id]}-${RLS[4+5*$rls_id]}/2-90));
 	  if (( $fi <= $fimax )) && (( $fi >= $fimin ))	# Если угол направления цели попадает в сектор
	  then
	   	return 1 # Возвращаем 1, если цель попала в сектор
	  fi
	fi
	return 0	# Возвращаем 0, если цель не попала в сектор
}

#-------------- Инициализация параметров систем --------------

target_number=0
old_targets=0
subsystem_type="rls"

trap sigint_handler 2

log_file="$LogDirectory/$subsystem_type.log" 																			# Директория для логов
echo "Система ${subsystem_type}_${rls_id} успешно инициализирована!" | base64 >> $log_file

pulse_init "${subsystem_type}_${rls_id}"

# Функция завершения работы системы
# sigint_handler() { echo "";echo "Завершение работы системы ${subsystem_type}_${rls_id}" ; exit 0;}

while :
do
	read_targets # Читаем цели из файла, результат в переменной targets

	#-------------- Проверка на промахи и попадания по целям --------------

	for target in $targets
	do
		if [ "$target" ]
		then
			target_id=`expr substr $target 13 6`;																	# Извлекаем ID цели из названия файла
			target_file=`cat $DirectoryTargets/$target 2>/dev/null`; result=$?;		# Читаем файл обрабатываемой цели для извлечения координат
			if (( $result == 0 ))																									# Если данные были получены успешно, то ...
			then
				XTarget=`echo $target_file | cut -d',' -f 1 | cut -d'X' -f 2`;				# Разделяем координаты и записываем в переменные
				YTarget=`echo $target_file | cut -d',' -f 2 | cut -d'Y' -f 2`;
				check_new_target "$target_id"; idx=$?;															# Проверка на новую цель, возврат значения в переменной idx, если нашел, то id, если нет, то -1
				
				#-------------- Обработка цели --------------

				if (( $idx == -1 ))																									# Запись новой цели в массив целей
				then
	    		TargetsId[0+8*$target_number]=$target_id		# ID цели
	    		TargetsId[1+8*$target_number]=$XTarget			# Координата X
	    		TargetsId[2+8*$target_number]=$YTarget			# Координата Y
	    		TargetsId[3+8*$target_number]=0							# Скорость цели по X
	    		TargetsId[4+8*$target_number]=0							# Скорость цели по Y
	    		TargetsId[5+8*$target_number]=-1						# Идентификатор цели
					TargetsId[6+8*$target_number]=0							# 0 - по цели не стреляли, 1 - стреляли, 2 - цель уничтожена
					TargetsId[7+8*$target_number]=0							# Было ли определено направление цели
					cIdx=$target_number 												# Индекс текущей цели
	    		let target_number+=1
				else
					cIdx=$idx																		# Индекс текущей цели

					#-------------- Обработка существующей цели --------------

					if (( ${TargetsId[1+8*$cIdx]} != ${XTarget} )) || (( ${TargetsId[2+8*$cIdx]} != ${YTarget} )) # Если координаты изменились, то ...
					then
						check_sector_coverage ${TargetsId[1+8*$cIdx]} ${TargetsId[2+8*$cIdx]}; dot1=$? 	# (1-я засечка)
						check_sector_coverage ${XTarget} ${YTarget};  dot2=$?														# (2-я засечка)
						if (($dot1 == 1)) && (( $dot2 == 1 ))																						# Если обе засечки
						then
							TId=-1
							if ((${TargetsId[3+8*$cIdx]} == 0 )) && ((${TargetsId[4+8*$cIdx]} == 0 ))		# Если скорости ещё не были определены	
							then
								let TargetsId[3+8*$cIdx]=(${XTarget}-${TargetsId[1+8*$cIdx]})							# Скорость по X
						  	let TargetsId[4+8*$cIdx]=(${YTarget}-${TargetsId[2+8*$cIdx]})							# Скорость по Y
								classify_target ${TargetsId[3+8*$cIdx]} ${TargetsId[4+8*$cIdx]}						# Идентифицируем цель по скорости
								let TId=$? 																																# Получили идентификатор цели
							fi
							if (((${TId} == 0)) || ((${TargetsId[5+8*$cIdx]} == 0)))		# Если цель - это ББ БР, то ...
							then
								if (( ${TargetsId[5+8*$cIdx]} == -1 ))	# Если до этого эту цель не идентифицировали
								then
									date=`date +'%F %T'`
									echo "-$date- ${subsystem_type}_${rls_id}: Цель ID:${TargetsId[0+8*$cIdx]} обнаружена в (${TargetsId[1+8*$cIdx]}, ${TargetsId[2+8*$cIdx]}) и идентифицирована как Бал.блок (${TargetsId[3+8*$cIdx]}  ${TargetsId[4+8*$cIdx]})" | base64  >>$log_file 
									TargetsId[5+8*$cIdx]=${TId}	   				# Выдаём сообщение и устанавливаем идентификатор цели
								fi
								if (( ${TargetsId[7+8*$cIdx]} == 0 ))		# Если до этого направление цели не определяли, то
								then
									offset_xold=$((${TargetsId[1+8*$cIdx]} / 1000 - ${SPRO[0+4*0]}))	# Координаты цели в новой системе координат с центром в СПРО
									offset_yold=$((${TargetsId[2+8*$cIdx]} / 1000 - ${SPRO[1+4*0]})) 
									offset_xnew=$((${XTarget} / 1000 - ${SPRO[0+4*0]})) 
									offset_ynew=$((${YTarget} / 1000 -${SPRO[1+4*0]})) 
									delta_x=$(($offset_xnew-$offset_xold))
									delta_y=$(($offset_ynew-$offset_yold))
									k=`echo "scale=3;$delta_y / $delta_x" | bc`												# Коэффициент "k" для прямой вида y=kx+b
 									b=`echo "scale=3;$offset_ynew - $k * $offset_xnew" | bc`					# Коэффициент "b" для прямой вида y=kx+b
									x=${SPRO[0+4*0]}																									# Координаты и радиус СПРО
									y=${SPRO[1+4*0]}
									r=${SPRO[2+4*0]}
									coef1=`echo "scale=3;4 * $k * $k * $b * $b" | bc`									# D=b^2-4ac=coef1-coef2
									coef2=`echo "scale=3;4 * (1 + $k * $k) * ($b * $b - $r * $r)" | bc` 
									result=`echo "$coef1>=$coef2" | bc`																# Дискриминант должен быть больше либо равен нулю, чтобы прямая пересекала окружность
									if [[ $result == 1 ]]					# Если прямая пересекается с окружностью, то...
									then
										old_distance=$((offset_xold*offset_xold + offset_yold*offset_yold))  # расстояние до старой позиции цели
										new_distance=$((offset_xnew*offset_xnew + offset_ynew*offset_ynew))  # расстояние до новой позиции цели
										result=`echo "$old_distance>$new_distance" | bc`	# Проверяем уменьшилось ли расстояние
										check_generate_in_spro=`echo "$new_distance<$r" | bc`
										if [[ $result == 0 || $check_generate_in_spro == 0 ]]
										then
											date=`date +'%F %T'`
											echo "-$date- ${subsystem_type}_${rls_id}: Цель ID:${TargetsId[0+8*$cIdx]} движется в направлении СПРО" | base64  >>$log_file
										fi
									fi
									let TargetsId[7+8*$cIdx]=1
								fi
							fi
						fi
						TargetsId[1+8*$idx]=${XTarget}	# Меняем координату X цели
						TargetsId[2+8*$idx]=${YTarget}	# Меняем координату Y цели
					fi
				fi
			fi
		fi
	done
	pulse $subsystem_type
	system_sleep
done
