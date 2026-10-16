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
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import '../code/utils.js' as Utils

PlasmoidItem {
    id: main

    FontLoader {
        id: symbolsFont;
        source: '../font/plasma-pstate.ttf'
    }

    property bool inTray: (Plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading) !== 0

    Backend {
        id: backend
        useSudoForReading: Plasmoid.configuration.useSudoForReading
    }

    compactRepresentation: CompactRepresentation { }
    fullRepresentation: FullRepresentation { }

    preferredRepresentation: compactRepresentation
    switchWidth: Kirigami.Units.gridUnit * 15
    switchHeight: Kirigami.Units.gridUnit * 20

    toolTipMainText: '' //i18n('Intel pstate and Thermal Management')
    toolTipSubText: tooltipText()
    toolTipTextFormat: Text.RichText
    Plasmoid.icon: 'cpu'

    // A row with the icon and the sensor values of every section that has some
    function tooltipText() {
        var rows = Utils.get_model()
            .filter(section => section.sensors && backend.valuesText(section.sensors))
            .map(section => '<tr>'
                 + '<td style="text-align: center;"><span style="font-family: ' + symbolsFont.name + ';">'
                 + '<font size="5">' + section.icon + '</font></span></td>'
                 + '<td style="text-align: left;"><span>&nbsp;&nbsp;' + backend.valuesText(section.sensors) + '</span></td>'
                 + '</tr>')
        return '<font size="4"><table>' + rows.join('') + '</table></font>'
    }
}
