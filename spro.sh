#!/bin/bash

source "main.sh" 2>/dev/null

#-------------- Инициализация параметров систем --------------

target_number=0
old_targets=0
subsystem_type="spro"

trap sigint_handler 2

log_file="$LogDirectory/$subsystem_type.log" 																			# Директория для логов
echo "Система $subsystem_type успешно инициализирована!" | base64 >> $log_file

pulse_init $subsystem_type

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
								if (( ${TargetsId[5+8*$cIdx]} == -1 ))					# Если до этого эту цель не идентифицировали
								then 
									date=`date +'%F %T'`
									echo "-$date- $subsystem_type $i: Цель ID:${TargetsId[0+8*$cIdx]} обнаружена в (${TargetsId[1+8*$cIdx]}, ${TargetsId[2+8*$cIdx]}) и идентифицирована как Бал.блок (${TargetsId[3+8*$cIdx]}  ${TargetsId[4+8*$cIdx]})" | base64  >>$log_file 
									TargetsId[5+8*$cIdx]=${TId}	   								# Выдаём сообщение и устанавливаем идентификатор цели
								fi
								if ((${SPRO[3+4*0]} > 0)) && ((${TargetsId[6+8*$i]} == 0))		 								# Если есть чем стрелять
								then
									touch "$DestroyDirectory/${TargetsId[0+8*$cIdx]}"		# Стреляем, выводим сообщение и устанавливаем флаг того, что стреляли
									let SPRO[3+4*0]-=1
									date=`date +'%F %T'`
									echo "-$date- $subsystem_type $i отстрелялась по цели ID:${TargetsId[0+8*$cIdx]}. Оставшийся боезапас: ${SPRO[3+4*0]})" | base64  >> $log_file
									let TargetsId[6+8*$cIdx]=1
								fi
								if ((${SPRO[3+4*0]} == 0))			 								# Если боезапас исчерпан
								then
									let SPRO[3+4*0]-=1				 										# Переход в режим обнаружения			
									date=`date +'%F %T'`										
									echo "-$date- $subsystem_type $i: Боекомплект исчерпан! Переход в режим обнаружения." | base64  >> $log_file
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
