import QtQuick
import QtTest

import '../gr.ictpro.jsalatas.plasma.pstate/contents/ui'

// Runs the backend against the mocks, see run-tests.sh
TestCase {
    name: "Backend"

    Component {
        id: backendComponent
        Backend { }
    }

    property Backend backend

    function init() {
        backend = createTemporaryObject(backendComponent, this)
        tryVerify(() => backend.values['cpu_governor'] !== undefined, 5000, 'settings are read')
        tryVerify(() => backend.values['powermizer'] !== undefined, 5000, 'PowerMizer mode is read')
    }

    function test_read() {
        compare(backend.values['cpu_min_perf'], '20')
        compare(backend.values['cpu_turbo'], 'true')
        compare(backend.values['energy_perf'], 'balance_performance')
        compare(backend.values['thermal_mode'], 'balanced')
        compare(backend.values['lg_usb_charge'], 'true')
        compare(backend.values['powermizer'], '2')
    }

    function test_change() {
        backend.changeSetting('cpu_governor', 'performance')
        compare(backend.values['cpu_governor'], 'performance', 'shown right away')
        verify('cpu_governor' in backend.pending)
        tryVerify(() => !('cpu_governor' in backend.pending), 5000, 'write finishes')

        // A new backend sees the change, so it was written
        var other = createTemporaryObject(backendComponent, this)
        tryVerify(() => other.values['cpu_governor'] == 'performance', 5000, 'cpu_governor is performance')

        backend.changeSetting('cpu_governor', 'powersave')
        tryVerify(() => !('cpu_governor' in backend.pending), 5000)
    }

    function test_bool_change() {
        backend.changeSetting('cpu_turbo', false)
        tryVerify(() => !('cpu_turbo' in backend.pending), 5000)
        var other = createTemporaryObject(backendComponent, this)
        tryVerify(() => other.values['cpu_turbo'] == 'false', 5000, 'cpu_turbo is false')

        backend.changeSetting('cpu_turbo', true)
        tryVerify(() => !('cpu_turbo' in backend.pending), 5000)
    }

    function test_change_is_not_undone() {
        backend.changeSetting('energy_perf', 'power')
        tryVerify(() => !('energy_perf' in backend.pending), 5000)
        // Reads that ran during the change must not bring back the old value
        for(var i = 0; i < 25; i++) {
            compare(backend.values['energy_perf'], 'power')
            wait(100)
        }
        backend.changeSetting('energy_perf', 'balance_performance')
        tryVerify(() => !('energy_perf' in backend.pending), 5000)
    }

    function test_read_during_change() {
        // The read has its data after 150ms, but only returns it after
        // MOCK_READ_DELAY, when the change has finished
        backend.read()
        wait(150)
        backend.changeSetting('thermal_mode', 'quiet')
        tryVerify(() => !('thermal_mode' in backend.pending), 5000)
        for(var i = 0; i < 10; i++) {
            compare(backend.values['thermal_mode'], 'quiet')
            wait(100)
        }
        backend.changeSetting('thermal_mode', 'balanced')
        tryVerify(() => !('thermal_mode' in backend.pending), 5000)
    }

    function test_repeated_change() {
        // Changing back to a value written moments ago runs the same command
        // again, which must not be answered from a cache
        for(var value of ['false', 'true', 'false']) {
            backend.changeSetting('lg_fan_mode', value)
            tryVerify(() => !('lg_fan_mode' in backend.pending), 5000)
        }
        var other = createTemporaryObject(backendComponent, this)
        tryVerify(() => other.values['lg_fan_mode'] !== undefined, 5000)
        compare(other.values['lg_fan_mode'], 'false')

        backend.changeSetting('lg_fan_mode', 'true')
        tryVerify(() => !('lg_fan_mode' in backend.pending), 5000)
    }

    function test_failed_change_reverts() {
        ignoreWarning(/Changing powermizer failed/)
        backend.changeSetting('powermizer', '7')
        compare(backend.values['powermizer'], '7')
        tryVerify(() => !('powermizer' in backend.pending), 5000)
        tryVerify(() => backend.values['powermizer'] == '2', 5000, 'powermizer is 2')
    }
}
