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

ColumnLayout {
    id: radio

    property alias text: radio_title.text
    property string sensor
    property var items: []

    property var props

    objectName: "Radio"

    Component {
        id: pushButton
        PushButton {}
    }

    onPropsChanged: {
        text = props['text']
        sensor = props['sensor']
        items = props['items']
    }

    onItemsChanged: {
        for(var i = 0; i < items.length; i++) {
            pushButton.createObject(buttons, {
                'symbol': items[i]['symbol'],
                'text': items[i]['text'],
                'sensor': sensor,
                'sensorValue': items[i]['sensor_value']
            });
        }
    }

    PlasmaComponents.Label {
        id: radio_title
        font.pointSize: Kirigami.Theme.smallFont.pointSize * 1.25
        color: Kirigami.Theme.textColor
        visible: text != ''
    }
    RowLayout {
        id: buttons
        spacing: -0.5
        Layout.topMargin: radio_title.visible ? 0 : 8
        Layout.rightMargin: 15

        height: Kirigami.Units.gridUnit * 4
    }
}
