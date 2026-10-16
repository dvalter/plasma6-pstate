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
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

RowLayout {
    Layout.fillWidth: true

    property var sensor: []
    
    property bool acceptingChanges: false
    property alias text: combobox_title.text
    property var props
    spacing: 10

    onPropsChanged: {
        acceptingChanges = false

        combobox.model = props['items']
        text = props['text']
        sensor.push(props['sensor'])

        acceptingChanges = true
    }

    Component.onCompleted: {
        acceptingChanges = true
        main.sensorsValuesChanged()
    }

    Connections {
        target: main
        function onSensorsValuesChanged() {
            acceptingChanges = false
            if(sensor.length != 0) {
                var value = main.sensors_model[sensor[0]]['value'];
                for(var i = 0; i < combobox.model.length; i++) {
                    if(combobox.model[i].sensor_value == value) {
                        combobox.currentIndex = i
                    }
                }
            }
            acceptingChanges = true
        }
    }
    
    PlasmaComponents.Label {
        Layout.alignment: Qt.AlignVCenter
        id: combobox_title
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        color: Kirigami.Theme.textColor
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: Kirigami.Units.gridUnit * 4
    }

    PlasmaComponents.ComboBox {
        id: combobox
        textRole: "text"
        onActivated: {
            if(acceptingChanges) {
                main.updateSensor(sensor[0], combobox.model[currentIndex].sensor_value)
            }

        }
        Layout.fillWidth: true
    }
}
