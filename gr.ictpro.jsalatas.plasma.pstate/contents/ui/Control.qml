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
import org.kde.plasma.plasmoid

import '../code/utils.js' as Utils

// Shows the control described by props, according to its type
Loader {
    property var props

    readonly property var sources: ({
        'group': 'Group.qml',
        'radio': 'Radio.qml',
        'slider': 'Slider.qml',
        'switch': 'Switch.qml',
        'combobox': 'ComboBox.qml'
    })

    Layout.topMargin: 5
    Layout.bottomMargin: props.type == 'group' || props.type == 'radio' ? 10 : 5
    Layout.fillWidth: props.type == 'group' || props.type == 'slider'

    // Controls are hidden when the hardware lacks their settings, and can
    // depend on a configuration option
    visible: Utils.has_value(props, backend.values)
             && (props.visible === undefined || Plasmoid.configuration[props.visible])

    Component.onCompleted: {
        if(props.type in sources) {
            setSource(sources[props.type], {'props': props})
        } else {
            console.warn('Unknown control type: ' + props.type)
        }
    }
}
