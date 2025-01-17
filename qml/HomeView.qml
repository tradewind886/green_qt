import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    signal openWallet(Wallet wallet)
    readonly property string url: 'https://blockstream.com/green/'
    readonly property var recentWallets: {
        const wallets = []
        // Force update when wallets are added/removed
        WalletManager.wallets
        for (const id of Settings.recentWallets) {
            const wallet = WalletManager.wallet(id)
            if (!wallet) continue
            if (wallet.deviceDetails?.type) continue
            if (wallet.network.key === 'testnet' && !Settings.enableTestnet) continue
            if (wallet.network.key === 'testnet-liquid' && !Settings.enableTestnet) continue
            wallets.push(wallet)
            if (wallets.length === 3) break
        }
        return wallets
    }

    AppUpdateController {
        id: app_update_controller
        Component.onCompleted: checkForUpdates()
    }

    AnalyticsView {
        name: 'Home'
        active: navigation.param.view === 'home'
    }

    id: self
    footer: StatusBar {
        contentItem: RowLayout {
            SessionBadge {
                session: HttpManager.session
            }
        }
    }
    topPadding: 24
    bottomPadding: 24
    contentItem: ColumnLayout {
        GPane {
            id: notification_panel
            Layout.rightMargin: 16
            Layout.fillWidth: true
            visible: app_update_controller.updateAvailable
            padding: constants.p3
            background: Rectangle {
                radius: 4
                color: 'white'
            }
            contentItem: RowLayout {
                Label {
                    text: qsTrId('There is a newer version of Green Desktop available')
                    color: 'black'
                }
                HSpacer {
                }
                Label {
                    text: qsTrId('Download %1').arg(app_update_controller.latestVersion)
                    font.bold: true
                    color: 'black'
                }
            }
            TapHandler {
                onTapped: Qt.openUrlExternally(constants.downloadUrl)
            }
        }
        spacing: constants.p4
        AlertView {
            alert: AnalyticsAlert {
                screen: 'Home'
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 210
            Layout.maximumHeight: 230
            spacing: 12
            ColumnLayout {
                Layout.fillHeight: true
                Label {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 16
                    text: qsTrId('id_recently_used_wallets')
                    font.pixelSize: 18
                    font.bold: true
                }
                GPane {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    padding: constants.p2
                    background: Rectangle {
                        radius: 16
                        color: constants.c800
                        Text {
                            visible: self.recentWallets.length === 0
                            text: qsTrId('id_looks_like_you_havent_used_a')
                            color: 'white'
                            anchors.centerIn: parent
                        }
                    }
                    contentItem: ColumnLayout {
                        spacing: 0
                        Repeater {
                            model: self.recentWallets
                            Button {
                                id: delegate
                                readonly property Wallet wallet: modelData
                                Layout.alignment: Qt.AlignTop
                                Layout.fillWidth: true
                                icon.source: UtilJS.iconFor(wallet)
                                icon.color: 'transparent'
                                flat: true
                                onClicked: self.openWallet(wallet)
                                background: Rectangle {
                                    visible: delegate.hovered
                                    radius: 8
                                    color: constants.c700
                                }
                                contentItem: RowLayout {
                                    spacing: 12
                                    Label {
                                        text: wallet.name
                                        elide: Label.ElideRight
                                        Layout.fillWidth: true
                                        Layout.maximumWidth: implicitWidth + 1
                                    }
                                    Loader {
                                        active: 'type' in wallet.deviceDetails
                                        visible: active
                                        sourceComponent: DeviceBadge {
                                            device: wallet.context?.device
                                            details: wallet.deviceDetails
                                        }
                                    }
                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        visible: wallet.context
                                        height: radius * 2
                                        width: radius * 2
                                        radius: 4
                                        color: constants.g500
                                    }
                                    HSpacer {
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Spacer {
            }
        }
        VSpacer {
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTrId('Copyright (©) 2023') + '<br/><br/>' +
                  qsTrId('id_version') + ' ' + Qt.application.version + '<br/><br/>' +
                  qsTrId('id_please_contribute_if_you_find') + ".<br/>" +
                  qsTrId('id_visit_s_for_further_information').arg(UtilJS.link(url)) + ".<br/><br/>" +
                  qsTrId('id_distributed_under_the_s_see').arg('GNU General Public License v3.0').arg(UtilJS.link('https://opensource.org/licenses/GPL-3.0'))
            textFormat: Text.RichText
            font.pixelSize: 12
            color: constants.c300
            onLinkActivated: Qt.openUrlExternally(link)
            background: MouseArea {
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }
}
