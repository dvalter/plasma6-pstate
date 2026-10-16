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
import org.kde.plasma.plasma5support as P5Support
import org.kde.ksysguard.sensors as Sensors
import org.kde.kirigami as Kirigami

import '../code/utils.js' as Utils

PlasmoidItem {
    id: main

    signal sensorsValuesChanged
    signal dataSourceReady
    signal updateSensor(string name, string value)

    FontLoader {
        id: symbolsFont;
        source: '../font/plasma-pstate.ttf'
    }

    property var sensors_model: Utils.get_sensors()
    property alias isReady: monitorDS.isReady
    property bool inTray: (Plasmoid.containmentDisplayHints & PlasmaCore.Types.ContainmentDrawsPlasmoidHeading) !== 0
    property string scriptPath: '/usr/share/plasma/plasmoids/gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh'
    property string readCommand: (Plasmoid.configuration.useSudoForReading ? 'sudo ' : '') + scriptPath + ' -read-all'

    compactRepresentation: CompactRepresentation { }
    fullRepresentation: FullRepresentation { }

    preferredRepresentation: compactRepresentation
    switchWidth: Kirigami.Units.gridUnit * 15
    switchHeight: Kirigami.Units.gridUnit * 20

    toolTipMainText: '' //i18n('Intel pstate and Thermal Management')
    toolTipSubText: ''
    toolTipTextFormat: Text.RichText
    Plasmoid.icon: 'cpu'

    onUpdateSensor: (name, value) => {
        print("updating sensor " + name +": " + value)
        if(value != sensors_model[name]['value']) {
            updater.update(name, value)
        } else {
            print("    same value")
        }
    }

    function get_value_text(sensor, value) {
        // lol! Is this the bwsat way to do it?
        var obj = {'value': value, 'unit': sensors_model[sensor]['unit']}
        return sensors_model[sensor]['print'](obj)
    }

    function get_sensors_text(sensors) {
        var res = '';
        if(sensors != undefined) {
            for(var i = 0 ; i < sensors.length; i++) {
                var value = sensors_model[sensors[i]]['print'](sensors_model[sensors[i]]);
                if(value) {
                    if(res) {
                        res += ' | ';
                    }
                    res += value;
                }
            }
        }

        return res || 'N/A';
    }

    onSensorsValuesChanged: {
        updateTooltip();
    }

    // The systemmonitor dataengine is gone in Plasma 6, use ksystemstats sensors instead
    component SystemSensor: Sensors.Sensor {
        property string modelKey
        updateRateLimit: 2000
        onValueChanged: {
            sensors_model[modelKey]['value'] = value
            sensorsValuesChanged()
        }
    }

    SystemSensor { sensorId: 'cpu/all/averageFrequency'; modelKey: 'cpu_cur_freq' }
    SystemSensor { sensorId: 'cpu/all/usage'; modelKey: 'cpu_cur_load' }
    SystemSensor { sensorId: 'cpu/all/maximumTemperature'; modelKey: 'package_temp' }

    P5Support.DataSource {
        id: powermanagementDS
        engine: "powermanagement"
        connectedSources: ['Battery']
        onDataChanged: {
            if(powermanagementDS.data["Battery"]) {
                sensors_model['battery_remaining_time']['value'] = Number(powermanagementDS.data["Battery"]["Remaining msec"]) / 1000;
                sensors_model['battery_percentage']['value'] = powermanagementDS.data["Battery"]["Percent"];
                sensorsValuesChanged()
            }
        }
        interval: 2000
    }

    P5Support.DataSource {
        id: monitorDS
        engine: 'executable'

        property bool isReady: false

        connectedSources: [readCommand]

        onNewData: (sourceName, data) => {
            if (data['exit code'] > 0) {
                print('monitorDS error: ' + data.stderr)
            } else {
                var obj = JSON.parse(data.stdout);
                var keys = Object.keys(obj);
                for(var i=0; i< keys.length; i++) {
                    sensors_model[keys[i]]['value'] = obj[keys[i]];
                }
                if(!isReady) {
                    dataSourceReady();
                    isReady = true;
                }
                sensorsValuesChanged();
            }
        }
        interval: 2000
    }

    P5Support.DataSource {
        id: updater
        engine: 'executable'

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            if (data['exit code'] > 0) {
                print("    error: " + data.stderr)
            } else {
                print("    done")
            }
        }

        function update(parameter, value) {
            var command = 'sudo ' + scriptPath + ' -' + parameter.replace(/_/g, '-') + ' ' + value
            print("exec: " + command)
            connectSource(command)
        }
    }

    function updateTooltip() {
        var toolTipSubText ='';
        var txt = '';

        toolTipSubText += '<font size="4"><table>'

        toolTipSubText += '<tr>'
        toolTipSubText += '<td style="text-align: right;">'
        toolTipSubText += '<span style="font-family: Plasma pstate Manager;"><font size="5">d</font></span>'
        toolTipSubText += '</td>'
        toolTipSubText += '<td style="text-align: left;">'
        toolTipSubText += '<span>&nbsp;&nbsp;'+get_sensors_text(['cpu_cur_load', 'cpu_cur_freq', 'gpu_cur_freq'])+'</span>'
        toolTipSubText += '</td>'
        toolTipSubText += '</tr>'

        txt = get_sensors_text(['battery_percentage', 'battery_remaining_time']);
        if(txt != 'N/A') {
            toolTipSubText += '<tr>'
            toolTipSubText += '<td style="text-align: center;">'
            toolTipSubText += '<span style="font-family: Plasma pstate Manager;"><font size="5">h</font></span>'
            toolTipSubText += '</td>'
            toolTipSubText += '<td style="text-align: left;">'
            toolTipSubText += '<span>&nbsp;&nbsp;'+ txt +'</span>'
            toolTipSubText += '</td>'
            toolTipSubText += '</tr>'
        }

        txt = get_sensors_text(['package_temp', 'fan_speeds']);
        if (txt != 'N/A') {
            toolTipSubText += '<tr>'
            toolTipSubText += '<td style="text-align: center;">'
            toolTipSubText += '<span style="font-family: Plasma pstate Manager;"><font size="5">b</font></span>'
            toolTipSubText += '</td>'
            toolTipSubText += '<td style="text-align: left;">'
            toolTipSubText += '<span>&nbsp;&nbsp;'+ txt +'</span>'
            toolTipSubText += '</td>'
            toolTipSubText += '</tr>'
        }
        toolTipSubText += '</table></font>'

        main.toolTipSubText = toolTipSubText
    }
}
