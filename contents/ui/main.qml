import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    readonly property int rateMs: Plasmoid.configuration.updateInterval * 1000

    // Sensors used by the panel strip and tooltip — always subscribed.
    // Popup-only sensors live inside fullRepresentation so they are lazy.
    Sensors.Sensor { id: ramSensor;    sensorId: "memory/physical/usedPercent"; updateRateLimit: root.rateMs }
    Sensors.Sensor { id: ramUsed;      sensorId: "memory/physical/used";        updateRateLimit: root.rateMs }
    Sensors.Sensor { id: ramTotal;     sensorId: "memory/physical/total";       updateRateLimit: root.rateMs }
    Sensors.Sensor { id: diskSensor;   sensorId: "disk/all/usedPercent";        updateRateLimit: root.rateMs }
    Sensors.Sensor { id: diskUsed;     sensorId: "disk/all/used";               updateRateLimit: root.rateMs }
    Sensors.Sensor { id: diskTotal;    sensorId: "disk/all/total";              updateRateLimit: root.rateMs }
    Sensors.Sensor { id: cpuUsage;     sensorId: "cpu/all/usage";               updateRateLimit: root.rateMs }
    Sensors.Sensor { id: cpuTempAvg;   sensorId: "cpu/all/averageTemperature";  updateRateLimit: root.rateMs }
    Sensors.Sensor { id: cpuTempMax;   sensorId: "cpu/all/maximumTemperature";  updateRateLimit: root.rateMs }
    Sensors.Sensor { id: cpuCount;     sensorId: "cpu/all/cpuCount";            updateRateLimit: root.rateMs }
    Sensors.Sensor { id: gpuUsage;     sensorId: "gpu/gpu0/usage";              updateRateLimit: root.rateMs }
    Sensors.Sensor { id: gpuTemp;      sensorId: "gpu/gpu0/temperature";        updateRateLimit: root.rateMs }
    Sensors.Sensor { id: gpuPower;     sensorId: "gpu/gpu0/power";              updateRateLimit: root.rateMs }
    Sensors.Sensor { id: gpuVram;      sensorId: "gpu/gpu0/usedVram";           updateRateLimit: root.rateMs }
    Sensors.Sensor { id: gpuVramTotal; sensorId: "gpu/gpu0/totalVram";          updateRateLimit: root.rateMs }

    // NVIDIA exposes a single GPU temperature, so "peak" is a rolling
    // 10-minute maximum — it self-heals instead of staying red all day.
    property var gpuHistory: []
    readonly property real gpuPeak: gpuHistory.length > 0 ? Math.max(...gpuHistory) : -1

    Timer {
        interval: root.rateMs
        running: true
        repeat: true
        onTriggered: {
            const v = gpuTemp.value;
            if (v === undefined || isNaN(v) || v <= 0) {
                return;
            }
            const maxLen = Math.max(1, Math.round(600000 / root.rateMs));
            let h = root.gpuHistory.slice();
            h.push(v);
            if (h.length > maxLen) {
                h = h.slice(h.length - maxLen);
            }
            root.gpuHistory = h;
        }
    }

    // 0 = normal, 1 = warning (amber) at the configured threshold,
    // 2 = critical (red) at threshold + 10
    function tier(v, threshold) {
        if (v === undefined || isNaN(v)) {
            return 0;
        }
        if (v >= threshold + 10) {
            return 2;
        }
        return v >= threshold ? 1 : 0;
    }

    function tierColor(t) {
        return t === 2 ? Kirigami.Theme.negativeTextColor
             : t === 1 ? Kirigami.Theme.neutralTextColor
             : Kirigami.Theme.textColor;
    }

    function pct(v) {
        return (v === undefined || isNaN(v)) ? "—" : Math.round(v) + "%";
    }

    function deg(v) {
        return (v === undefined || isNaN(v) || v <= 0) ? "—" : Math.round(v) + "°";
    }

    function fmt(sensor) {
        const v = sensor.formattedValue;
        return (v === undefined || v === "") ? "—" : v;
    }

    readonly property int ramTier: tier(ramSensor.value, Plasmoid.configuration.ramThreshold)
    // Disk usage is a capacity fact, not an emergency — never goes red
    readonly property int diskTier: Math.min(tier(diskSensor.value, Plasmoid.configuration.diskThreshold), 1)
    readonly property int cpuUsageTier: tier(cpuUsage.value, Plasmoid.configuration.cpuUsageThreshold)
    readonly property int cpuTempTier: tier(cpuTempMax.value, Plasmoid.configuration.cpuTempThreshold)
    readonly property int gpuUsageTier: tier(gpuUsage.value, Plasmoid.configuration.gpuUsageThreshold)
    readonly property int gpuTempTier: tier(gpuTemp.value, Plasmoid.configuration.gpuTempThreshold)

    toolTipMainText: i18n("System Glance")
    toolTipSubText: [
        i18n("CPU %1 — hottest core %2, average %3",
             pct(cpuUsage.value), deg(cpuTempMax.value), deg(cpuTempAvg.value)),
        i18n("GPU %1 — %2 now, %3 peak (last 10 min)",
             pct(gpuUsage.value), deg(gpuTemp.value), deg(gpuPeak)),
        i18n("RAM %1 — %2 of %3",
             pct(ramSensor.value), fmt(ramUsed), fmt(ramTotal)),
        i18n("Disk %1 — %2 of %3 used",
             pct(diskSensor.value), fmt(diskUsed), fmt(diskTotal)),
        "",
        i18n("Click for the full breakdown")
    ].join("\n")

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: source => disconnectSource(source)
    }

    TextMetrics {
        id: pctMetrics
        font: Kirigami.Theme.defaultFont
        text: "100%"
    }

    TextMetrics {
        id: degMetrics
        font: Kirigami.Theme.defaultFont
        text: "100°"
    }

    component GroupLabel : PC3.Label {
        color: Kirigami.Theme.disabledTextColor
        font: Kirigami.Theme.smallFont
        Layout.alignment: Qt.AlignBaseline
    }

    // Fixed-width, left-aligned, tabular digits: the value hugs its label
    // and the row never shifts as values tick between 1 and 3 digits.
    component Value : PC3.Label {
        property int tier: 0
        property bool temp: false
        horizontalAlignment: Text.AlignLeft
        Layout.alignment: Qt.AlignBaseline
        Layout.preferredWidth: Math.ceil(temp ? degMetrics.advanceWidth : pctMetrics.advanceWidth)
        font.features: ({ "tnum": 1 })
        color: root.tierColor(tier)
    }

    component Group : RowLayout {
        spacing: Kirigami.Units.smallSpacing
    }

    component Sep : PC3.Label {
        text: "|"
        color: Kirigami.Theme.disabledTextColor
        opacity: 0.5
        Layout.alignment: Qt.AlignBaseline
    }

    component SectionHeading : ColumnLayout {
        property alias text: sectionTitle.text

        spacing: Kirigami.Units.smallSpacing
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing

        Kirigami.Separator { Layout.fillWidth: true }

        PlasmaExtras.Heading {
            id: sectionTitle
            level: 4
        }
    }

    component DetailLabel : PC3.Label {
        font.features: ({ "tnum": 1 })
    }

    component DimLabel : PC3.Label {
        color: Kirigami.Theme.disabledTextColor
        font: Kirigami.Theme.smallFont
    }

    compactRepresentation: Item {
        Layout.preferredWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.minimumWidth: Layout.preferredWidth
        Layout.fillHeight: true

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing * 2

            Group {
                GroupLabel { text: i18n("RAM") }
                Value { text: root.pct(ramSensor.value); tier: root.ramTier }
            }

            Sep {}

            Group {
                GroupLabel { text: i18n("DISK") }
                Value { text: root.pct(diskSensor.value); tier: root.diskTier }
            }

            Sep {}

            Group {
                GroupLabel { text: i18n("CPU") }
                Value { text: root.pct(cpuUsage.value); tier: root.cpuUsageTier }
                Value { text: root.deg(cpuTempMax.value); tier: root.cpuTempTier; temp: true }
            }

            Sep {}

            Group {
                GroupLabel { text: i18n("GPU") }
                Value { text: root.pct(gpuUsage.value); tier: root.gpuUsageTier }
                Value { text: root.deg(gpuTemp.value); tier: root.gpuTempTier; temp: true }
            }
        }
    }

    fullRepresentation: Item {
        id: popup

        Layout.preferredWidth: content.implicitWidth + Kirigami.Units.largeSpacing * 2
        Layout.preferredHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight

        // Popup-only sensors — instantiated on first expand
        Sensors.Sensor { id: gpuName;      sensorId: "gpu/gpu0/name";              updateRateLimit: root.rateMs }
        Sensors.Sensor { id: gpuCoreFreq;  sensorId: "gpu/gpu0/coreFrequency";     updateRateLimit: root.rateMs }
        Sensors.Sensor { id: gpuMemFreq;   sensorId: "gpu/gpu0/memoryFrequency";   updateRateLimit: root.rateMs }
        Sensors.Sensor { id: ramFree;      sensorId: "memory/physical/free";       updateRateLimit: root.rateMs }
        Sensors.Sensor { id: swapUsed;     sensorId: "memory/swap/used";           updateRateLimit: root.rateMs }
        Sensors.Sensor { id: swapTotal;    sensorId: "memory/swap/total";          updateRateLimit: root.rateMs }
        Sensors.Sensor { id: diskFree;     sensorId: "disk/all/free";              updateRateLimit: root.rateMs }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                PlasmaExtras.Heading {
                    level: 3
                    text: i18n("System Glance")
                    Layout.fillWidth: true
                }
                PC3.ToolButton {
                    icon.name: "utilities-system-monitor"
                    display: PC3.ToolButton.IconOnly
                    text: i18n("Open System Monitor")
                    PC3.ToolTip.text: text
                    PC3.ToolTip.visible: hovered
                    onClicked: {
                        exec.connectSource("plasma-systemmonitor");
                        root.expanded = false;
                    }
                }
            }

            SectionHeading { text: i18n("Memory") }
            DetailLabel {
                text: i18n("Used %1 — free %2 — of %3 (%4)",
                           root.fmt(ramUsed), root.fmt(ramFree), root.fmt(ramTotal), root.pct(ramSensor.value))
            }
            DetailLabel {
                text: i18n("Swap: %1 of %2 used", root.fmt(swapUsed), root.fmt(swapTotal))
            }

            SectionHeading { text: i18n("Disks") }

            GridLayout {
                columns: 3
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing / 2

                DimLabel { text: i18n("All disks") }
                DetailLabel {
                    text: root.pct(diskSensor.value)
                    color: root.tierColor(root.diskTier)
                }
                DetailLabel { text: i18n("%1 used, %2 free of %3", root.fmt(diskUsed), root.fmt(diskFree), root.fmt(diskTotal)) }

                Repeater {
                    model: [
                        "disk/26c40217-e4a6-4ebd-bb3b-c6a5d2fb27dd",
                        "disk/f777a7d5-e2be-4bbb-ba34-8331ab01a060"
                    ]

                    delegate: DimLabel {
                        id: partNameLabel

                        required property string modelData
                        required property int index

                        Sensors.Sensor { id: partName; sensorId: partNameLabel.modelData + "/name"; updateRateLimit: root.rateMs }

                        text: root.fmt(partName)
                        Layout.row: 1 + index
                        Layout.column: 0
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                        elide: Text.ElideMiddle
                    }
                }

                Repeater {
                    model: [
                        "disk/26c40217-e4a6-4ebd-bb3b-c6a5d2fb27dd",
                        "disk/f777a7d5-e2be-4bbb-ba34-8331ab01a060"
                    ]

                    delegate: DetailLabel {
                        id: partPctLabel

                        required property string modelData
                        required property int index

                        Sensors.Sensor { id: partPct; sensorId: partPctLabel.modelData + "/usedPercent"; updateRateLimit: root.rateMs }

                        text: root.pct(partPct.value)
                        Layout.row: 1 + index
                        Layout.column: 1
                    }
                }

                Repeater {
                    model: [
                        "disk/26c40217-e4a6-4ebd-bb3b-c6a5d2fb27dd",
                        "disk/f777a7d5-e2be-4bbb-ba34-8331ab01a060"
                    ]

                    delegate: DetailLabel {
                        id: partDetailLabel

                        required property string modelData
                        required property int index

                        Sensors.Sensor { id: partUsed;  sensorId: partDetailLabel.modelData + "/used";  updateRateLimit: root.rateMs }
                        Sensors.Sensor { id: partFree;  sensorId: partDetailLabel.modelData + "/free";  updateRateLimit: root.rateMs }
                        Sensors.Sensor { id: partTotal; sensorId: partDetailLabel.modelData + "/total"; updateRateLimit: root.rateMs }

                        text: i18n("%1 used, %2 free of %3", root.fmt(partUsed), root.fmt(partFree), root.fmt(partTotal))
                        Layout.row: 1 + index
                        Layout.column: 2
                    }
                }
            }

            SectionHeading { text: i18n("CPU") }
            DetailLabel {
                text: i18n("%1 — hottest core %2, average %3",
                           root.pct(cpuUsage.value), root.deg(cpuTempMax.value), root.deg(cpuTempAvg.value))
            }

            GridLayout {
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing * 2
                rowSpacing: 0

                Repeater {
                    model: cpuCount.value !== undefined ? cpuCount.value : 0

                    delegate: RowLayout {
                        id: coreRow

                        required property int index

                        spacing: Kirigami.Units.smallSpacing

                        Sensors.Sensor { id: coreUsage; sensorId: "cpu/cpu" + coreRow.index + "/usage";       updateRateLimit: root.rateMs }
                        Sensors.Sensor { id: coreTemp;  sensorId: "cpu/cpu" + coreRow.index + "/temperature"; updateRateLimit: root.rateMs }
                        Sensors.Sensor { id: coreFreq;  sensorId: "cpu/cpu" + coreRow.index + "/frequency";   updateRateLimit: root.rateMs }

                        DimLabel {
                            text: "C" + (coreRow.index < 10 ? "0" : "") + coreRow.index
                        }
                        DetailLabel {
                            text: root.pct(coreUsage.value)
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: Math.ceil(pctMetrics.advanceWidth)
                        }
                        DetailLabel {
                            text: root.deg(coreTemp.value)
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: Math.ceil(degMetrics.advanceWidth)
                        }
                        DetailLabel {
                            text: root.fmt(coreFreq)
                            color: Kirigami.Theme.disabledTextColor
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        }
                    }
                }
            }

            SectionHeading { text: root.fmt(gpuName) !== "—" ? i18n("GPU — %1", root.fmt(gpuName)) : i18n("GPU") }
            DetailLabel {
                text: i18n("%1 — %2 now, %3 peak (last 10 min)",
                           root.pct(gpuUsage.value), root.deg(gpuTemp.value), root.deg(root.gpuPeak))
            }
            DetailLabel {
                text: i18n("VRAM %1 of %2 — drawing %3",
                           root.fmt(gpuVram), root.fmt(gpuVramTotal), root.fmt(gpuPower))
            }
            DetailLabel {
                text: i18n("Clocks: core %1, memory %2",
                           root.fmt(gpuCoreFreq), root.fmt(gpuMemFreq))
            }

            Item { Layout.fillHeight: true }
        }
    }
}
