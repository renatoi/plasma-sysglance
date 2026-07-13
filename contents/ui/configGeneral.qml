import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    // Absorb the cfg_<key>Default initial properties the config dialog sets
    property int cfg_updateIntervalDefault: 0
    property int cfg_ramThresholdDefault: 0
    property int cfg_diskThresholdDefault: 0
    property int cfg_cpuUsageThresholdDefault: 0
    property int cfg_cpuTempThresholdDefault: 0
    property int cfg_gpuUsageThresholdDefault: 0
    property int cfg_gpuTempThresholdDefault: 0

    property alias cfg_updateInterval: updateIntervalSpin.value
    property alias cfg_ramThreshold: ramSpin.value
    property alias cfg_diskThreshold: diskSpin.value
    property alias cfg_cpuUsageThreshold: cpuUsageSpin.value
    property alias cfg_cpuTempThreshold: cpuTempSpin.value
    property alias cfg_gpuUsageThreshold: gpuUsageSpin.value
    property alias cfg_gpuTempThreshold: gpuTempSpin.value

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: updateIntervalSpin
            Kirigami.FormData.label: i18n("Update interval (seconds):")
            from: 1
            to: 60
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Values turn amber at the threshold and red at threshold + 10. Disk only ever turns amber.")
        }

        QQC2.SpinBox {
            id: ramSpin
            Kirigami.FormData.label: i18n("RAM alert threshold (%):")
            from: 1
            to: 100
        }

        QQC2.SpinBox {
            id: diskSpin
            Kirigami.FormData.label: i18n("Disk alert threshold (%):")
            from: 1
            to: 100
        }

        QQC2.SpinBox {
            id: cpuUsageSpin
            Kirigami.FormData.label: i18n("CPU usage alert threshold (%):")
            from: 1
            to: 100
        }

        QQC2.SpinBox {
            id: cpuTempSpin
            Kirigami.FormData.label: i18n("CPU temperature alert (°C):")
            from: 30
            to: 110
        }

        QQC2.SpinBox {
            id: gpuUsageSpin
            Kirigami.FormData.label: i18n("GPU usage alert threshold (%):")
            from: 1
            to: 100
        }

        QQC2.SpinBox {
            id: gpuTempSpin
            Kirigami.FormData.label: i18n("GPU temperature alert (°C):")
            from: 30
            to: 110
        }
    }
}
