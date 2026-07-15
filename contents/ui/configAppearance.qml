import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    id: page

    // Align content with the dialog's page title, which is inset ~1 gridUnit
    leftPadding: Kirigami.Units.gridUnit
    rightPadding: Kirigami.Units.gridUnit
    topPadding: Kirigami.Units.largeSpacing
    bottomPadding: Kirigami.Units.largeSpacing

    // Absorb the cfg_<key>Default initial properties the config dialog sets
    property string cfg_metricOrderDefault: ""
    property bool cfg_ramShownDefault: false
    property bool cfg_diskShownDefault: false
    property bool cfg_cpuShownDefault: false
    property bool cfg_gpuShownDefault: false
    property string cfg_ramPartsDefault: ""
    property string cfg_diskPartsDefault: ""
    property string cfg_cpuPartsDefault: ""
    property string cfg_gpuPartsDefault: ""
    property string cfg_ramFormatDefault: ""
    property string cfg_diskFormatDefault: ""
    property string cfg_cpuFormatDefault: ""
    property string cfg_gpuFormatDefault: ""
    property int cfg_labelStyleDefault: 0
    property string cfg_ramLabelDefault: ""
    property string cfg_diskLabelDefault: ""
    property string cfg_cpuLabelDefault: ""
    property string cfg_gpuLabelDefault: ""
    property string cfg_ramIconDefault: ""
    property string cfg_diskIconDefault: ""
    property string cfg_cpuIconDefault: ""
    property string cfg_gpuIconDefault: ""
    property int cfg_fontSizeDefault: 0
    property string cfg_fontFamilyDefault: ""
    property int cfg_valueWidthDefault: 0
    property bool cfg_showSeparatorsDefault: false
    property string cfg_separatorColorDefault: ""
    property int cfg_valueGapDefault: 0
    property int cfg_groupGapDefault: 0
    property bool cfg_customTextColorDefault: false
    property bool cfg_customLabelColorDefault: false
    property bool cfg_customSeparatorColorDefault: false
    property bool cfg_customWarningColorDefault: false
    property bool cfg_customCriticalColorDefault: false
    property string cfg_textColorDefault: ""
    property string cfg_labelColorDefault: ""
    property string cfg_warningColorDefault: ""
    property string cfg_criticalColorDefault: ""

    // The dialog pushes every config key into every page — absorb the
    // General page's keys so they don't log warnings here.
    property int cfg_updateInterval; property int cfg_updateIntervalDefault: 0
    property int cfg_ramThreshold; property int cfg_ramThresholdDefault: 0
    property int cfg_diskThreshold; property int cfg_diskThresholdDefault: 0
    property int cfg_cpuUsageThreshold; property int cfg_cpuUsageThresholdDefault: 0
    property int cfg_cpuTempThreshold; property int cfg_cpuTempThresholdDefault: 0
    property int cfg_gpuUsageThreshold; property int cfg_gpuUsageThresholdDefault: 0
    property int cfg_gpuTempThreshold; property int cfg_gpuTempThresholdDefault: 0

    // Strip content: metricOrder + per-metric Shown/Parts (ordered
    // comma-separated part keys, or "custom" with a <metric>Format template)
    // — see main.xml. The reorderable list below is the single source of
    // truth in this dialog: any edit rewrites the keys via saveMetrics();
    // external changes (Defaults) rebuild it.
    property string cfg_metricOrder
    property bool cfg_ramShown
    property bool cfg_diskShown
    property bool cfg_cpuShown
    property bool cfg_gpuShown
    property string cfg_ramParts
    property string cfg_diskParts
    property string cfg_cpuParts
    property string cfg_gpuParts
    property string cfg_ramFormat
    property string cfg_diskFormat
    property string cfg_cpuFormat
    property string cfg_gpuFormat
    property int cfg_labelStyle

    property bool syncingMetrics: false

    function saveMetrics() {
        syncingMetrics = true;
        const order = [];
        for (let i = 0; i < metricModel.count; i++) {
            const m = metricModel.get(i);
            order.push(m.key);
            page["cfg_" + m.key + "Shown"] = m.shown;
            page["cfg_" + m.key + "Parts"] = m.parts;
            page["cfg_" + m.key + "Format"] = m.format;
        }
        cfg_metricOrder = order.join(",");
        syncingMetrics = false;
    }

    function rebuildMetricModel() {
        if (syncingMetrics) {
            return;
        }
        const meta = {
            ram: { label: i18n("RAM"), thermal: false, shown: cfg_ramShown, parts: cfg_ramParts, format: cfg_ramFormat },
            disk: { label: i18n("Disk"), thermal: false, shown: cfg_diskShown, parts: cfg_diskParts, format: cfg_diskFormat },
            cpu: { label: i18n("CPU"), thermal: true, shown: cfg_cpuShown, parts: cfg_cpuParts, format: cfg_cpuFormat },
            gpu: { label: i18n("GPU"), thermal: true, shown: cfg_gpuShown, parts: cfg_gpuParts, format: cfg_gpuFormat }
        };
        metricModel.clear();
        cfg_metricOrder.split(",").map(k => k.trim()).forEach(k => {
            if (meta[k] !== undefined) {
                metricModel.append({ key: k, label: meta[k].label, thermal: meta[k].thermal, shown: meta[k].shown, parts: meta[k].parts, format: meta[k].format });
            }
        });
    }

    onCfg_metricOrderChanged: rebuildMetricModel()
    onCfg_ramShownChanged: rebuildMetricModel()
    onCfg_diskShownChanged: rebuildMetricModel()
    onCfg_cpuShownChanged: rebuildMetricModel()
    onCfg_gpuShownChanged: rebuildMetricModel()
    onCfg_ramPartsChanged: rebuildMetricModel()
    onCfg_diskPartsChanged: rebuildMetricModel()
    onCfg_cpuPartsChanged: rebuildMetricModel()
    onCfg_gpuPartsChanged: rebuildMetricModel()
    onCfg_ramFormatChanged: rebuildMetricModel()
    onCfg_diskFormatChanged: rebuildMetricModel()
    onCfg_cpuFormatChanged: rebuildMetricModel()
    onCfg_gpuFormatChanged: rebuildMetricModel()
    Component.onCompleted: rebuildMetricModel()

    // Part choices: value is the ordered parts string stored in config, so
    // "which values" and "in what order" are one intuitive pick. "custom"
    // switches the metric to its free-form {variable} template.
    readonly property var capacityPartChoices: [
        { text: i18n("Usage %"), value: "usage" },
        { text: i18n("Used amount"), value: "abs" },
        { text: i18n("Usage % + used amount"), value: "usage,abs" },
        { text: i18n("Used amount + usage %"), value: "abs,usage" },
        { text: i18n("Custom…"), value: "custom" }
    ]
    readonly property var thermalPartChoices: [
        { text: i18n("Usage %"), value: "usage" },
        { text: i18n("Temperature"), value: "temp" },
        { text: i18n("Usage % + temperature"), value: "usage,temp" },
        { text: i18n("Temperature + usage %"), value: "temp,usage" },
        { text: i18n("Custom…"), value: "custom" }
    ]

    // Token + what it maps to, per metric — rendered as click-to-insert
    // chips under the custom format field.
    function variableDefs(key) {
        if (key === "cpu") {
            return [
                { token: "{usage}", desc: i18n("usage %") },
                { token: "{temp}", desc: i18n("hottest core") },
                { token: "{tempavg}", desc: i18n("core average") }
            ];
        }
        if (key === "gpu") {
            return [
                { token: "{usage}", desc: i18n("usage %") },
                { token: "{temp}", desc: i18n("temperature") },
                { token: "{peak}", desc: i18n("10-min peak") },
                { token: "{vram}", desc: i18n("VRAM used") },
                { token: "{vramtotal}", desc: i18n("VRAM total") },
                { token: "{power}", desc: i18n("power draw") }
            ];
        }
        return [
            { token: "{usage}", desc: i18n("used %") },
            { token: "{used}", desc: i18n("used") },
            { token: "{free}", desc: i18n("free") },
            { token: "{total}", desc: i18n("total") }
        ];
    }

    onCfg_labelStyleChanged: labelStyleCombo.currentIndex = labelStyleCombo.indexOfValue(cfg_labelStyle)

    property string cfg_fontFamily
    property int cfg_fontSize

    onCfg_fontFamilyChanged: fontFamilyCombo.currentIndex =
        cfg_fontFamily === "" ? 0 : Math.max(0, fontFamilyCombo.find(cfg_fontFamily))
    onCfg_fontSizeChanged: syncFontSizeCombo()

    // The size combo is editable: presets fill the popup, but any number can
    // be typed. 0 / non-numeric text means "Theme default".
    function syncFontSizeCombo() {
        if (cfg_fontSize === 0) {
            fontSizeCombo.currentIndex = 0;
            return;
        }
        const i = fontSizeCombo.find(String(cfg_fontSize));
        if (i >= 0) {
            fontSizeCombo.currentIndex = i;
        } else {
            fontSizeCombo.currentIndex = -1;
            fontSizeCombo.editText = String(cfg_fontSize);
        }
    }

    // Editable width combo, same pattern as font size: presets in the
    // popup, any number typable; 0 / non-numeric = fit content.
    property int cfg_valueWidth
    onCfg_valueWidthChanged: syncValueWidthCombo()

    function syncValueWidthCombo() {
        if (cfg_valueWidth === 0) {
            valueWidthCombo.currentIndex = 0;
            return;
        }
        const i = valueWidthCombo.find(String(cfg_valueWidth));
        if (i >= 0) {
            valueWidthCombo.currentIndex = i;
        } else {
            valueWidthCombo.currentIndex = -1;
            valueWidthCombo.editText = String(cfg_valueWidth);
        }
    }

    property alias cfg_ramLabel: ramLabelField.text
    property alias cfg_diskLabel: diskLabelField.text
    property alias cfg_cpuLabel: cpuLabelField.text
    property alias cfg_gpuLabel: gpuLabelField.text
    property alias cfg_ramIcon: ramIconField.text
    property alias cfg_diskIcon: diskIconField.text
    property alias cfg_cpuIcon: cpuIconField.text
    property alias cfg_gpuIcon: gpuIconField.text
    property alias cfg_showSeparators: showSeparatorsCheck.checked
    property alias cfg_valueGap: valueGapSpin.value
    property alias cfg_groupGap: groupGapSpin.value
    property alias cfg_customTextColor: textColorRow.custom
    property alias cfg_customLabelColor: labelColorRow.custom
    property alias cfg_customSeparatorColor: separatorColorRow.custom
    property alias cfg_customWarningColor: warningColorRow.custom
    property alias cfg_customCriticalColor: criticalColorRow.custom
    property alias cfg_textColor: textColorRow.stored
    property alias cfg_labelColor: labelColorRow.stored
    property alias cfg_separatorColor: separatorColorRow.stored
    property alias cfg_warningColor: warningColorRow.stored
    property alias cfg_criticalColor: criticalColorRow.stored

    // Reset every Appearance option to its main.xml default (the dialog
    // injects the defaults as cfg_<key>Default).
    function restoreDefaults() {
        cfg_metricOrder = cfg_metricOrderDefault;
        cfg_ramShown = cfg_ramShownDefault;
        cfg_diskShown = cfg_diskShownDefault;
        cfg_cpuShown = cfg_cpuShownDefault;
        cfg_gpuShown = cfg_gpuShownDefault;
        cfg_ramParts = cfg_ramPartsDefault;
        cfg_diskParts = cfg_diskPartsDefault;
        cfg_cpuParts = cfg_cpuPartsDefault;
        cfg_gpuParts = cfg_gpuPartsDefault;
        cfg_ramFormat = cfg_ramFormatDefault;
        cfg_diskFormat = cfg_diskFormatDefault;
        cfg_cpuFormat = cfg_cpuFormatDefault;
        cfg_gpuFormat = cfg_gpuFormatDefault;
        cfg_labelStyle = cfg_labelStyleDefault;
        cfg_ramLabel = cfg_ramLabelDefault;
        cfg_diskLabel = cfg_diskLabelDefault;
        cfg_cpuLabel = cfg_cpuLabelDefault;
        cfg_gpuLabel = cfg_gpuLabelDefault;
        cfg_ramIcon = cfg_ramIconDefault;
        cfg_diskIcon = cfg_diskIconDefault;
        cfg_cpuIcon = cfg_cpuIconDefault;
        cfg_gpuIcon = cfg_gpuIconDefault;
        cfg_fontFamily = cfg_fontFamilyDefault;
        cfg_fontSize = cfg_fontSizeDefault;
        cfg_valueWidth = cfg_valueWidthDefault;
        cfg_valueGap = cfg_valueGapDefault;
        cfg_groupGap = cfg_groupGapDefault;
        cfg_showSeparators = cfg_showSeparatorsDefault;
        cfg_customTextColor = cfg_customTextColorDefault;
        cfg_customLabelColor = cfg_customLabelColorDefault;
        cfg_customSeparatorColor = cfg_customSeparatorColorDefault;
        cfg_customWarningColor = cfg_customWarningColorDefault;
        cfg_customCriticalColor = cfg_customCriticalColorDefault;
        cfg_textColor = cfg_textColorDefault;
        cfg_labelColor = cfg_labelColorDefault;
        cfg_separatorColor = cfg_separatorColorDefault;
        cfg_warningColor = cfg_warningColorDefault;
        cfg_criticalColor = cfg_criticalColorDefault;
    }

    component DisplayCombo : QQC2.ComboBox {
        textRole: "text"
        valueRole: "value"
    }

    component FieldLabel : QQC2.Label {
        Layout.alignment: Qt.AlignRight
    }

    component SectionLabel : QQC2.Label {
        Layout.columnSpan: 2
        Layout.topMargin: Kirigami.Units.largeSpacing
        font.bold: true
    }

    // Metric label text, editable in text-label mode
    component LabelField : QQC2.TextField {
        enabled: page.cfg_labelStyle === 0
    }

    // One color: the button always shows the effective color — the theme's
    // until the user picks one (which flips `custom` on). The revert button
    // returns it to following the theme. `accepted` fires only on a real
    // user pick, so programmatic syncs can't accidentally set the flag.
    component ColorRow : RowLayout {
        id: colorRow

        property bool custom
        property string stored
        property color themeColor

        spacing: Kirigami.Units.smallSpacing

        function syncColor() {
            button.color = custom ? stored : themeColor;
        }
        onCustomChanged: syncColor()
        onStoredChanged: syncColor()
        onThemeColorChanged: syncColor()
        Component.onCompleted: syncColor()

        KQuickControls.ColorButton {
            id: button
            onAccepted: acceptedColor => {
                colorRow.stored = String(acceptedColor);
                colorRow.custom = true;
            }
        }

        QQC2.ToolButton {
            icon.name: "edit-undo"
            visible: colorRow.custom
            text: i18n("Follow the theme again")
            display: QQC2.ToolButton.IconOnly
            QQC2.ToolTip.text: text
            QQC2.ToolTip.visible: hovered
            onClicked: colorRow.custom = false
        }
    }

    // Icon chooser: the button opens KDE's icon dialog (theme icons with
    // search, plus Browse… for arbitrary image files like PNGs); the text
    // field allows typing a name or path directly. Both write to `text`.
    component IconField : RowLayout {
        property alias text: field.text
        enabled: page.cfg_labelStyle === 1
        spacing: Kirigami.Units.smallSpacing

        QQC2.Button {
            icon.name: field.text
            text: i18n("Choose…")
            onClicked: dialog.open()

            KIconThemes.IconDialog {
                id: dialog
                onIconNameChanged: field.text = iconName
            }
        }
        QQC2.TextField {
            id: field
        }
    }

    // --- Live preview data ---------------------------------------------
    // The dialog has no sensor subscriptions, so the preview uses plausible
    // sample values run through the user's actual configuration: order,
    // visibility, parts, custom formats, labels/icons, fonts and colors.
    function sampleVars(key) {
        if (key === "cpu") {
            return { usage: "38%", temp: "61°", tempavg: "54°" };
        }
        if (key === "gpu") {
            return { usage: "24%", temp: "58°", peak: "72°", vram: "3.2 GiB", vramtotal: "16.0 GiB", power: "87 W" };
        }
        if (key === "disk") {
            return { usage: "67%", used: "1.2 TiB", free: "610 GiB", total: "1.8 TiB" };
        }
        return { usage: "42%", used: "13.4 GiB", free: "18.2 GiB", total: "31.6 GiB" };
    }

    function samplePart(key, part) {
        const vars = sampleVars(key);
        if (part === "custom") {
            const tpl = key === "ram" ? cfg_ramFormat
                      : key === "disk" ? cfg_diskFormat
                      : key === "cpu" ? cfg_cpuFormat
                      : cfg_gpuFormat;
            return tpl.replace(/\{(\w+)\}/g, (match, name) => vars[name] !== undefined ? vars[name] : match);
        }
        return part === "temp" ? vars.temp : part === "abs" ? vars.used : vars.usage;
    }

    function previewLabel(key) {
        return key === "ram" ? cfg_ramLabel
             : key === "disk" ? cfg_diskLabel
             : key === "cpu" ? cfg_cpuLabel
             : cfg_gpuLabel;
    }

    function previewIcon(key) {
        return key === "ram" ? cfg_ramIcon
             : key === "disk" ? cfg_diskIcon
             : key === "cpu" ? cfg_cpuIcon
             : cfg_gpuIcon;
    }

    readonly property var previewMetrics: {
        const shown = { ram: cfg_ramShown, disk: cfg_diskShown, cpu: cfg_cpuShown, gpu: cfg_gpuShown };
        const parts = { ram: cfg_ramParts, disk: cfg_diskParts, cpu: cfg_cpuParts, gpu: cfg_gpuParts };
        return cfg_metricOrder.split(",").map(k => k.trim())
            .filter(k => shown[k] !== undefined && shown[k] && parts[k] !== "")
            .map(k => ({ key: k, parts: parts[k].split(",") }));
    }

    readonly property color previewValueColor: cfg_customTextColor ? cfg_textColor : Kirigami.Theme.textColor
    readonly property color previewLabelColor: cfg_customLabelColor ? cfg_labelColor : Kirigami.Theme.disabledTextColor
    readonly property color previewSepColor: cfg_customSeparatorColor ? cfg_separatorColor : Kirigami.Theme.disabledTextColor
    readonly property string previewFontFamily: cfg_fontFamily !== "" ? cfg_fontFamily : Kirigami.Theme.defaultFont.family
    readonly property real previewPointSize: cfg_fontSize > 0 ? cfg_fontSize : Kirigami.Theme.defaultFont.pointSize
    readonly property real previewLabelPointSize: previewPointSize
        * Kirigami.Theme.smallFont.pointSize / Kirigami.Theme.defaultFont.pointSize

    // Wide content (the metrics list) lives outside the FormLayout so it
    // spans the full page width instead of being squeezed into the form's
    // field column with a dead label column on the left.
    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            Kirigami.Heading {
                level: 4
                text: i18n("Preview")
                Layout.fillWidth: true
            }

            QQC2.Button {
                icon.name: "document-revert"
                text: i18n("Restore defaults")
                onClicked: page.restoreDefaults()
            }
        }

        QQC2.Frame {
            Layout.fillWidth: true

            RowLayout {
                id: previewRow
                anchors.centerIn: parent
                spacing: page.cfg_groupGap

                Repeater {
                    model: page.previewMetrics

                    delegate: RowLayout {
                        id: previewGroup

                        required property var modelData
                        required property int index

                        spacing: page.cfg_groupGap

                        QQC2.Label {
                            visible: previewGroup.index > 0 && page.cfg_showSeparators
                            text: "|"
                            opacity: 0.5
                            color: page.previewSepColor
                            font.family: page.previewFontFamily
                            font.pointSize: page.previewPointSize
                        }

                        RowLayout {
                            spacing: page.cfg_valueGap

                            Kirigami.Icon {
                                visible: page.cfg_labelStyle === 1
                                source: page.previewIcon(previewGroup.modelData.key)
                                color: page.previewLabelColor
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            }

                            QQC2.Label {
                                visible: page.cfg_labelStyle === 0
                                text: page.previewLabel(previewGroup.modelData.key)
                                color: page.previewLabelColor
                                font.family: page.previewFontFamily
                                font.pointSize: page.previewLabelPointSize
                            }

                            Repeater {
                                model: previewGroup.modelData.parts

                                delegate: QQC2.Label {
                                    required property string modelData
                                    text: page.samplePart(previewGroup.modelData.key, modelData)
                                    color: page.previewValueColor
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: modelData !== "custom" && page.cfg_valueWidth > 0
                                        ? page.cfg_valueWidth
                                        : -1
                                    font.family: page.previewFontFamily
                                    font.pointSize: page.previewPointSize
                                    font.features: ({ "tnum": 1 })
                                }
                            }
                        }
                    }
                }

                QQC2.Label {
                    visible: page.previewMetrics.length === 0
                    text: i18n("Nothing to show — enable a metric below")
                    opacity: 0.6
                }
            }

            // Frame needs an implicit height since its content is anchored
            implicitHeight: previewRow.implicitHeight + Kirigami.Units.largeSpacing * 2
        }

        Kirigami.Heading {
            level: 4
            text: i18n("Metrics")
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Drag to reorder, check to show, and pick what each metric displays. Custom accepts free text with {variables}.")
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
        }

        ListView {
            id: metricList

            Layout.fillWidth: true
            implicitHeight: contentHeight
            interactive: false
            clip: true

            model: ListModel { id: metricModel }

            delegate: Item {
                id: metricRow

                required property int index
                required property string key
                required property string label
                required property bool thermal
                required property bool shown
                required property string parts
                required property string format

                width: metricList.width
                implicitHeight: rowColumn.implicitHeight + Kirigami.Units.smallSpacing

                ColumnLayout {
                    id: rowColumn
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.ListItemDragHandle {
                            listItem: metricRow
                            listView: metricList
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.fillHeight: true
                            onMoveRequested: (oldIndex, newIndex) => metricModel.move(oldIndex, newIndex, 1)
                            onDropped: page.saveMetrics()
                        }

                        QQC2.CheckBox {
                            text: metricRow.label
                            checked: metricRow.shown
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                            onToggled: {
                                metricModel.setProperty(metricRow.index, "shown", checked);
                                page.saveMetrics();
                            }
                        }

                        DisplayCombo {
                            Layout.fillWidth: true
                            enabled: metricRow.shown
                            model: metricRow.thermal ? page.thermalPartChoices : page.capacityPartChoices
                            onActivated: {
                                metricModel.setProperty(metricRow.index, "parts", currentValue);
                                page.saveMetrics();
                            }
                            Component.onCompleted: currentIndex = indexOfValue(metricRow.parts)
                        }
                    }

                    ColumnLayout {
                        visible: metricRow.parts === "custom"
                        Layout.leftMargin: Kirigami.Units.gridUnit * 2
                        spacing: Kirigami.Units.smallSpacing / 2

                        QQC2.TextField {
                            id: formatField
                            Layout.fillWidth: true
                            text: metricRow.format
                            enabled: metricRow.shown
                            onEditingFinished: {
                                metricModel.setProperty(metricRow.index, "format", text);
                                page.saveMetrics();
                            }
                        }

                        QQC2.Label {
                            text: i18n("Click a value to insert it:")
                            font: Kirigami.Theme.smallFont
                            opacity: 0.7
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Repeater {
                                model: page.variableDefs(metricRow.key)

                                delegate: QQC2.Button {
                                    id: chip

                                    required property var modelData

                                    enabled: metricRow.shown
                                    // Don't steal focus — the field keeps its
                                    // cursor position for the insertion.
                                    focusPolicy: Qt.NoFocus

                                    // The style's button background doesn't size
                                    // itself from a custom contentItem, so pin the
                                    // implicit size to content + padding explicitly.
                                    padding: Kirigami.Units.smallSpacing
                                    leftPadding: Kirigami.Units.smallSpacing * 2
                                    rightPadding: Kirigami.Units.smallSpacing * 2
                                    implicitWidth: chipRow.implicitWidth + leftPadding + rightPadding
                                    implicitHeight: chipRow.implicitHeight + topPadding + bottomPadding

                                    onClicked: {
                                        const pos = formatField.cursorPosition;
                                        formatField.text = formatField.text.slice(0, pos)
                                            + chip.modelData.token
                                            + formatField.text.slice(pos);
                                        formatField.cursorPosition = pos + chip.modelData.token.length;
                                        metricModel.setProperty(metricRow.index, "format", formatField.text);
                                        page.saveMetrics();
                                    }

                                    contentItem: RowLayout {
                                        id: chipRow
                                        spacing: Kirigami.Units.smallSpacing

                                        QQC2.Label {
                                            text: chip.modelData.token
                                            font.family: "monospace"
                                            font.bold: true
                                        }
                                        QQC2.Label {
                                            text: chip.modelData.desc
                                            font: Kirigami.Theme.smallFont
                                            opacity: 0.7
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Plain two-column grid instead of Kirigami.FormLayout: the form hugs
        // the left edge rather than centering in the page (which left a large
        // dead zone on the left).
        GridLayout {
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing
            Layout.alignment: Qt.AlignLeft

            SectionLabel { text: i18n("Labels") }

            FieldLabel { text: i18n("Label style:") }
            DisplayCombo {
                id: labelStyleCombo
                model: [
                    { text: i18n("Text (RAM, DISK, …)"), value: 0 },
                    { text: i18n("Icons"), value: 1 }
                ]
                onActivated: page.cfg_labelStyle = currentValue
                Component.onCompleted: currentIndex = indexOfValue(page.cfg_labelStyle)
            }

            FieldLabel { text: i18n("RAM label:") }
            LabelField { id: ramLabelField }
            FieldLabel { text: i18n("Disk label:") }
            LabelField { id: diskLabelField }
            FieldLabel { text: i18n("CPU label:") }
            LabelField { id: cpuLabelField }
            FieldLabel { text: i18n("GPU label:") }
            LabelField { id: gpuLabelField }

            FieldLabel { text: i18n("RAM icon:") }
            IconField { id: ramIconField }
            FieldLabel { text: i18n("Disk icon:") }
            IconField { id: diskIconField }
            FieldLabel { text: i18n("CPU icon:") }
            IconField { id: cpuIconField }
            FieldLabel { text: i18n("GPU icon:") }
            IconField { id: gpuIconField }

            QQC2.Label {
                Layout.columnSpan: 2
                Layout.maximumWidth: Kirigami.Units.gridUnit * 25
                text: i18n("Choose… browses theme icons and, via its Browse button, arbitrary image files (PNG/SVG). The field also accepts a typed icon name or file path.")
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }

            SectionLabel { text: i18n("Layout") }

            FieldLabel { text: i18n("Font:") }
            QQC2.ComboBox {
                id: fontFamilyCombo
                Layout.minimumWidth: Kirigami.Units.gridUnit * 14

                // Qt.fontFamilies() scans the whole font database (slow), so the
                // model starts with just the current choice and the full list is
                // built on first open. Plain-text entries: per-item typeface
                // previews make the popup janky with hundreds of fonts — the
                // preview label below shows the selected font instead.
                property bool populated: false
                model: [i18n("Theme default")].concat(page.cfg_fontFamily !== "" ? [page.cfg_fontFamily] : [])
                currentIndex: page.cfg_fontFamily === "" ? 0 : 1

                function populate() {
                    if (populated) {
                        return;
                    }
                    populated = true;
                    const current = page.cfg_fontFamily;
                    model = [i18n("Theme default")].concat(Qt.fontFamilies());
                    currentIndex = current === "" ? 0 : Math.max(0, find(current));
                }
                onPressedChanged: if (pressed) populate()
                onActivated: page.cfg_fontFamily = currentIndex === 0 ? "" : currentText
            }

            FieldLabel { text: i18n("Font size (pt):") }
            QQC2.ComboBox {
                id: fontSizeCombo
                editable: true
                model: [i18n("Theme default"), "8", "9", "10", "11", "12", "14", "16", "18", "20", "22", "24", "28", "32"]

                function commit(text, index) {
                    const n = parseInt(text);
                    page.cfg_fontSize = (index === 0 || isNaN(n) || n <= 0) ? 0 : Math.min(n, 96);
                }
                onActivated: index => commit(textAt(index), index)
                onAccepted: commit(editText, find(editText) === 0 ? 0 : -1)
                Component.onCompleted: page.syncFontSizeCombo()
            }

            FieldLabel { text: i18n("Value width (px):") }
            QQC2.ComboBox {
                id: valueWidthCombo
                editable: true
                model: [i18n("Fit content"), "30", "40", "50", "60", "80", "100"]

                function commit(text, index) {
                    const n = parseInt(text);
                    page.cfg_valueWidth = (index === 0 || isNaN(n) || n <= 0) ? 0 : Math.min(n, 400);
                }
                onActivated: index => commit(textAt(index), index)
                onAccepted: commit(editText, find(editText) === 0 ? 0 : -1)
                Component.onCompleted: page.syncValueWidthCombo()
            }

            FieldLabel { text: i18n("Gap inside a group (px):") }
            QQC2.SpinBox {
                id: valueGapSpin
                from: 0
                to: 32
            }

            FieldLabel { text: i18n("Gap between groups (px):") }
            QQC2.SpinBox {
                id: groupGapSpin
                from: 0
                to: 48
            }

            FieldLabel { text: i18n("Separators:") }
            QQC2.CheckBox {
                id: showSeparatorsCheck
                text: i18n("Show | between groups")
            }

            SectionLabel { text: i18n("Colors") }

            QQC2.Label {
                Layout.columnSpan: 2
                text: i18n("Colors follow the system theme until you pick one; the undo button next to a picked color reverts it to the theme.")
                Layout.maximumWidth: Kirigami.Units.gridUnit * 25
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }

            FieldLabel { text: i18n("Values:") }
            ColorRow { id: textColorRow; themeColor: Kirigami.Theme.textColor }
            FieldLabel { text: i18n("Labels:") }
            ColorRow { id: labelColorRow; themeColor: Kirigami.Theme.disabledTextColor }
            FieldLabel { text: i18n("Separators:") }
            ColorRow { id: separatorColorRow; themeColor: Kirigami.Theme.disabledTextColor; enabled: showSeparatorsCheck.checked }
            FieldLabel { text: i18n("Warning (amber):") }
            ColorRow { id: warningColorRow; themeColor: Kirigami.Theme.neutralTextColor }
            FieldLabel { text: i18n("Critical (red):") }
            ColorRow { id: criticalColorRow; themeColor: Kirigami.Theme.negativeTextColor }
        }
    }
}
