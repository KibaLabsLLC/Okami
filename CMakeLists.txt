cmake_minimum_required(VERSION 3.20)

project(okami VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

include(GNUInstallDirs)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

# ─────────────────────────────────────────────
# Qt6, fallback to Qt5
# ─────────────────────────────────────────────

find_package(Qt6 COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Widgets
    Network
)

if(NOT Qt6_FOUND)
    message(STATUS "Qt6 not found, falling back to Qt5")

    find_package(Qt5 REQUIRED COMPONENTS
        Core
        Gui
        Qml
        Quick
        QuickControls2
        Widgets
        Network
    )

    set(QT_VERSION_MAJOR 5)
else()
    set(QT_VERSION_MAJOR 6)
endif()

# ─────────────────────────────────────────────
# KDE Frameworks 6, fallback to 5
# ─────────────────────────────────────────────

find_package(KF6 COMPONENTS
    Kirigami
    I18n
    CoreAddons
)

if(NOT KF6_FOUND)
    message(STATUS "KF6 not found, falling back to KF5")

    find_package(KF5 REQUIRED COMPONENTS
        Kirigami2
        I18n
        CoreAddons
    )

    set(KDE_KIRIGAMI KF5::Kirigami2)
    set(KDE_I18N KF5::I18n)
    set(KDE_COREADDONS KF5::CoreAddons)
else()
    set(KDE_KIRIGAMI KF6::Kirigami)
    set(KDE_I18N KF6::I18n)
    set(KDE_COREADDONS KF6::CoreAddons)
endif()

# ─────────────────────────────────────────────
# Okami
# ─────────────────────────────────────────────

add_executable(okami
    src/main.cpp
    src/kstorebackend.cpp
    src/kstorebackend.h
    src/resources.qrc
)

target_link_libraries(okami
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Gui
    Qt${QT_VERSION_MAJOR}::Qml
    Qt${QT_VERSION_MAJOR}::Quick
    Qt${QT_VERSION_MAJOR}::QuickControls2
    Qt${QT_VERSION_MAJOR}::Widgets
    Qt${QT_VERSION_MAJOR}::Network
    ${KDE_KIRIGAMI}
    ${KDE_I18N}
    ${KDE_COREADDONS}
)

# ─────────────────────────────────────────────
# Generate okami.desktop
# ─────────────────────────────────────────────

set(DESKTOP_FILE "${CMAKE_CURRENT_BINARY_DIR}/okami.desktop")

file(WRITE "${DESKTOP_FILE}"
"[Desktop Entry]\n"
"Name=Okami\n"
"Comment=KibaOS Software Store\n"
"Exec=okami\n"
"Icon=okami\n"
"Terminal=false\n"
"Type=Application\n"
"Categories=System;PackageManager;Utility;\n"
"StartupNotify=true\n"
)

# ─────────────────────────────────────────────
# Automatically install Okami when built
# ─────────────────────────────────────────────

add_custom_command(TARGET okami POST_BUILD

    # Make sure destination directories exist
    COMMAND ${CMAKE_COMMAND} -E make_directory
        /usr/bin

    COMMAND ${CMAKE_COMMAND} -E make_directory
        /usr/share/applications

    # Install executable
    COMMAND ${CMAKE_COMMAND} -E copy
        "$<TARGET_FILE:okami>"
        /usr/bin/okami

    # Install desktop entry
    COMMAND ${CMAKE_COMMAND} -E copy
        "${DESKTOP_FILE}"
        /usr/share/applications/okami.desktop

    COMMENT "Installing Okami to /usr/bin and registering desktop entry"
)

# ─────────────────────────────────────────────
# Tests
# ─────────────────────────────────────────────

enable_testing()

add_executable(test_backend
    tests/test_backend.cpp
    src/kstorebackend.cpp
    src/kstorebackend.h
)

target_link_libraries(test_backend
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Network
    ${KDE_COREADDONS}
    ${KDE_I18N}
)

add_test(
    NAME test_backend
    COMMAND test_backend
)

add_executable(test_functional
    tests/test_functional.cpp
    src/kstorebackend.cpp
    src/kstorebackend.h
)

target_link_libraries(test_functional
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Network
    ${KDE_COREADDONS}
    ${KDE_I18N}
)

add_test(
    NAME test_functional
    COMMAND test_functional
)
