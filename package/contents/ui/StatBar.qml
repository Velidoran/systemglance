import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// One row: caption on the left, a progress bar in the middle, a value on the right.
RowLayout {
    id: bar

    property string caption
    property real fraction: 0        // 0.0 .. 1.0
    property string valueText: ""
    property string tooltip: ""

    spacing: Kirigami.Units.smallSpacing

    QQC2.Label {
        text: bar.caption
        textFormat: Text.PlainText      // mount points can come from removable-drive labels
        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
        elide: Text.ElideRight
        font: Kirigami.Theme.smallFont
    }

    QQC2.ProgressBar {
        Layout.fillWidth: true
        from: 0
        to: 1
        value: Math.max(0, Math.min(1, bar.fraction))

        QQC2.ToolTip.visible: bar.tooltip !== "" && hover.hovered
        QQC2.ToolTip.text: bar.tooltip
        HoverHandler { id: hover }
    }

    QQC2.Label {
        text: bar.valueText
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
        Layout.maximumWidth: Kirigami.Units.gridUnit * 6
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        font: Kirigami.Theme.smallFont

        QQC2.ToolTip.visible: truncated && valHover.hovered
        QQC2.ToolTip.text: bar.valueText
        HoverHandler { id: valHover }
    }
}
