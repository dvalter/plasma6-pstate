/*
 *   Copyright 2018 John Salatas <jsalatas@ictpro.gr>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    implicitWidth: Kirigami.Units.gridUnit * 4.2
    implicitHeight: Kirigami.Units.gridUnit * 4

    objectName: "PushButton"

    property string symbol
    property alias text: label.text
    property string sensor
    property string sensorValue

    readonly property bool active: backend.values[sensor] == sensorValue
    readonly property bool updating: active && sensor in backend.pending

    property color borderColor: updating ? Kirigami.Theme.negativeTextColor : (active ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.6) :
                                         Qt.rgba(Kirigami.Theme.textColor.r,      Kirigami.Theme.textColor.g,      Kirigami.Theme.textColor.b,      0.4))
    property color buttonColor: active ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor

    Rectangle {
        anchors.fill: parent
        border.width: 2
        border.color: borderColor
        color: "transparent"
        radius: 3
        id: button

        MouseArea {
            anchors.fill: parent
            onClicked: backend.changeSetting(sensor, sensorValue)
        }

        PlasmaComponents.Label {
            id: icon
            anchors {
                margins: Kirigami.Units.smallSpacing *1.5
                right: parent.right
                left: parent.left
                top: parent.top
            }

            verticalAlignment: Text.AlignTop
            horizontalAlignment: Text.AlignHCenter

            font.pointSize: Kirigami.Theme.smallFont.pointSize * 2.8
            font.family: symbolsFont.name
            color: buttonColor
 
            text: symbol
        }

        PlasmaComponents.Label {
            id: label
            anchors {
                margins: Kirigami.Units.smallSpacing * 1.5
                right: parent.right
                left: parent.left
                bottom: parent.bottom
            }

            verticalAlignment: Text.AlignBottom
            horizontalAlignment: Text.AlignHCenter

            wrapMode: Text.WordWrap
            font.pointSize: Kirigami.Theme.smallFont.pointSize * 0.9
            lineHeight: 0.75

            color: buttonColor
        }
    }
}
