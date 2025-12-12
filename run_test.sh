#!/bin/bash

# =======================================================
# 설정
# =======================================================
INCLUDE_DIR="/home/afe-r360/OrbbecSDK/SDK/include"
LIB_DIR="/home/afe-r360/slamnav2"
LOG_FILE="cpp_test_log.txt"

# 1. 실제 라이브러리 파일 이름 찾기 (자동 감지)
# libOrbbecSDK.so 로 시작하는 파일 중 하나를 찾음
REAL_LIB=$(find "$LIB_DIR" -name "libOrbbecSDK.so*" | head -n 1)

echo "=== 컴파일 시작 ==="
echo "헤더 경로: $INCLUDE_DIR"
echo "라이브러리 경로: $LIB_DIR"

if [ -z "$REAL_LIB" ]; then
    echo "❌ 오류: $LIB_DIR 폴더 안에 'libOrbbecSDK.so' 관련 파일을 찾을 수 없습니다."
    exit 1
fi

echo "감지된 라이브러리 파일: $REAL_LIB"

# 실행 시 라이브러리 로드를 위한 환경변수 설정
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LIB_DIR

# 2. 컴파일 (test_connect.cpp -> test_orbbec_bin)
# -l 옵션 대신 찾은 파일 경로($REAL_LIB)를 직접 넣어서 컴파일합니다.
g++ -std=c++11 test_connect.cpp -o test_orbbec_bin \
    "$REAL_LIB" \
    -I"$INCLUDE_DIR" \
    -Wl,-rpath,"$LIB_DIR" \
    -lpthread

if [ $? -ne 0 ]; then
    echo "❌ 컴파일 실패! 에러 메시지를 확인해주세요."
    exit 1
fi

echo "✅ 컴파일 성공!"
echo "------------------------------------------------------"

# =======================================================
# 테스트 루프
# =======================================================
MAX_CYCLES=20
MAX_RETRIES=10
RETRY_DELAY=0.5

echo "=== 테스트 시작 ($(date)) ===" > "$LOG_FILE"

for (( cycle=1; cycle<=MAX_CYCLES; cycle++ ))
do
    echo -n "[Cycle $cycle] 연결 시도 중..."
    
    start_time=$(date +%s.%N)
    success=false
    
    for (( try_num=1; try_num<=MAX_RETRIES; try_num++ ))
    do
        # 컴파일된 프로그램 실행
        OUTPUT=$(./test_orbbec_bin 2>&1)
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ]; then
            end_time=$(date +%s.%N)
            duration=$(echo "$end_time - $start_time" | bc)
            duration_formatted=$(printf "%.2f" $duration)
            
            msg="성공 ✅ (시도: ${try_num}회, 소요: ${duration_formatted}초)"
            echo " $msg"
            echo "[$(date '+%H:%M:%S')] Cycle $cycle: $msg" >> "$LOG_FILE"
            success=true
            break
        else
            echo -n "."
            sleep $RETRY_DELAY
        fi
    done

    if [ "$success" = false ]; then
        msg="실패 ❌ (에러: $OUTPUT)"
        echo " $msg"
        echo "[$(date '+%H:%M:%S')] Cycle $cycle: $msg" >> "$LOG_FILE"
        sleep 2
    fi
done

echo "------------------------------------------------------"
echo "테스트 완료. 결과 로그: $LOG_FILE"
