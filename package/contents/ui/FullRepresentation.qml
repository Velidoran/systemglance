import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as P5Support

ColumnLayout {
    id: root

    Layout.minimumWidth: Kirigami.Units.gridUnit * 12
    Layout.minimumHeight: Kirigami.Units.gridUnit * 20
    Layout.preferredWidth: Kirigami.Units.gridUnit * 15
    Layout.preferredHeight: Kirigami.Units.gridUnit * 28
    spacing: Kirigami.Units.smallSpacing

    // ---------------------------------------------------------------- state
    // Bound to the applet's expanded state by main.qml, so the shell commands
    // only run while the popup is open.
    property bool expanded: true

    property var netIfaces: []
    property var gwMap: ({})
    property var ssidMap: ({})
    property string publicIp: ""
    property var diskRows: []

    readonly property var combinedNet: {
        var out = [];
        for (var i = 0; i < netIfaces.length; i++) {
            var e = netIfaces[i];
            out.push({
                name: e.name,
                state: e.state,
                v4: e.v4,
                v6: e.v6,
                gw: gwMap[e.name] || "",
                ssid: ssidMap[e.name] || ""
            });
        }
        return out;
    }

    readonly property var sshList: parseHosts(Plasmoid.configuration.sshHosts)

    // ---------------------------------------------------------------- sensors
    Sensors.Sensor { id: hostnameSensor; sensorId: "os/system/hostname" }
    Sensors.Sensor { id: kernelSensor; sensorId: "os/kernel/prettyName" }

    Sensors.Sensor { id: cpuSensor; sensorId: "cpu/all/usage"; updateRateLimit: 2000 }
    Sensors.Sensor { id: memUsed; sensorId: "memory/physical/used" }
    Sensors.Sensor { id: memTotal; sensorId: "memory/physical/total" }
    Sensors.Sensor { id: memUsedPct; sensorId: "memory/physical/usedPercent" }
    Sensors.Sensor { id: swapUsed; sensorId: "memory/swap/used" }
    Sensors.Sensor { id: swapTotal; sensorId: "memory/swap/total" }
    Sensors.Sensor { id: swapUsedPct; sensorId: "memory/swap/usedPercent" }

    Sensors.Sensor { id: netDown; sensorId: "network/all/download"; updateRateLimit: 2000 }
    Sensors.Sensor { id: netUp; sensorId: "network/all/upload"; updateRateLimit: 2000 }
    Sensors.Sensor { id: diskRead; sensorId: "disk/all/read"; updateRateLimit: 2000 }
    Sensors.Sensor { id: diskWrite; sensorId: "disk/all/write"; updateRateLimit: 2000 }

    // ---------------------------------------------------------------- exec engine
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function (sourceName, data) {
            var stdout = (data && data["stdout"]) ? data["stdout"] : "";
            try {
                if (sourceName === "ip -j addr")
                    root.parseAddr(stdout);
                else if (sourceName === "ip -j route")
                    root.parseRoute(stdout);
                else if (sourceName.indexOf("nmcli ") === 0)
                    root.parseWifi(stdout);
                else if (sourceName.indexOf("df ") === 0)
                    root.parseDf(stdout);
                else if (sourceName.indexOf("curl ") === 0)
                    root.publicIp = root.parsePublicIp(stdout);
            } catch (e) {
                console.warn("System Glance: failed to parse", sourceName, "-", e);
            }
            disconnectSource(sourceName);
        }
    }

    function exec(cmd) {
        executable.connectSource(cmd);
    }

    // Fires straight away whenever the popup opens, then every interval.
    Timer {
        interval: Math.max(1, Plasmoid.configuration.refreshInterval) * 1000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshNow()
    }

    function refreshNow() {
        exec("ip -j addr");
        exec("ip -j route");
        // --rescan no: read NetworkManager's cached results. Without it nmcli
        // starts a Wi-Fi scan whenever its list is over 30 s old.
        exec("nmcli -t -f device,active,ssid dev wifi list --rescan no");
        exec(dfCommand());
    }

    // ---------------------------------------------------------------- helpers
    function cleanLines(raw) {
        var out = [];
        var lines = String(raw || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].trim();
            if (l && l.indexOf("#") !== 0)
                out.push(l);
        }
        return out;
    }

    function shellQuote(s) {
        s = String(s);
        // Mount paths almost always need no quoting; pass those through bare so
        // this works whether the executable engine uses a shell or arg-splitting.
        if (/^[A-Za-z0-9_./:@%+-]+$/.test(s))
            return s;
        return '"' + s.replace(/(["\\$`])/g, "\\$1") + '"';
    }

    function fmtBytes(b) {
        b = Number(b) || 0;
        var u = ["B", "KiB", "MiB", "GiB", "TiB"];
        var i = 0;
        while (b >= 1024 && i < u.length - 1) {
            b /= 1024;
            i++;
        }
        return (i === 0 ? b.toFixed(0) : b.toFixed(1)) + " " + u[i];
    }

    function dfCommand() {
        var mounts = cleanLines(Plasmoid.configuration.diskMounts);
        var base = "df -B1 --output=target,size,used,avail,pcent";
        if (mounts.length > 0)
            return base + " " + mounts.map(shellQuote).join(" ");
        return base + " -x tmpfs -x devtmpfs -x squashfs -x efivarfs -x overlay";
    }

    function parseHosts(raw) {
        var out = [];
        var lines = cleanLines(raw);
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("|");
            var label = (parts[0] || "").trim();
            var target = (parts[1] || "").trim();
            var port = (parts[2] || "").trim();
            if (!target) {
                target = label;
            }
            if (!label) {
                label = target;
            }
            if (!target)
                continue;
            out.push({ label: label, target: target, port: port });
        }
        return out;
    }

    function sshCommand(entry) {
        var term = String(Plasmoid.configuration.terminalCommand || "konsole -e").trim();
        if (Plasmoid.configuration.keepTerminalOpen && term.indexOf("konsole") === 0)
            term = term.replace(/^konsole/, "konsole --hold");
        var portArg = entry.port ? (" -p " + entry.port) : "";
        return term + " ssh" + portArg + " " + entry.target;
    }

    function parseAddr(stdout) {
        var arr = JSON.parse(stdout || "[]");
        var list = [];
        for (var i = 0; i < arr.length; i++) {
            var it = arr[i];
            if (it.link_type === "loopback" || !it.addr_info)
                continue;
            var v4 = [], v6 = [];
            for (var j = 0; j < it.addr_info.length; j++) {
                var a = it.addr_info[j];
                if (a.family === "inet")
                    v4.push(a.local + "/" + a.prefixlen);
                else if (a.family === "inet6" && a.scope === "global")
                    v6.push(a.local + "/" + a.prefixlen);
            }
            if (v4.length === 0 && v6.length === 0)
                continue;
            list.push({ name: it.ifname, state: it.operstate || "", v4: v4, v6: v6 });
        }
        netIfaces = list;
    }

    function parseRoute(stdout) {
        var routes = JSON.parse(stdout || "[]");
        var map = {};
        for (var i = 0; i < routes.length; i++) {
            var r = routes[i];
            if (r.dst === "default" && r.gateway)
                map[r.dev] = r.gateway;
        }
        gwMap = map;
    }

    function parseWifi(stdout) {
        // lines: "device:active:ssid" from `nmcli -t`. device and active never
        // contain ':'; the ssid is whatever is left after the second ':', with
        // ':' and '\' escaped by a backslash.
        var map = {};
        var lines = String(stdout || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            var m = lines[i].match(/^([^:]*):([^:]*):(.*)$/);
            if (!m)
                continue;
            var dev = m[1];
            var active = m[2];
            var ssid = m[3].replace(/\\(.)/g, "$1");
            if (active === "yes" && ssid)
                map[dev] = ssid;
        }
        ssidMap = map;
    }

    function parseDf(stdout) {
        var rows = [];
        var lines = String(stdout || "").split("\n");
        for (var i = 1; i < lines.length; i++) {
            // "target size used avail pcent", matched from the right so mount
            // points with spaces in them (e.g. "/media/me/My Passport") survive.
            var m = lines[i].match(/^\s*(.*\S)\s+(\d+)\s+(\d+)\s+\d+\s+\S+\s*$/);
            if (!m)
                continue;
            var size = Number(m[2]);
            var used = Number(m[3]);
            if (!(size > 0))
                continue;
            rows.push({
                mount: m[1],
                size: size,
                used: used,
                fraction: used / size
            });
        }
        diskRows = rows;
    }

    function parsePublicIp(stdout) {
        // api.ipify.org replies with the bare address. Anything else, such as
        // an error page from a proxy, is not shown.
        var ip = String(stdout || "").trim();
        return /^[0-9A-Fa-f:.]{2,45}$/.test(ip) ? ip : i18n("(no answer)");
    }

    function copyText(t) {
        clip.text = String(t);
        clip.selectAll();
        clip.copy();
    }

    TextEdit {
        id: clip
        visible: false
        width: 0
        height: 0
    }

    // ---------------------------------------------------------------- header
    RowLayout {
        Layout.fillWidth: true
        Kirigami.Icon {
            source: "utilities-system-monitor"
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
        }
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Kirigami.Heading {
                level: 3
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: String(hostnameSensor.value || i18n("System Glance"))
            }
            QQC2.Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                opacity: 0.7
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                text: String(kernelSensor.value || "")
            }
        }
    }

    // ---------------------------------------------------------------- body
    QQC2.ScrollView {
        id: sv
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: sv.availableWidth
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Separator { Layout.fillWidth: true }

            StatBar {
                Layout.fillWidth: true
                caption: i18n("CPU")
                fraction: (cpuSensor.value || 0) / 100
                valueText: Math.round(cpuSensor.value || 0) + "%"
            }
            StatBar {
                Layout.fillWidth: true
                caption: i18n("RAM")
                fraction: (memUsedPct.value || 0) / 100
                valueText: fmtBytes(memUsed.value) + " / " + fmtBytes(memTotal.value)
            }
            StatBar {
                Layout.fillWidth: true
                visible: Plasmoid.configuration.showSwap && (swapTotal.value || 0) > 0
                caption: i18n("Swap")
                fraction: (swapUsedPct.value || 0) / 100
                valueText: fmtBytes(swapUsed.value) + " / " + fmtBytes(swapTotal.value)
            }

            Repeater {
                model: root.diskRows
                delegate: StatBar {
                    required property var modelData
                    Layout.fillWidth: true
                    caption: modelData.mount
                    fraction: modelData.fraction || 0
                    valueText: fmtBytes(modelData.used) + " / " + fmtBytes(modelData.size)
                    tooltip: i18n("%1 — %2% used", modelData.mount, Math.round((modelData.fraction || 0) * 100))
                }
            }
            QQC2.Label {
                visible: root.diskRows.length === 0
                opacity: 0.7
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                text: i18n("No filesystem data")
            }

            Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing }

            // Laid out to match the StatBar rows above: caption | plot | value.
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    text: i18n("Net")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    Layout.alignment: Qt.AlignVCenter
                    elide: Text.ElideRight
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }

                NetGraph {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
                    downValue: Number(netDown.value) || 0
                    upValue: Number(netUp.value) || 0

                    QQC2.ToolTip.visible: graphHover.hovered
                    QQC2.ToolTip.text: i18n("Last ~90 s · ↓ blue, ↑ green")
                    HoverHandler { id: graphHover }
                }

                ColumnLayout {
                    spacing: 0
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                    Layout.alignment: Qt.AlignVCenter
                    QQC2.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        text: i18n("↓ %1", netDown.formattedValue || "0 B/s")
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        text: i18n("↑ %1", netUp.formattedValue || "0 B/s")
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    opacity: 0.7
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    text: i18n("Disk  read %1   write %2",
                               diskRead.formattedValue || "0 B/s",
                               diskWrite.formattedValue || "0 B/s")
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing }
            QQC2.Label { text: i18n("Network"); font.bold: true; font.pointSize: Kirigami.Theme.smallFont.pointSize }

            Repeater {
                model: root.combinedNet
                delegate: ColumnLayout {
                    id: ifBlock
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label {
                            text: ifBlock.modelData.name
                            font.bold: true
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                        QQC2.Label {
                            text: ifBlock.modelData.ssid
                                  ? i18n("Wi-Fi: %1", ifBlock.modelData.ssid)
                                  : ifBlock.modelData.state
                            // whoever runs the network picks the SSID: never parse it as markup
                            textFormat: Text.PlainText
                            opacity: 0.7
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Repeater {
                        model: ifBlock.modelData.v4.concat(ifBlock.modelData.v6)
                        delegate: RowLayout {
                            required property string modelData
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.largeSpacing
                            QQC2.Label {
                                text: modelData
                                Layout.fillWidth: true
                                font.family: "monospace"
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                elide: Text.ElideRight
                            }
                            QQC2.ToolButton {
                                icon.name: "edit-copy"
                                display: QQC2.AbstractButton.IconOnly
                                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                QQC2.ToolTip.visible: hovered
                                QQC2.ToolTip.text: i18n("Copy address")
                                onClicked: root.copyText(String(modelData).split("/")[0])
                            }
                        }
                    }

                    QQC2.Label {
                        visible: ifBlock.modelData.gw !== ""
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        opacity: 0.7
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        text: i18n("gateway %1", ifBlock.modelData.gw)
                    }
                }
            }
            QQC2.Label {
                visible: root.combinedNet.length === 0
                opacity: 0.7
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                text: i18n("No active interfaces")
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing
                visible: Plasmoid.configuration.enablePublicIp
                QQC2.Label {
                    text: i18n("public")
                    opacity: 0.7
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.publicIp !== "" ? root.publicIp : "—"
                    font.family: "monospace"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    elide: Text.ElideRight
                }
                QQC2.ToolButton {
                    icon.name: "view-refresh"
                    display: QQC2.AbstractButton.IconOnly
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: i18n("Fetch public IP from api.ipify.org")
                    onClicked: root.exec("curl -s --max-time 8 https://api.ipify.org")
                }
                QQC2.ToolButton {
                    visible: root.publicIp !== ""
                    icon.name: "edit-copy"
                    display: QQC2.AbstractButton.IconOnly
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: i18n("Copy")
                    onClicked: root.copyText(root.publicIp)
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing }
            QQC2.Label { text: i18n("SSH"); font.bold: true; font.pointSize: Kirigami.Theme.smallFont.pointSize }

            Repeater {
                model: root.sshList
                delegate: QQC2.Button {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label
                    icon.name: "utilities-terminal"
                    onClicked: root.exec(root.sshCommand(modelData))
                }
            }
            QQC2.Label {
                visible: root.sshList.length === 0
                opacity: 0.7
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                text: i18n("Add hosts in this widget's settings")
            }
        }
    }

    // ---------------------------------------------------------------- footer
    Kirigami.Separator { Layout.fillWidth: true }
    RowLayout {
        Layout.fillWidth: true
        QQC2.Button {
            text: i18n("System Monitor")
            icon.name: "utilities-system-monitor"
            onClicked: root.exec("plasma-systemmonitor")
        }
        Item { Layout.fillWidth: true }
        QQC2.Button {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onClicked: root.refreshNow()
        }
    }
}
