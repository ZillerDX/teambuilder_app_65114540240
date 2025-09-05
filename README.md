Pokemon App พัฒนาด้วย Flutter - 65114540240

Tech Stack 

Flutter: 3.35.3 (stable)

Dart: 3.9.2 (มาพร้อม Flutter)

SDK Target (Android ที่แนะนำ): Android SDK Platform 34/35

IDE ที่รองรับ: VS Code / Android Studio / IntelliJ

System Requirements (ตามแพลตฟอร์ม)

Windows 10/11

เปิด Developer Mode เพื่อให้ใช้งาน symlink กับ plugins ได้ (จำเป็นมาก) ⚠️

start ms-settings:developers


ถ้าจะ build/run แบบ Windows Desktop ให้ติดตั้ง Visual Studio Build Tools 2022 และเลือก workload/component:

MSVC v143, C++ CMake tools, Windows 10/11 SDK

Android

ติดตั้ง Android Studio, Android SDK, Platform Tools, Build-Tools, Command-line Tools (latest)

ยอมรับ licenses ทั้งหมด:

flutter doctor --android-licenses


Web

Chrome หรือเบราว์เซอร์ Chromium


เริ่มต้นอย่างรวดเร็ว (Clone & Run) ✨
# 1) โคลนโปรเจกต์
git clone https://github.com/ZillerDX/Pokemon_app65114540240.git
cd pkm01 และ cd teambuilder_app

# 2) ตรวจเวอร์ชัน (ควรเห็น Flutter 3.35.3 / Dart 3.9.2)
flutter --version

# 3) ติดตั้ง dependencies
flutter pub get

รันบน Web 
flutter run -d chrome
