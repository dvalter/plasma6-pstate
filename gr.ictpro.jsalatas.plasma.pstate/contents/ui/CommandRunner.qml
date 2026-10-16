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

// Runs shell commands and passes their results to a callback
P5Support.DataSource {
    engine: 'executable'

    property int runs: 0
    // The callback of each running command, by source name
    property var callbacks: ({})

    // callback(exitCode, stdout, stderr)
    function run(command, callback) {
        // Shortly after a command finishes, the dataengine hands out its
        // result again instead of running it once more. Give every run its
        // own source name with a shell comment so that it really runs.
        var source = command + ' # ' + (++runs)
        callbacks[source] = callback
        connectSource(source)
    }

    onNewData: (source, data) => {
        disconnectSource(source)
        var callback = callbacks[source]
        delete callbacks[source]
        callback(data['exit code'], data.stdout, data.stderr)
    }
}
