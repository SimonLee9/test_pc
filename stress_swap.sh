#!/bin/bash

# ========================================================
# 우분투 시스템 부하 테스트 (CPU + RAM + Swap)
# ========================================================

cleanup() {
    echo ""
    echo "=========================================="
    echo "[!] 테스트를 종료합니다. 정리 중..."
    
    # 백그라운드로 실행된 yes(CPU)와 python(RAM) 프로세스 종료
    if [ -n "$pids" ]; then
        kill $pids 2>/dev/null
        wait $pids 2>/dev/null
    fi
    
    echo "[*] 모든 부하 프로세스가 종료되었습니다."
    exit
}

trap cleanup SIGINT

echo "#############################################"
echo "#     PC 극한 테스트 (CPU & RAM & Swap)     #"
echo "#############################################"

# --- 1. 시스템 자원 확인 ---
# free 명령어로 물리 메모리와 스왑 크기 파악 (MB 단위)
real_mem=$(free -m | awk '/^Mem:/{print $2}')
swap_mem=$(free -m | awk '/^Swap:/{print $2}')
total_avail=$((real_mem + swap_mem))

echo "[*] 시스템 사양 감지:"
echo "    - 물리 메모리(RAM): ${real_mem} MB"
echo "    - 스왑 메모리(Swap): ${swap_mem} MB"
echo "    - 최대 가용 한계:    ${total_avail} MB"
echo ""

# --- 2. CPU 부하 설정 ---
cpu_limit=$(nproc)
echo -n "[?] 부하를 줄 CPU 코어 개수 (최대 $cpu_limit): "
read cpu_count

if [[ ! "$cpu_count" =~ ^[0-9]+$ ]] || [ "$cpu_count" -le 0 ]; then
    cpu_count=0
fi

# --- 3. 메모리(Swap 포함) 부하 설정 ---
echo "---------------------------------------------------------"
echo "(!) 팁: 스왑을 테스트하려면 '물리 메모리'보다 큰 값을 입력하세요."
echo "    예) 물리 8GB(8000)라면 -> 9000 입력 시 약 1GB 스왑 사용"
echo "---------------------------------------------------------"
echo -n "[?] 점유할 메모리 크기(MB) 입력: "
read mem_size

if [[ ! "$mem_size" =~ ^[0-9]+$ ]] || [ "$mem_size" -le 0 ]; then
    mem_size=0
fi

# 안전 경고
if [ "$mem_size" -gt "$total_avail" ]; then
    echo ""
    echo "[WARNING] 입력한 크기($mem_size MB)가 시스템 총 한계($total_avail MB)를 초과합니다."
    echo "시스템이 완전히 멈추거나(Freezing) 프로세스가 강제 종료(OOM Killer)될 수 있습니다."
    echo -n "정말 진행하시겠습니까? (y/n): "
    read confirm
    if [ "$confirm" != "y" ]; then
        echo "테스트를 취소합니다."
        exit
    fi
fi

echo ""
echo "=========================================="
echo "테스트 시작... (중지하려면 Ctrl+C)"

pids=""

# [실행 1] 메모리 부하 (Python 활용)
# 파이썬을 이용해 실제 메모리 공간(Anonymous Memory)을 할당합니다.
# 이렇게 하면 OS는 물리 메모리가 부족할 때 이 데이터를 스왑으로 내립니다.
if [ "$mem_size" -gt 0 ]; then
    echo "[*] 메모리 ${mem_size}MB 할당 프로세스 시작..."
    
    # 파이썬 스크립트 설명:
    # 1. 'a' * (MB * 1024 * 1024) 로 거대한 문자열 생성 (RAM 점유)
    # 2. time.sleep으로 프로세스 유지
    # 3. 바이트 단위 계산을 위해 정수로 변환
    python3 -c "import time; data = bytearray($mem_size * 1024 * 1024); time.sleep(999999)" &
    
    pids="$pids $!" # 프로세스 ID 저장
    echo " -> 메모리 점유 시작 (PID: $!). Swap 사용 여부를 htop으로 확인하세요."
fi

# [실행 2] CPU 부하
if [ "$cpu_count" -gt 0 ]; then
    echo "[*] CPU 코어 ${cpu_count}개 가동..."
    for ((i=1; i<=cpu_count; i++)); do
        yes > /dev/null &
        pids="$pids $!"
    done
fi

echo "=========================================="
echo "실행 중입니다. 시스템이 느려질 수 있습니다."
echo "상태 모니터링: 새 터미널에서 'htop' 또는 'free -h' 입력"

# 무한 대기
while true; do
    sleep 1
done
