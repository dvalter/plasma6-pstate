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

import '../code/utils.js' as Utils

RowLayout {
    property var props

    readonly property string sensor: props.sensor
    readonly property bool updating: sensor in main.pending

    spacing: 10

    // A limit is either a number or the name of the sensor that holds it
    function limit(value, fallback) {
        return typeof value === 'string' ? (parseInt(main.values[value], 10) || fallback) : value
    }

    PlasmaComponents.Label {
        Layout.alignment: Qt.AlignTop
        text: props.text
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        color: Kirigami.Theme.textColor
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: Kirigami.Units.gridUnit * 4
    }

    PlasmaComponents.Slider {
        id: slider
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignBottom
        from: limit(props.min, 0)
        to: limit(props.max, 100)
        stepSize: 1

        // Only change the setting once the slider is released
        onPressedChanged: {
            if(!pressed) {
                main.changeSetting(sensor, value)
            }
        }
        onMoved: {
            if(!pressed) {
                main.changeSetting(sensor, value)
            }
        }
    }

    Binding {
        target: slider
        property: 'value'
        value: parseInt(main.values[sensor], 10) || slider.from
        when: !slider.pressed
        restoreMode: Binding.RestoreNone
    }

    PlasmaComponents.Label {
        Layout.alignment: Qt.AlignTop
        text: Utils.format_value(sensor, slider.value)
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        color: slider.pressed || updating ? '#ff0000' : Kirigami.Theme.textColor
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: Kirigami.Units.gridUnit * 3
    }
}
