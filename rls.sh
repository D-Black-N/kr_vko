#!/bin/bash

source "main.sh" 2>/dev/null

#-------------- Проверка параметров запуска --------------

args=$# # Количество аргументов, переданных в скрипт
id=$1 # Передаем ID РЛС

if (( args != 1 )) || (( id > 2 )) || (( id < 0 ))
then
	echo "Параметры запуска системы заданы неверно(1)!"
	exit 1
fi

#-------------- Инициализация параметров систем --------------

target_number=0
old_targets=0
subsystem_type="rls"

trap sigint_handler 2

log_file="$LogDirectory/$subsystem_type.log" 				# Директория для логов
echo "Система $subsystem_type успешно инициализирована!" | base64 >> $commfile

while :
do
	GetTargets

	#-------------- Проверка на промахи и попадания по целям --------------
	old=("${Targets[@]}")
done
