#!/bin/bash

function CheckStart			# Функция проверки возможности запуска
{
	if [[ $EUID -eq 0 ]]	# Проверка на то, что запускает не админ
	then
		echo "Невозможен запуск с правами администратора"
		exit 1
	fi

	OS=`uname -s`
	if [[ $OS != "Linux" ]]	 # Проверка ОС
	then
	  echo "Невозможен запуск в ОС, отличной от Linux"
	  exit 1
	fi

	t1=`echo $BASH | grep -o bash` 
	res=$?
	if [ $res != 0 ]
	then
	  echo "Невозможен запуск в интерпретаторе, отличном от BASH"
	  exit 1
	fi
}

sigint_handler() { echo "";echo "Завершение работы системы $SubsystemType" ; exit 0;} 
