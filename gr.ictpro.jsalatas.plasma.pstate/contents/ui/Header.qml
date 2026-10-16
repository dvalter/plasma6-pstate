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

GridLayout {
    property var props

    columns: 2
    columnSpacing: 10
    rowSpacing: 0

    PlasmaComponents.Label {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 2.2

        horizontalAlignment: Text.AlignHCenter

        text: props.icon
        font.pointSize: Kirigami.Theme.smallFont.pointSize * 2.5
        font.family: symbolsFont.name
        color: Kirigami.Theme.textColor
    }

    PlasmaComponents.Label {
        text: props.text
        font.pointSize: Kirigami.Theme.smallFont.pointSize * 2
        color: Kirigami.Theme.textColor
    }

    Item {
        visible: sensorsLabel.visible
    }

    PlasmaComponents.Label {
        id: sensorsLabel

        Layout.bottomMargin: 5

        text: main.valuesText(props.sensors || [])
        font.pointSize: Kirigami.Theme.smallFont.pointSize * 1.25
        color: Kirigami.Theme.textColor
        opacity: 0.8

        visible: text != ''
    }

    Item {
    }

    ColumnLayout {
        Repeater {
            model: props.items

            Control {
                required property var modelData
                props: modelData
            }
        }
    }
}
