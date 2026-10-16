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
    property var props

    readonly property string sensor: props.sensor

    spacing: 10

    PlasmaComponents.Label {
        Layout.alignment: Qt.AlignVCenter
        text: props.text
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        color: Kirigami.Theme.textColor
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: Kirigami.Units.gridUnit * 4
    }

    PlasmaComponents.CheckBox {
        checked: main.values[sensor] == 'true'
        onToggled: main.changeSetting(sensor, checked)
    }
}
