import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Panel: icon only. All detail lives in the popup (fullRepresentation).
    Plasmoid.icon: "utilities-system-monitor"
    preferredRepresentation: compactRepresentation

    toolTipMainText: i18n("System Glance")
    toolTipSubText: i18n("Click for CPU, RAM, network, disk and SSH")

    compactRepresentation: MouseArea {
        id: iconArea
        hoverEnabled: true
        activeFocusOnTab: true
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        onClicked: root.expanded = !root.expanded
        Keys.onReturnPressed: root.expanded = !root.expanded
        Keys.onSpacePressed: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon || "utilities-system-monitor"
            active: iconArea.containsMouse
        }
    }

    fullRepresentation: FullRepresentation {
        expanded: root.expanded
    }
}
