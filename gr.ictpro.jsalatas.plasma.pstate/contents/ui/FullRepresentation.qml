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
import org.kde.kirigami as Kirigami

import '../code/utils.js' as Utils

Column {
    id: fullRoot
    spacing: 0.1
    Layout.minimumWidth: Kirigami.Units.gridUnit * 15
    Layout.minimumHeight: Kirigami.Units.gridUnit * 20

    property var model: Utils.get_model()
    property var vendors: Utils.get_vendors()

    Component {
        id: header
        Header {
        }
    }

    Component.onCompleted: {
        if(main.isReady) {
            initialize()
        }
    }

    Connections {
        target: main
        function onDataSourceReady() {
            initialize()
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onShowIntelGPUChanged() {
            if(main.isReady) {
                initialize()
            }
        }
        function onUseSudoForReadingChanged() {
            if(main.isReady) {
                initialize()
            }
        }
    }

    function is_present(item_vendors) {
        if(item_vendors && item_vendors.length != 0) {
            for(var j=0; j< item_vendors.length; j++) {
                var vendor = vendors[item_vendors[j]]
                for(var k=0; k<vendor['provides'].length; k++) {
                    if(main.values[vendor['provides'][k]]) {
                        return true;
                        break;
                    }
                }
            }
            return false;
        }

        return true;
    }

    function initialize() {
        removeChildren()

        var w = 0;
        var h = 0;

        for(var i = 0; i < model.length; i++) {
            var item = model[i];
            if(is_present(item['vendors'])) {
                switch (item.type) {
                    case 'header': {
                        var obj = header.createObject(fullRoot, {'props': item})
                        w = Math.max(w, obj.width)
                        h += obj.height
                        break
                    }
                    default: console.log("unkonwn type: " + item.type)
                }
            }
        }

        //FIXME: For some reason, the first time it is shown, the two rects are different :\
        print(">>>>>>>>>>>>> childrenRect: " + childrenRect.width + " - " + childrenRect.height)
        print(">>>>>>>>>>>>>          w-h: " + w + " - " + h)
        Layout.minimumWidth = w
        Layout.minimumHeight = h
        Layout.maximumWidth = w
        Layout.maximumHeight = h
    }
    
    function removeChildren() {
        for(var i = fullRoot.children.length; i > 0 ; i--) {
            fullRoot.children[i-1].destroy()
        }
    }
}
