import QtQuick
import QtTest

import '../gr.ictpro.jsalatas.plasma.pstate/contents/code/utils.js' as Utils

TestCase {
    name: "Utils"

    // Minimal stand-in for a ksysguard SensorTreeModel: nested {id, children}
    function fakeTree(roots) {
        return {
            rowCount: parent => (parent ? parent.children : roots).length,
            index: (row, column, parent) => (parent ? parent.children : roots)[row],
            data: (index, role) => index.id
        }
    }

    function test_find_fan_sensors() {
        var tree = fakeTree([
            {id: '', children: [
                {id: '', children: [{id: 'cpu/all/usage', children: []}]}]},
            {id: '', children: [
                {id: '', children: [
                    {id: 'lmsensors/.*/fan\\d+', children: []},
                    {id: 'lmsensors/dell_smm-virtual-0/fan1', children: []},
                    {id: 'lmsensors/dell_smm-virtual-0/fan2', children: []},
                    {id: 'lmsensors/dell_smm-virtual-0/fan2_min', children: []},
                    {id: 'lmsensors/coretemp-isa-0000/temp1', children: []}]},
                {id: '', children: [
                    {id: 'lmsensors/thinkpad-isa-0000/fan1', children: []}]}]}
        ])
        compare(Utils.find_sensor_ids(tree, 0, /^lmsensors\/[\w.-]+\/fan\d+$/, null),
                ['lmsensors/dell_smm-virtual-0/fan1',
                 'lmsensors/dell_smm-virtual-0/fan2',
                 'lmsensors/thinkpad-isa-0000/fan1'])
    }

    function test_format_value() {
        compare(Utils.format_value('cpu_min_perf', '20'), '20%')
        compare(Utils.format_value('cpu_min_perf', ''), '')
        compare(Utils.format_value('cpu_min_perf', undefined), '')
        compare(Utils.format_value('gpu_min_limit', '300.4'), '300')
        compare(Utils.format_value('battery_remaining_time', 5400), '1:30')
        compare(Utils.format_value('battery_remaining_time', 1800), '0:30')
        compare(Utils.format_value('battery_remaining_time', 0), '')
        compare(Utils.format_value('battery_remaining_time', undefined), '')
        compare(Utils.format_value('fan_speeds', {'a': '2100.4', 'b': undefined, 'c': '0'}), '2100 RPM | 0 RPM')
    }

    function test_sensors_text() {
        var values = {'cpu_cur_load': 12.6, 'cpu_cur_freq': undefined, 'gpu_cur_freq': '450'}
        compare(Utils.sensors_text(['cpu_cur_load', 'cpu_cur_freq', 'gpu_cur_freq'], values), '13% | 450 MHz')
        compare(Utils.sensors_text(['cpu_cur_freq'], values), '')
    }

    function test_has_value() {
        var values = {'cpu_min_perf': '20', 'cpu_governor': 'powersave'}
        verify(Utils.has_value({'type': 'slider', 'sensor': 'cpu_min_perf'}, values))
        verify(!Utils.has_value({'type': 'slider', 'sensor': 'gpu_min_freq'}, values))
        verify(Utils.has_value({'type': 'radio', 'sensor': 'cpu_governor', 'items': [{'sensor_value': 'performance'}]}, values))
        verify(!Utils.has_value({'type': 'combobox', 'sensor': 'powermizer', 'items': [{'sensor_value': '0'}]}, values))
        verify(Utils.has_value({'type': 'header', 'items': [
            {'type': 'group', 'items': [{'type': 'slider', 'sensor': 'gpu_min_freq'}]},
            {'type': 'group', 'items': [{'type': 'slider', 'sensor': 'cpu_min_perf'}]}]}, values))
        verify(!Utils.has_value({'type': 'header', 'items': [
            {'type': 'group', 'items': [{'type': 'slider', 'sensor': 'gpu_min_freq'}]},
            {'type': 'switch', 'sensor': 'lg_fan_mode'}]}, values))
    }
}
