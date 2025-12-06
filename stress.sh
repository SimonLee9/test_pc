#!/bin/bash

# ==========================================
# 우분투 시스템 부하 테스트 스크립트 (Bash)
# ==========================================

# 종료 시 정리 함수 (Ctrl+C 눌렀을 때 실행)
cleanup() {
    echo ""
    echo "=========================================="
    echo "[!] 테스트를 종료합니다. 정리 중..."
    
    # 1. 백그라운드에서 실행 중인 'yes' 프로세스(CPU 부하) 종료
    if [ -n "$pids" ]; then
        echo " -> CPU 부하 프로세스 종료 중..."
        kill $pids 2>/dev/null
    fi

    # 2. RAM 점유를 위해 생성한 임시 파일 삭제
    if [ -f /dev/shm/ram_stress_test ]; then
        echo " -> 할당된 메모리 해제 중 (/dev/shm 파일 삭제)..."
        rm -f /dev/shm/ram_stress_test
    fi
    
    echo "[*] 완료."
    exit
}

# 트랩 설정: SIGINT(Ctrl+C) 신호를 받으면 cleanup 함수 실행
trap cleanup SIGINT

echo "#############################################"
echo "#        PC 상태 테스트 (CPU & RAM)         #"
echo "#############################################"

# --- 1. CPU 부하 설정 ---
total_cores=$(nproc)
echo -n "[?] 사용할 CPU 코어 개수를 입력하세요 (전체: $total_cores): "
read cpu_count

if [[ ! "$cpu_count" =~ ^[0-9]+$ ]] || [ "$cpu_count" -le 0 ]; then
    cpu_count=0
    echo " -> CPU 테스트를 건너뜁니다."
fi

# --- 2. RAM 부하 설정 ---
# 현재 가용 메모리 확인 (MB 단위)
free_mem=$(free -m | awk '/^Mem:/{print $7}')
echo -n "[?] 점유할 메모리 크기(MB)를 입력하세요 (현재 가용: ${free_mem}MB): "
read mem_size

if [[ ! "$mem_size" =~ ^[0-9]+$ ]] || [ "$mem_size" -le 0 ]; then
    mem_size=0
    echo " -> 메모리 테스트를 건너뜁니다."
else
    # 안전장치: 가용 메모리보다 크게 입력하면 경고
    if [ "$mem_size" -ge "$free_mem" ]; then
        echo "[!] 경고: 가용 메모리보다 큰 값을 입력했습니다. 시스템이 멈출 수 있습니다."
        echo -n "    그래도 진행하시겠습니까? (y/n): "
        read confirm
        if [ "$confirm" != "y" ]; then
            mem_size=0
            echo " -> 메모리 테스트를 취소합니다."
        fi
    fi
fi

echo ""
echo "=========================================="
echo "테스트 시작... (종료하려면 Ctrl+C를 누르세요)"

# [실행 1] 메모리 부하 (dd 명령어로 /dev/shm에 파일 생성)
# /dev/shm은 리눅스의 공유 메모리로, 여기에 파일을 쓰면 실제 RAM을 점유합니다.
if [ "$mem_size" -gt 0 ]; then
    echo "[*] RAM ${mem_size}MB 할당 중..."
    # /dev/zero를 읽어서 /dev/shm에 지정된 크기만큼 씀
    dd if=/dev/zero of=/dev/shm/ram_stress_test bs=1M count=$mem_size status=none
    echo " -> RAM 할당 완료."
fi

# [실행 2] CPU 부하 (yes 명령어를 /dev/null로 리다이렉션)
# 'yes'는 무한히 'y'를 출력하는 가벼운 명령어지만, 이를 계속 실행하면 CPU 코어를 100% 씁니다.
if [ "$cpu_count" -gt 0 ]; then
    echo "[*] CPU 코어 ${cpu_count}개에 부하를 주는 중..."
    pids=""
    for ((i=1; i<=cpu_count; i++)); do
        yes > /dev/null &
        pids="$pids $!" # 실행된 프로세스 ID 저장
    done
fi

echo "=========================================="
echo "현재 부하가 걸려있습니다. 모니터링 도구(htop 등)로 확인하세요."
echo "대기 중..."

# 무한 대기 (종료 시그널 기다림)
while true; do
    sleep 1
done
