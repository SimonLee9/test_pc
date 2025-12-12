#include <iostream>
#include <thread>
#include <chrono>
#include "libobsensor/ObSensor.hpp"

int main() {
    // 로그 레벨 최소화
    ob::Context::setLoggerSeverity(OB_LOG_SEVERITY_ERROR);

    try {
        // 컨텍스트 생성
        ob::Context ctx;

        // 장치 목록 조회
        auto devList = ctx.queryDeviceList();
        
        if (devList->deviceCount() == 0) {
            return 1; // 장치 없음
        }

        // 첫 번째 장치 정보 가져오기
        auto dev = devList->getDevice(0);
        auto devInfo = dev->getDeviceInfo();
        
        // 연결 성공 메시지 출력
        std::cout << "Device: " << devInfo->name();
        
        // 2초간 연결 유지 (스트리밍 시뮬레이션)
        std::this_thread::sleep_for(std::chrono::seconds(2));
        
        return 0; // 성공
        
    } catch(ob::Error &e) {
        std::cerr << "SDK Error: " << e.getMessage();
        return 1;
    } catch(std::exception &e) {
        std::cerr << "Exception: " << e.what();
        return 1;
    }
}
