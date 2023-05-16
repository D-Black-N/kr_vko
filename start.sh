#!/bin/bash

source "helper.sh" 2>/dev/null

# Старт систем РЛС
./rls.sh 0 &
rls_0_pid=$!; echo "Запуск РЛС 0 PID=$rls_0_pid"
./rls.sh 1 &
rls_1_pid=$!; echo "Запуск РЛС 1 PID=$rls_1_pid"
./rls.sh 2 &
rls_2_pid=$!; echo "Запуск РЛС 2 PID=$rls_2_pid"

# Старт системы СПРО
./spro.sh
spro_pid=$!; echo "Запуск СПРО PID=$spro_pid"

# Старт систем ЗРДН
./zrdn.sh 0 &
zrdn_0_pid=$!; echo "Запуск ЗРДН 0 PID=$zrdn_0_pid"
./zrdn.sh 1 &
zrdn_1_pid=$!; echo "Запуск ЗРДН 1 PID=$zrdn_1_pid"
./zrdn.sh 2 &
zrdn_2_pid=$!; echo "Запуск ЗРДН 2 PID=$zrdn_2_pid"
