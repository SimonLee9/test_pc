#!/bin/bash

# ==========================================
# 설정 (환경에 맞게 조정하세요)
# ==========================================
MAX_CYCLES=20           # 전체 테스트 반복 횟수
MAX_RETRIES=10          # 한 사이클 내에서 연결 재시도 최대 횟수
RETRY_DELAY=0.5         # 연결 실패 시 대기 시간 (초)
STREAM_TIME=2           # 연결 성공 시 스트리밍 유지 시간 (초)
LOG_FILE="camera_test_log.txt"
# ==========================================

# 로그 파일 초기화
echo "=== Orbbec 카메라 연결 테스트 시작 ($(date)) ===" > "$LOG_FILE"
echo "설정: 총 $MAX_CYCLES 사이클, 사이클 당 최대 $MAX_RETRIES 회 재시도" | tee -a "$LOG_FILE"
echo "------------------------------------------------------" | tee -a "$LOG_FILE"

# 파이썬 바인딩 확인
if ! python3 -c "import pyorbbecsdk" 2>/dev/null; then
    echo "오류: 'pyorbbecsdk'가 설치되어 있지 않습니다."
    echo "먼저 파이썬 환경을 확인해주세요."
    exit 1
fi

# ==========================================
# 테스트 루프
# ==========================================
for (( cycle=1; cycle<=MAX_CYCLES; cycle++ ))
do
    echo -n "[Cycle $cycle] 연결 시도 중..."
    
    start_time=$(date +%s.%N)
    success=false
    
    for (( try_num=1; try_num<=MAX_RETRIES; try_num++ ))
    do
        # ---------------------------------------------------------
        # Python One-liner를 이용한 SDK 연결 테스트
        # exit 0: 성공
        # exit 1: 실패 (SDK 에러, 리소스 점유 등)
        # ---------------------------------------------------------
        python3 -c "
import sys, time
from pyorbbecsdk import Pipeline, Config, OBSensorType

try:
    # 1. 파이프라인 생성
    pipeline = Pipeline()
    config = Config()
    
    # 2. 프로필 조회 (장치 인식 확인)
    profile_list = pipeline.get_stream_profile_list(OBSensorType.DEPTH_SENSOR)
    if profile_list is None:
        sys.exit(1) # 장치 없음
        
    # 3. 스트리밍 시작 (리소스 점유 확인)
    depth_profile = profile_list.get_default_video_stream_profile()
    config.enable_stream(depth_profile)
    pipeline.start(config)
    
    # 4. 성공 시 잠시 대기 (스트리밍 시뮬레이션)
    time.sleep($STREAM_TIME)
    
    # 5. 종료
    pipeline.stop()
    sys.exit(0) # 성공
except Exception as e:
    sys.exit(1) # 실패
"
        # ---------------------------------------------------------
        # 결과 확인
        # ---------------------------------------------------------
        if [ $? -eq 0 ]; then
            end_time=$(date +%s.%N)
            duration=$(echo "$end_time - $start_time" | bc)
            
            # 소수점 둘째자리까지 자르기
            duration_formatted=$(printf "%.2f" $duration)
            
            msg="성공 ✅ (시도 횟수: ${try_num}회, 소요 시간: ${duration_formatted}초)"
            echo " $msg"
            echo "[$(date '+%H:%M:%S')] Cycle $cycle: $msg" >> "$LOG_FILE"
            success=true
            break
        else
            # 실패 시 점 찍기 (진행상황 표시)
            echo -n "."
            sleep $RETRY_DELAY
        fi
    done

    if [ "$success" = false ]; then
        msg="실패 ❌ ($MAX_RETRIES 회 시도 후 연결 불가)"
        echo " $msg"
        echo "[$(date '+%H:%M:%S')] Cycle $cycle: $msg" >> "$LOG_FILE"
        
        # 연속 실패 시 잠시 긴 대기 (옵션)
        sleep 2
    fi
    
    # 다음 사이클로 바로 넘어감 (즉시 재연결 테스트를 위해 별도 sleep 없음)
done

echo "------------------------------------------------------" | tee -a "$LOG_FILE"
echo "테스트 완료. 로그 파일: $LOG_FILE"
