import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_refreshInterval: refreshSpin.value
    property alias cfg_diskMounts: diskArea.text
    property alias cfg_showSwap: swapCheck.checked
    property alias cfg_terminalCommand: termField.text
    property alias cfg_keepTerminalOpen: holdCheck.checked
    property alias cfg_sshHosts: sshArea.text
    property alias cfg_enablePublicIp: pubIpCheck.checked

    QQC2.SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: i18n("Refresh interval (seconds):")
        from: 1
        to: 3600
        stepSize: 1
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.TextArea {
        id: diskArea
        Kirigami.FormData.label: i18n("Mount points:")
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
        wrapMode: TextEdit.NoWrap
    }
    QQC2.Label {
        text: i18n("One per line, e.g. / or /home. Leave empty to show all real filesystems.")
        font: Kirigami.Theme.smallFont
        opacity: 0.7
    }

    QQC2.CheckBox {
        id: swapCheck
        Kirigami.FormData.label: i18n("Swap:")
        text: i18n("Show swap usage")
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.TextField {
        id: termField
        Kirigami.FormData.label: i18n("Terminal command:")
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        placeholderText: "konsole -e"
    }
    QQC2.Label {
        text: i18n("Must accept a trailing command to run, e.g. \"konsole -e\" or \"x-terminal-emulator -e\".")
        font: Kirigami.Theme.smallFont
        opacity: 0.7
    }
    QQC2.CheckBox {
        id: holdCheck
        text: i18n("Keep the terminal open after the SSH session ends (konsole only)")
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.TextArea {
        id: sshArea
        Kirigami.FormData.label: i18n("SSH hosts:")
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredHeight: Kirigami.Units.gridUnit * 6
        wrapMode: TextEdit.NoWrap
        placeholderText: "home server | pi@192.168.1.20 | 22\nwork | me@work.example.com"
    }
    QQC2.Label {
        text: i18n("One host per line:  label | user@host | port   (port optional).")
        font: Kirigami.Theme.smallFont
        opacity: 0.7
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.CheckBox {
        id: pubIpCheck
        Kirigami.FormData.label: i18n("Public IP:")
        text: i18n("Allow fetching the public IP from api.ipify.org on demand")
    }
}
