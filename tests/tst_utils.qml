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

    function test_print_helpers() {
        compare(Utils.array_to_int({'value': {'a': '2100.4', 'b': undefined, 'c': '0'}, 'unit': ' RPM'}), '2100 RPM | 0 RPM')
        compare(Utils.to_int({'value': '', 'unit': '%'}), '')
        compare(Utils.to_time({'value': 5400}), '1:30')
    }
}
