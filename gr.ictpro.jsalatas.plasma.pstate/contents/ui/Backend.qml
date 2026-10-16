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

import org.kde.plasma.plasma5support as P5Support
import org.kde.ksysguard.sensors as Sensors

import '../code/utils.js' as Utils

// Reads the sensors and settings and changes the settings
Item {
    id: backend

    // The current value of every sensor and setting by name. It is replaced
    // rather than modified, so that bindings using it update.
    property var values: ({})
    // The settings being changed, by name
    property var pending: ({})

    property bool useSudoForReading: true
    property string scriptPath: decodeURIComponent(Qt.resolvedUrl('../code/set_prefs.sh').toString().replace(/^file:\/\//, ''))
    readonly property string readCommand: (useSudoForReading ? 'sudo ' : '') + scriptPath + ' -read-all'

    function setValues(changes) {
        var newValues = Object.assign({}, values)
        for(var name in changes) {
            // Don't let a read that started before a change undo it
            if(!(name in pending)) {
                newValues[name] = changes[name]
            }
        }
        values = newValues
    }

    function setValue(name, value) {
        var changes = {}
        changes[name] = value
        setValues(changes)
    }

    function valuesText(names) {
        return Utils.sensors_text(names, values)
    }

    function changeSetting(name, value) {
        value = String(value)
        if(value == values[name]) {
            return
        }
        // Show the new value right away; it is read back once written
        setValue(name, value)
        var newPending = Object.assign({}, pending)
        newPending[name] = value
        pending = newPending

        var command = 'sudo ' + scriptPath + ' -' + name.replace(/_/g, '-') + ' ' + value
        runner.run(command, (exitCode, stdout, stderr) => {
            if(exitCode > 0) {
                console.warn('Changing ' + name + ' failed: ' + stderr)
            }
            settingWritten(name)
        })
    }

    function settingWritten(name) {
        var newPending = Object.assign({}, pending)
        delete newPending[name]
        pending = newPending
        read()
    }

    property bool reading: false

    function read() {
        if(reading) {
            return
        }
        reading = true
        runner.run(readCommand, (exitCode, stdout, stderr) => {
            reading = false
            if(exitCode > 0) {
                console.warn('Reading the settings failed: ' + stderr)
            } else {
                setValues(JSON.parse(stdout))
            }
        })
    }

    // The systemmonitor dataengine is gone in Plasma 6, use ksystemstats sensors instead
    component SystemSensor: Sensors.Sensor {
        property string modelKey
        updateRateLimit: 2000
        onValueChanged: setValue(modelKey, value)
    }

    SystemSensor { sensorId: 'cpu/all/averageFrequency'; modelKey: 'cpu_cur_freq' }
    SystemSensor { sensorId: 'cpu/all/usage'; modelKey: 'cpu_cur_load' }
    SystemSensor { sensorId: 'cpu/all/maximumTemperature'; modelKey: 'package_temp' }

    property var fanSensorIds: []

    Sensors.SensorTreeModel {
        id: sensorTree

        function findFans() {
            var ids = Utils.find_sensor_ids(sensorTree, Sensors.SensorTreeModel.SensorId,
                                            /^lmsensors\/[\w.-]+\/fan\d+$/, sensorTree.index(-1, -1))
            if(ids.join() != fanSensorIds.join()) {
                fanSensorIds = ids
            }
        }

        onRowsInserted: findFans()
        onModelReset: findFans()
    }

    Instantiator {
        model: fanSensorIds
        delegate: Sensors.Sensor {
            required property string modelData
            sensorId: modelData
            updateRateLimit: 2000
            onValueChanged: {
                var fans = Object.assign({}, values['fan_speeds'])
                fans[sensorId] = value
                setValue('fan_speeds', fans)
            }
        }
    }

    P5Support.DataSource {
        id: powermanagementDS
        engine: "powermanagement"
        connectedSources: ['Battery']
        onDataChanged: {
            var battery = powermanagementDS.data["Battery"]
            if(battery) {
                setValues({
                    'battery_remaining_time': Number(battery["Remaining msec"]) / 1000,
                    'battery_percentage': battery["Percent"]
                })
            }
        }
        interval: 2000
    }

    CommandRunner {
        id: runner
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: read()
    }

    onReadCommandChanged: read()
}
