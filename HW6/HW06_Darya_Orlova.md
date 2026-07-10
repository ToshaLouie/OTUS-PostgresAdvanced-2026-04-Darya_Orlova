# HW  6- Углубленный анализ производительности. Профилирование. Оптимизация 

## Задание 1
## Разверните инстанс PostgreSQL на виртуальной машине в Яндекс.Облаке или любом другом месте.
## Ход действий:

Использовала машину поднятую раньше в рамках домашней работы по восстановление класстера на отдельном кластере.
Для этого подключилась к ВМ и  выполнила:

    sudo -u postgres psql -c "SELECT pg_promote();"
     pg_promote 
    ------------
     t
    (1 row)

     sudo -u postgres psql -d otus -c "
    SELECT
        pg_is_in_recovery() AS is_replica,
        current_setting('transaction_read_only') AS transaction_read_only;
    "
     is_replica | transaction_read_only 
    ------------+-----------------------
     f          | off
    (1 row)

Тем самым: сделала ее самостоятельным  PostgreSQL-сервером, так как promote — вывел из recovery и повысил состояние до primary.

## Задание 2
## Протестируйте производительность с помощью pgbench.
## Ход действий:
Установила pgbench

    sudo apt update
    sudo apt install  postgresql-contrib

Подготовила тестовую БД для нагрузок

    sudo -u postgres pgbench -i -s 100 otus
    pgbench создал тестовые таблицы и измеряет TPS — transactions per second.
    
    
    sudo -u postgres pgbench -i -s 100 otus
    dropping old tables...
    creating tables...
    generating data (client-side)...
    10000000 of 10000000 tuples (100%) done (elapsed 208.21 s, remaining 0.00 s)
    vacuuming...
    creating primary keys...
         
    
    done in 376.36 s (drop tables 0.06 s, create tables 0.03 s, client-side generate 208.68 s, vacuum 18.75 s, primary keys 148.84 s).


## Задание 3
## Оптимизируйте настройки PostgreSQL для максимальной производительности. Настройте кластер на оптимальную производительность, не обращая внимания на стабильность БД.
## Ход действий:

Провела тесты до внесения правок в конфиг файлы
Фиксирую себе :

    sudo -u postgres pgbench -c 10 -j 4 -T 60 otus
    sudo -u postgres pgbench -c 50 -j 4 -T 60 otus
    sudo -u postgres pgbench -c 100 -j 4 -T 60 otus
    pgbench (16.14 (Ubuntu 16.14-0ubuntu0.24.04.1))
    starting vacuum...end.
    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 100
    query mode: simple
    number of clients: 10
    number of threads: 4
    maximum number of tries: 1
    duration: 60 s
    number of transactions actually processed: 23516
    number of failed transactions: 0 (0.000%)
    latency average = 25.554 ms
    initial connection time = 20.579 ms
    tps = 391.332833 (without initial connection time)
    pgbench (16.14 (Ubuntu 16.14-0ubuntu0.24.04.1))
    starting vacuum...end.
    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 100
    query mode: simple
    number of clients: 50
    number of threads: 4
    maximum number of tries: 1
    duration: 60 s
    number of transactions actually processed: 19528
    number of failed transactions: 0 (0.000%)
    latency average = 154.210 ms
    initial connection time = 85.493 ms
    tps = 324.233073 (without initial connection time)
    pgbench (16.14 (Ubuntu 16.14-0ubuntu0.24.04.1))
    starting vacuum...end.
    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 100
    query mode: simple
    number of clients: 100
    number of threads: 4
    maximum number of tries: 1
    duration: 60 s
    number of transactions actually processed: 16065
    number of failed transactions: 0 (0.000%)
    latency average = 376.574 ms
    initial connection time = 168.849 ms
    tps = 265.551763 (without initial connection time)



До оптимизации:
c=10  TPS = 391
c=50  TPS = 324
c=100 TPS = 256

Начинаем с базовых настроек . Чекаем текущие настройки

    sudo -u postgres psql -c "SHOW shared_buffers;"
    sudo -u postgres psql -c "SHOW fsync;"
    sudo -u postgres psql -c "SHOW synchronous_commit;"
    
    
     shared_buffers 
    ----------------
     128MB
    (1 row)
    
     fsync 
    -------
     on
    (1 row)
    
     synchronous_commit 
    --------------------
     on
    (1 row)


Внесла правки в конфиг 

    sudo vim /etc/postgresql/16/main/postgresql.conf , а именно добавила:

    shared_buffers = 1GB
    effective_cache_size = 2GB
    work_mem = 64MB
    maintenance_work_mem = 512MB
    
    checkpoint_timeout = 30min
    max_wal_size = 2GB
    min_wal_size = 2GB
    wal_buffers = 64MB
    fsync = off
    synchronous_commit = off
    full_page_writes = off
    

на VM - у нас 2 цпу и 4 gb ram
fsync = off и synchronous_commit повышают скорость, но опасны для данных, однако в рамках тестовой бд это не проблема. А так же в задании сказано не обращать внимание на стабильность бд


Перезапустила сервис postgresql

sudo systemctl restart postgresql@16-main

Перепроверяю, что параметры применились:


sudo -u postgres psql -c "SHOW fsync;"
sudo -u postgres psql -c "SHOW synchronous_commit;"
sudo -u postgres psql -c "SHOW full_page_writes;"
 fsync 
-------
 off
(1 row)

 synchronous_commit 
--------------------
 off
(1 row)

 full_page_writes 
------------------
 off
(1 row)


## Задание 4
## Проверьте, насколько выросла производительность.
### Ход действий:

Проверяю pgbench после оптимизации

    sudo -u postgres pgbench -c 10 -j 4 -T 60 otus
    sudo -u postgres pgbench -c 50 -j 4 -T 60 otus
    sudo -u postgres pgbench -c 100 -j 4 -T 60 otus
    
    
    sudo -u postgres pgbench -c 10 -j 4 -T 60 otus
    sudo -u postgres pgbench -c 50 -j 4 -T 60 otus
    sudo -u postgres pgbench -c 100 -j 4 -T 60 otus
    pgbench (16.14 (Ubuntu 16.14-0ubuntu0.24.04.1))
    starting vacuum...end.
    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 100
    query mode: simple
    number of clients: 10
    number of threads: 4
    maximum number of tries: 1
    duration: 60 s
    number of transactions actually processed: 94163
    number of failed transactions: 0 (0.000%)
    latency average = 6.370 ms
    initial connection time = 25.156 ms
    tps = 1569.852065 (without initial connection time)
    pgbench (16.14 (Ubuntu 16.14-0ubuntu0.24.04.1))
    starting vacuum...end.
    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 100
    query mode: simple
    number of clients: 50
    number of threads: 4
    maximum number of tries: 1
    duration: 60 s
    number of transactions actually processed: 205276
    number of failed transactions: 0 (0.000%)
    latency average = 14.596 ms
    initial connection time = 157.162 ms
    tps = 3425.665564 (without initial connection time)
    pgbench (16.14 (Ubuntu 16.14-0ubuntu0.24.04.1))
    starting vacuum...end.
    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 100
    query mode: simple
    number of clients: 100
    number of threads: 4
    maximum number of tries: 1
    duration: 60 s
    number of transactions actually processed: 175374
    number of failed transactions: 0 (0.000%)
    latency average = 34.278 ms
    initial connection time = 182.166 ms
    tps = 2917.285587 (without initial connection time)

Посчитала прирост по формуле:

Прирост, % = ((TPS после - TPS до) / TPS до) * 100


    Количество клиентов    До,TPS	    После,TPS	Рост	Latency до	Latency после
    10	                    391	      1570	 в 4 раза	25,55 ms	6,37 ms
    50	                    324	      3426	 в 10 раз	154,21 ms	14,60 ms
    100	                    266	      2917	 в 11 раз	376,57 ms	34,28 ms

### Вывод: 
В рамках домашней работы была замерена производительность  с помощью pgbench до и после изменения параметров PostgreSQL.После отключения настроек надёжной записи на диск и увеличения буферов производительность выросла. Однако такая конфигурация не подходит для production, так как при сбое возможна потеря или повреждение данных.
