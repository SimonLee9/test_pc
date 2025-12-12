#!/bin/bash

# =======================================================
# 1. 경로 설정 (사용자 환경에 맞춰 고정)
# =======================================================
# 헤더 파일이 있는 곳 (-I 옵션용)
INCLUDE_DIR="/home/afe-r360/OrbbecSDK/SDK/include"

# .so 라이브러리 파일이 있는 곳 (-L 옵션용)
LIB_DIR="/home/afe-r360/slamnav2"

echo "=== Orbbec C++ 연결 테스트 준비 ==="
echo "헤더 경로: $INCLUDE_DIR"
echo "라이브러리 경로: $LIB_DIR"

# 런타임 라이브러리 경로 설정 (실행 시 .so를 찾기 위해 필수)
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LIB_DIR

# =======================================================
# 2. C++ 소스 코드 생성 (임시 파일)
# =======================================================
cat <<EOF > test_connect.cpp
#include <iostream>
#include <thread>
#include <chrono>
#include "libobsensor/ObSensor.hpp"

int main() {
    // 로그 레벨을 에러만 표시하도록 설정 (깔끔한 출력을 위해)
    ob::Context::setLoggerSeverity(OB_LOG_SEVERITY_ERROR);

    try {
        // 컨텍스트 생성
        ob::Context ctx;

        // 장치 목록 조회 (이 함수가 장치를 제대로 불러오는지 확인하는 핵심)
        auto devList = ctx.queryDeviceList();
        
        if (devList->deviceCount() == 0) {
            // 장치 없음
            return 1; 
        }

        // 첫 번째 장치 정보 가져오기 시도
        auto dev = devList->getDevice(0);
        auto devInfo = dev->getDeviceInfo();
        
        //
