#!/bin/bash
# Скрипт для тестирования механизма остановки контейнера при падении dnsmasq
# Использование: ./test-failure-scenarios.sh <scenario_number>

SCENARIO=$1

echo "========================================="
echo "DNS Cache Container - Failure Testing"
echo "========================================="
echo ""

case $SCENARIO in
1)
	echo "Scenario 1: Повреждение upstream DNS файла"
	echo "-------------------------------------------"
	echo "Действие: Создаем пустой /etc/resolv.dnsmasq"
	echo "Ожидаемый результат: dnsmasq не запустится, контейнер упадет"
	echo ""

	# Бэкап
	cp /etc/resolv.dnsmasq /etc/resolv.dnsmasq.backup 2>/dev/null

	# Создаем пустой файл
	echo "" >/etc/resolv.dnsmasq

	echo "Файл поврежден. Перезапускаем dnsmasq..."
	supervisorctl restart dnsmasq

	echo "Ждем 5 секунд для проверки состояния..."
	sleep 5
	supervisorctl status dnsmasq
	;;

2)
	echo "Scenario 2: Upstream DNS содержит localhost (DNS loop)"
	echo "-------------------------------------------------------"
	echo "Действие: Добавляем 127.0.0.1 в upstream DNS"
	echo "Ожидаемый результат: Валидация fail, dnsmasq exit 1, контейнер упадет"
	echo ""

	# Бэкап
	cp /etc/resolv.dnsmasq /etc/resolv.dnsmasq.backup 2>/dev/null

	# Создаем DNS loop
	echo "nameserver 127.0.0.1" >/etc/resolv.dnsmasq

	echo "Файл поврежден. Перезапускаем dnsmasq..."
	supervisorctl restart dnsmasq

	echo "Ждем 5 секунд для проверки состояния..."
	sleep 5
	supervisorctl status dnsmasq
	;;

3)
	echo "Scenario 3: Повреждение конфигурации dnsmasq"
	echo "----------------------------------------------"
	echo "Действие: Добавляем невалидную строку в dnsmasq.conf"
	echo "Ожидаемый результат: dnsmasq не запустится, контейнер упадет"
	echo ""

	# Бэкап
	cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup 2>/dev/null

	# Добавляем невалидную опцию
	echo "invalid-option-that-does-not-exist=true" >>/etc/dnsmasq.conf

	echo "Конфигурация повреждена. Перезапускаем dnsmasq..."
	supervisorctl restart dnsmasq

	echo "Ждем 5 секунд для проверки состояния..."
	sleep 5
	supervisorctl status dnsmasq
	;;

4)
	echo "Scenario 4: Удаление upstream DNS файла"
	echo "-----------------------------------------"
	echo "Действие: Удаляем /etc/resolv.dnsmasq и /etc/resolv.conf.original"
	echo "Ожидаемый результат: Скрипт не найдет upstream DNS, exit 1, контейнер упадет"
	echo ""

	# Бэкап
	cp /etc/resolv.dnsmasq /etc/resolv.dnsmasq.backup 2>/dev/null
	cp /etc/resolv.conf.original /etc/resolv.conf.original.backup 2>/dev/null

	# Удаляем файлы
	rm -f /etc/resolv.dnsmasq

	# Портим backup тоже (экстремальный сценарий)
	echo "nameserver 127.0.0.1" >/etc/resolv.conf.original

	echo "Файлы удалены/повреждены. Перезапускаем dnsmasq..."
	supervisorctl restart dnsmasq

	echo "Ждем 5 секунд для проверки состояния..."
	sleep 5
	supervisorctl status dnsmasq
	;;

5)
	echo "Scenario 5: Ручная отправка SIGTERM процессу dnsmasq"
	echo "-----------------------------------------------------"
	echo "Действие: Убиваем процесс dnsmasq с exit code 1"
	echo "Ожидаемый результат: supervisord пытается перезапустить, но если будет FATAL → контейнер упадет"
	echo ""

	PID=$(supervisorctl pid dnsmasq)
	echo "PID dnsmasq: $PID"

	if [ "$PID" != "0" ]; then
		echo "Отправляем SIGTERM..."
		kill -TERM $PID

		echo "Ждем 5 секунд..."
		sleep 5
		supervisorctl status dnsmasq
	else
		echo "dnsmasq не запущен!"
	fi
	;;

6)
	echo "Scenario 6: Симуляция быстрого падения (FATAL trigger)"
	echo "-------------------------------------------------------"
	echo "Действие: Создаем конфликт портов для dnsmasq"
	echo "Ожидаемый результат: dnsmasq не может забиндить порт 53, exit 1, FATAL"
	echo ""

	# Запускаем другой процесс на порту 53
	echo "Запускаем nc на порту 53..."
	nc -l -p 53 &
	NC_PID=$!
	echo "NC PID: $NC_PID"

	sleep 2

	echo "Перезапускаем dnsmasq (должен упасть т.к. порт занят)..."
	supervisorctl restart dnsmasq

	echo "Ждем 5 секунд..."
	sleep 5
	supervisorctl status dnsmasq

	# Убиваем nc
	kill $NC_PID 2>/dev/null
	;;

restore)
	echo "Scenario RESTORE: Восстановление из бэкапов"
	echo "--------------------------------------------"
	echo "Восстанавливаем файлы из бэкапов..."

	cp /etc/resolv.dnsmasq.backup /etc/resolv.dnsmasq 2>/dev/null && echo "✓ resolv.dnsmasq restored"
	cp /etc/dnsmasq.conf.backup /etc/dnsmasq.conf 2>/dev/null && echo "✓ dnsmasq.conf restored"
	cp /etc/resolv.conf.original.backup /etc/resolv.conf.original 2>/dev/null && echo "✓ resolv.conf.original restored"

	echo ""
	echo "Перезапускаем dnsmasq..."
	supervisorctl restart dnsmasq

	sleep 3
	supervisorctl status dnsmasq
	;;

*)
	echo "Использование: $0 <scenario_number>"
	echo ""
	echo "Доступные сценарии:"
	echo "  1 - Повреждение upstream DNS файла (пустой файл)"
	echo "  2 - DNS loop (127.0.0.1 в upstream)"
	echo "  3 - Невалидная конфигурация dnsmasq.conf"
	echo "  4 - Удаление критических файлов"
	echo "  5 - Ручное убийство процесса dnsmasq"
	echo "  6 - Конфликт портов (порт 53 занят)"
	echo ""
	echo "  restore - Восстановить из бэкапов"
	echo ""
	echo "ВНИМАНИЕ: Эти тесты могут остановить контейнер!"
	echo "          В Kubernetes Pod будет в состоянии Error/CrashLoopBackOff"
	echo ""
	echo "Пример:"
	echo "  $0 1    # Запустить сценарий 1"
	echo "  $0 restore  # Восстановить файлы"
	;;
esac

echo ""
echo "========================================="
echo "Проверка состояния supervisord..."
echo "========================================="
supervisorctl status
