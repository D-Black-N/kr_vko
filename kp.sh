#!/bin/bash

#-------------- Секция инициализации --------------

SYSTEMS=("rls" "zrdn" "spro" "kp")		# Массив с именами файлов систем
SYSTEMSDESCR=("РЛС" "ЗРДН" "СПРО")		# Массив систем для вывода в логи
HBVARS=("-1" "-1" "-1")								# Массив для хранения значений пульса систем
LOGLINES=("0" "0" "0")								# Массив для хранения количества выведенных строк из лог файлов для систем
COUNTLINES=("-1" "-1" "-1" "-1")			# Массив для хранения количества строк в логах, которые были записаны за 30 минут

source "main.sh" 2>/dev/null

subsystem_type="kp"
log_file="$LogDirectory/$subsystem_type.log"

trap sigint_handler 2 		# Отлов сигнала остановки процесса. Если сигнал пойман, то вызывается функция ...

date=`date +'%F %T'`
echo "-$date- Система $SubsystemType успешно инициализирована!"
echo "-$date- Система $SubsystemType успешно инициализирована!" >>$log_file

sltime=0;

while :
do
	sleep 1
	let sltime+=1

	#-------------- Секция вывода логов --------------

  if (( sltime%2 == 0))		# Если счётчик кратен 2м, то ...
	then
		i=0
		while (( $i < 3 ))		# Цикл по подсистемам
		do
			lines=`wc -l "$LogDirectory/${SYSTEMS[$i]}.log" 2>/dev/null`; res=$? 	# Получаем строку с количеством строк в лог файле и с названием этого файла
			if (( res == 0 ))																													# Если количество строк удалось получить, то ...
			then
				count=($lines)																													# Получаем массив из строки
				count=${count[0]}																												# Получаем первый элемент массива (количество строк в лог файле)
				((LinesToDisplay=$count-${LOGLINES[$i]}))																# Получаем количество строк, которое нужно вывести
				LOGLINES[$i]=$count																											# Определяем количество уже выведенных строк
				if (( $LinesToDisplay > 0))																							# Если количество строк строк, которое нужно вывести, больше нуля, то ...
				then
					readedfile=`tail -n $LinesToDisplay $LogDirectory/${SYSTEMS[$i]}.log 2>/dev/null`;result=$?		# Считываем строки, которые нужно вывести
					if (( $result == 0 ))																									# Если удалось считать, то ...
					then
						echo "$readedfile" | base64 -d																			# выводим декодированные строки
						echo "$readedfile" | base64 -d >> $log_file
					fi
				fi
			fi
			let i+=1
		done
	fi

	#-------------- Секция мониторинга состояния подсистем --------------

  if (( sltime%30 == 0))				# Если счётчик кратен 2м, то ...
	then
		i=0
		while (( $i < 3 ))					# Цикл по подсистемам
		do
			readedfile=`tail $DirectoryComm/${SYSTEMS[$i]} 2>/dev/null`; result=$?	# Получаем значение пульса из файла
			date=`date +'%F %T'`
			if (( $result == 0 ))
			then
				if (( ${HBVARS[$i]} == $readedfile))				# Если значение пульса не изменилось по сравнению с предыдущим, то ...
				then
					echo "  -$date- Система ${SYSTEMSDESCR[$i]} зависла"
					echo "  -$date- Система ${SYSTEMSDESCR[$i]} зависла" >>$log_file
				fi
				HBVARS[$i]=$readedfile
			else
				echo "  -$date- Ошибка доступа к cиcтеме ${SYSTEMSDESCR[$i]}"
				echo "  -$date- Ошибка доступа к cиcтеме ${SYSTEMSDESCR[$i]}" >>$log_file
			fi
			let i+=1
		done
	fi

	#-------------- Секция контроля логов --------------

  if (( sltime%3000 == 0)) 						# Раз в 200 тактов сохраняем количество строк за 200 тактов
	then
		i=0
		while (( $i < 4 ))
		do
			lines=`wc -l "$LogDirectory/${SYSTEMS[$i]}.log" 2>/dev/null`; res=$?		# Получаем количество строк в лог файле
			if (( res == 0 ))																														# Если количество строк удалось получить, то
			then
				count=($lines)																														# Получаем массив ищ строки с информацией о количестве строк
				count=${count[0]}																													# Получаем первое число из массива
				COUNTLINES[$i]=$count																											# Переприсваиваем количество строк
			fi
			let i+=1
		done
	fi
	if (( sltime%5800 == 0 ))   # Раз в 380 тактов удаляем количество строк за 200 тактов
	then
		i=0
		while (( $i < 4 ))	# Цикл по всем системам
		do
			if ((${COUNTLINES[$i]}>0))
			then
				date=`date +'%F %T'`
				echo "-$date- Удаление ${COUNTLINES[$i]} первых строк из файла ${SYSTEMS[$i]}.log"
				sed -i "1,${COUNTLINES[$i]}d" "/tmp/GenTargets/CommLog/${SYSTEMS[$i]}.log"
			fi
			let i+=1
		done
	fi
done
