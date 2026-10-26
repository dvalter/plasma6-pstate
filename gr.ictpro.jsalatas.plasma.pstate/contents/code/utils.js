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

function to_int(value, unit) {
    var val = Math.round(parseFloat(value));
    return isNaN(val) ? '' : val + unit;
}

function array_to_int(values, unit) {
    return Object.keys(values || {}).map(key => to_int(values[key], unit))
                                    .filter(text => text)
                                    .join(' | ');
}

function to_string(value) {
    return value || '';
}

// The TCC offset lowers the temperature
function to_tcc_offset(value, unit) {
    var text = to_int(value, unit);
    return text && Math.round(parseFloat(value)) != 0 ? '-' + text : text;
}

function to_time(value) {
    var val = Math.round(parseFloat(value));
    if(!(val > 0)) {
        return '';
    }
    var hours = Math.floor(val / 3600);
    var minutes = Math.floor(val % 3600 / 60);
    return hours + ':' + (minutes < 10 ? '0' : '') + minutes;
}

// How to display sensors and settings. Anything not listed is shown as an
// integer without a unit.
var sensors = {
    'cpu_cur_load': {'unit': '%'},
    'cpu_cur_freq': {'unit': ' MHz'},
    'gpu_cur_freq': {'unit': ' MHz'},
    'battery_percentage': {'unit': '%'},
    'battery_remaining_time': {'format': to_time},
    'package_temp': {'unit': ' \u2103'},
    'fan_speeds': {'unit': ' RPM', 'format': array_to_int},
    'cpu_min_perf': {'unit': '%'},
    'cpu_max_perf': {'unit': '%'},
    'gpu_min_freq': {'unit': ' MHz'},
    'gpu_max_freq': {'unit': ' MHz'},
    'gpu_boost_freq': {'unit': ' MHz'},
    'nvidia_runtime_status': {'format': to_string},
    'intel_rapl_long': {'unit': ' W'},
    'intel_rapl_short': {'unit': ' W'},
    'intel_tcc_cur_state': {'unit': ' °C', 'format': to_tcc_offset},
}

function format_value(name, value) {
    var sensor = sensors[name] || {};
    return (sensor.format || to_int)(value, sensor.unit || '');
}

// The values of the named sensors as text, skipping those without a value
function sensors_text(names, values) {
    return names.map(name => format_value(name, values[name]))
                .filter(text => text)
                .join(' | ');
}

// The sections of the popup. Controls are only shown for the settings the
// hardware has, and sections and groups only when they have controls.
var model =  [
    {'type': 'header', 'text': 'Processor Settings', 'icon': 'd',
        'sensors': ['cpu_cur_load', 'cpu_cur_freq', 'gpu_cur_freq'],
        'items': [
            {'type': 'group', 'text': 'CPU Frequencies', 'items' :[
                {'type': 'slider', 'text': 'Min perf', 'min': 0, 'max': 100, 'sensor': 'cpu_min_perf'},
                {'type': 'slider', 'text': 'Max perf', 'min': 0, 'max': 100, 'sensor': 'cpu_max_perf'},
                {'type': 'switch', 'text': 'Turbo', 'sensor': 'cpu_turbo'}
            ]},
            {'type': 'group', 'text': 'GPU Frequencies', 'visible': 'showIntelGPU', 'items' :[
                {'type': 'slider', 'text': 'Min freq', 'min': 'gpu_min_limit', 'max': 'gpu_max_limit', 'sensor': 'gpu_min_freq'},
                {'type': 'slider', 'text': 'Max freq', 'min': 'gpu_min_limit', 'max': 'gpu_max_limit', 'sensor': 'gpu_max_freq'},
                {'type': 'slider', 'text': 'Boost freq', 'min': 'gpu_min_limit', 'max': 'gpu_max_limit', 'sensor': 'gpu_boost_freq'},
            ]},
            {'type': 'radio', 'text': 'CPU Governor', 'sensor': 'cpu_governor',
                'available': 'cpu_available_governors', 'items' :[
                {'symbol': 'a', 'text': 'Performance', 'sensor_value': 'performance'},
                {'symbol': 'f', 'text': 'Powersave', 'sensor_value': 'powersave'},
                {'symbol': 'l', 'text': 'Ondemand', 'sensor_value': 'ondemand'},
                {'symbol': 'k', 'text': 'Schedutil', 'sensor_value': 'schedutil'},
                {'symbol': 'f', 'text': 'Conservative', 'sensor_value': 'conservative'}
            ]}
        ]
    },
    {'type': 'header', 'text': 'Energy Performance', 'icon': 'h',
        'sensors': ['battery_percentage', 'battery_remaining_time'],
        'items': [
            {'type': 'radio', 'text': '', 'sensor': 'energy_perf', 'items' :[
                {'symbol': 'i', 'text': 'Default', 'sensor_value': 'default'},
                {'symbol': 'a', 'text': 'Performance', 'sensor_value': 'performance'},
                {'symbol': 'k', 'text': 'Balance Performance', 'sensor_value': 'balance_performance'},
                {'symbol': 'l', 'text': 'Balance Power', 'sensor_value': 'balance_power'},
                {'symbol': 'f', 'text': 'Power', 'sensor_value': 'power'}
            ]},
            {'type': 'group', 'text': 'Running Average Power Limit (RAPL)', 'items' :[
                {'type': 'slider', 'text': 'Short Term', 'min': 1, 'max': 'intel_rapl_short_max',
                 'sensor': 'intel_rapl_short'},
                {'type': 'slider', 'text': 'Long Term', 'min': 1, 'max': 'intel_rapl_long_max',
                 'sensor': 'intel_rapl_long'}
            ]}
        ]
    },
    {'type': 'header', 'text': 'Thermal Management', 'icon': 'b',
        'sensors': ['package_temp', 'fan_speeds'],
        'items': [
            {'type': 'radio', 'text': 'Thermal Mode', 'sensor': 'thermal_mode', 'items' :[
                 {'symbol': 'e', 'text': 'Performance', 'sensor_value': 'performance'},
                 {'symbol': 'j', 'text': 'Balanced', 'sensor_value': 'balanced'},
                 {'symbol': 'g', 'text': 'Cool Bottom', 'sensor_value': 'cool-bottom'},
                {'symbol': 'c', 'text': 'Quiet', 'sensor_value': 'quiet'}
            ]},
            {'type': 'group', 'text': 'Thermal Control Circuit', 'items' :[
                {'type': 'slider', 'text': 'Offset', 'min': 0, 'max': 'intel_tcc_max_state',
                 'sensor': 'intel_tcc_cur_state'}
            ]}
        ]
    }, 
    {'type': 'header', 'text': 'Power Supply Management', 'icon': 'm',
        'items': [
            {'type': 'switch', 'text': 'Battery Limit', 'sensor': 'lg_battery_charge_limit'},
            {'type': 'switch', 'text': 'USB Charge', 'sensor': 'lg_usb_charge'}
        ]
    },
    {'type': 'header', 'text': 'Fan Control', 'icon': 'n',
        'items': [
            {'type': 'switch', 'text': 'Silent Mode', 'sensor': 'lg_fan_mode'}
        ]
    },
    {'type': 'header', 'text': 'Nvidia Settings', 'icon': 'o',
        'sensors': ['nvidia_runtime_status'],
        'items': [
            {'type': 'combobox', 'text': 'PowerMizer', 'sensor': 'powermizer', 'items' :[
                 {'text': 'Adaptive', 'sensor_value': '0'},
                 {'text': 'Prefer Max Performance', 'sensor_value': '1'},
                {'text': 'Auto', 'sensor_value': '2'}
            ]}
        ]
    }
]

// Walk a ksysguard SensorTreeModel and return the ids of all sensors matching
// pattern. Needed because SensorDataModel doesn't resolve wildcards.
function find_sensor_ids(tree, idRole, pattern, parent) {
    var res = [];
    for(var i = 0; i < tree.rowCount(parent); i++) {
        var index = tree.index(i, 0, parent);
        var id = tree.data(index, idRole);
        if(id && pattern.test(id)) {
            res.push(id);
        }
        res = res.concat(find_sensor_ids(tree, idRole, pattern, index));
    }
    return res;
}

// The options of a radio or combobox. With 'available', only those listed in
// that setting, separated by spaces, once it has been read.
function available_items(item, values) {
    var available = item.available && values[item.available];
    if(!available) {
        return item.items;
    }
    available = available.split(/\s+/);
    return item.items.filter(option => available.includes(option.sensor_value));
}

// Whether a control, or any control in a group or section, has a value
function has_value(item, values) {
    if(item.items && item.type != 'radio' && item.type != 'combobox') {
        return item.items.some(child => has_value(child, values));
    }
    return values[item.sensor] !== undefined;
}

function get_model() {
    return model;
}

