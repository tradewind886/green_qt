import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

Page {
    required property Account account

    readonly property var selectedOutputs: {
        const outputs = []
        for (var i = 0; i < selection_model.selectedIndexes.length; i++) {
            const index = selection_model.selectedIndexes[i]
            const output = output_model.data(index, Qt.UserRole)
            outputs.push(output)
        }
        return outputs;
    }

    id: self
    padding: 0
    focusPolicy: Qt.ClickFocus
    background: Rectangle {
        color: '#161921'
        border.width: 1
        border.color: '#1F222A'
        radius: 4
        Label {
            visible: list_view.count === 0
            anchors.centerIn: parent
            color: 'white'
            text: {
                if (output_model_filter.filter === '') {
                    return qsTrId('id_youll_see_your_coins_here_when')
                } else {
                    return qsTrId('id_there_are_no_results_for_the')
                }
            }
        }
    }
    contentItem: TListView {
        id: list_view
        spacing: 0
        model: output_model_filter
        delegate: OutputDelegate {
            highlighted: selection_model.selectedIndexes.indexOf(output_model.index(output_model.indexOf(output), 0))>-1
            width: ListView.view.width
        }
        BusyIndicator {
            width: 32
            height: 32
            // TODO
            running: output_model.fetching
            anchors.margins: 8
            Layout.alignment: Qt.AlignHCenter
            opacity: output_model.fetching ? 1 : 0
            Behavior on opacity { OpacityAnimator {} }
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
    header: GPane {
        padding: 10
        contentItem: RowLayout {
            spacing: 8
            Repeater {
                model: {
                    const filters = ['', 'csv', 'p2wsh']
                    if (account.network.liquid) {
                        filters.push('not_confidential')
                    } else {
                        filters.push('p2sh')
                        filters.push('dust')
                        filters.push('locked')
                    }
                    if (account.type !== '2of3' && account.type !== '2of2_no_recovery') {
                        filters.push('expired')
                    }
                    return filters
                }
                delegate: ItemDelegate {
                    id: self
                    ButtonGroup.group: button_group
                    checked: index === 0
                    checkable: true
                    padding: 18
                    topInset: 0
                    bottomInset: 0
                    topPadding: 4
                    bottomPadding: 4
                    background: Rectangle {
                        id: rectangle
                        radius: 4
                        color: self.checked ? constants.c300 : constants.c500
                    }
                    contentItem: Label {
                        text: self.text
                        font.pixelSize: 10
                        font.weight: 400
                        font.styleName: 'Regular'
                    }
                    text: localizedLabel(modelData)
                    property string buttonTag: modelData
                    font.capitalization: Font.AllUppercase
                }
            }
            HSpacer {
            }
            ToolButton {
                visible: false
                topPadding: 0
                bottomPadding: 0
                topInset: 0
                bottomInset: 0
                icon.source: "qrc:/svg/info.svg"
                icon.color: "white"
                onClicked: info_dialog.createObject(self).open();
            }
        }
    }

    footer: GPane {
        padding: 10
        visible: selection_model.hasSelection && !account.network.liquid
        contentItem: RowLayout {
            spacing: constants.p1
            Label {
                text: selection_model.selectedIndexes.length + ' selected'
                padding: 4
            }
            HSpacer {
            }
            GButton {
                text: qsTrId('id_lock')
                enabled: {
                    for (const output of selectedOutputs) {
                        if (!output.canBeLocked || output.locked || output.unconfirmed) return false;
                    }
                    return true;
                }
                onClicked: set_unspent_outputs_status_dialog.createObject(self, { outputs: selectedOutputs, status: "frozen" }).open();
            }
            GButton {
                text: qsTrId('id_unlock')
                enabled: {
                    for (const output of selectedOutputs) {
                        if (!output.locked) return false;
                    }
                    return true;
                }
                onClicked: set_unspent_outputs_status_dialog.createObject(self, { outputs: selectedOutputs, status: "default" }).open();
            }
            GButton {
                text: qsTrId('id_clear')
                onClicked: selection_model.clear();
            }
        }
    }

    Component {
        id: set_unspent_outputs_status_dialog
        SetUnspentOutputsStatusDialog {
            model: output_model
            account: self.account
        }
    }

    Component {
        id: info_dialog
        AbstractDialog {
            title: qsTrId('id_filters')
            icon: "qrc:/svg/info.svg"
            contentItem: ColumnLayout {
                spacing: constants.p3
                Repeater {
                    model: ['all', 'csv', 'p2wsh', 'p2sh', 'not_confidential', 'dust', 'locked', 'expired']
                    delegate: RowLayout {
                        spacing: constants.p1

                        Tag {
                            text: localizedLabel(modelData)
                            Layout.minimumWidth: 120
                            Layout.alignment: Qt.AlignTop
                            horizontalAlignment: Label.AlignHCenter
                            font.capitalization: Font.AllUppercase
                        }

                        Label {
                            Layout.maximumWidth: 400
                            text: {
                                switch (modelData) {
                                    case 'all':
                                        return qsTrId('id_all_the_coins_received_or')
                                    case 'csv':
                                        return qsTrId('id_coins_protected_by_the_new')
                                    case 'p2wsh':
                                        return qsTrId('id_coins_protected_by_the_legacy')
                                    case 'p2sh':
                                        return qsTrId('id_coins_received_or_created')
                                    case 'not_confidential':
                                        return qsTrId('id_coins_whose_asset_and_amount')
                                    case 'dust':
                                        return qsTrId('id_coins_with_a_value_lower_than')
                                    case 'locked':
                                        return qsTrId('id_locking_coins_can_help_protect')
                                    case 'expired':
                                        return qsTrId('id_coins_for_which_2fa_protection')
                                }
                            }
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
