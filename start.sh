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
./spro.sh &
spro_pid=$!; echo "Запуск СПРО PID=$spro_pid"

# Старт систем ЗРДН
./zrdn.sh 0 &
zrdn_0_pid=$!; echo "Запуск ЗРДН 0 PID=$zrdn_0_pid"

./zrdn.sh 1 &
zrdn_1_pid=$!; echo "Запуск ЗРДН 1 PID=$zrdn_1_pid"

./zrdn.sh 2 &
zrdn_2_pid=$!; echo "Запуск ЗРДН 2 PID=$zrdn_2_pid"

# Старт работы КП
./kp.sh &
kp_pid=$!; echo "Запуск КП PID=$kp_pid"

echo "Завершение работы подсистемы РЛС 0"; disown $rls_0_pid; kill -9 $rls_0_pid 2>/dev/null;
echo "Завершение работы подсистемы РЛС 1"; disown $rls_1_pid 2>/dev/null; kill -9 $rls_1_pid 2>/dev/null;
echo "Завершение работы подсистемы РЛС 2"; disown $rls_2_pid 2>/dev/null; kill -9 $rls_2_pid 2>/dev/null;

echo "Завершение работы подсистемы ЗРДН 0"; disown $zrdn_0_pid 2>/dev/null; kill -9 $zrdn_0_pid 2>/dev/null;
echo "Завершение работы подсистемы ЗРДН 1"; disown $zrdn_1_pid 2>/dev/null; kill -9 $zrdn_1_pid 2>/dev/null;
echo "Завершение работы подсистемы ЗРДН 2"; disown $zrdn_2_pid 2>/dev/null; kill -9 $zrdn_2_pid 2>/dev/null;

echo "Завершение работы подсистемы СПРО"; disown $spro_pid 2>/dev/null; kill -9 $spro_pid 2>/dev/null;
echo "Завершение работы подсистемы КП"; disown $kp_pid 2>/dev/null; kill -9 $kp_pid 2>/dev/null;
