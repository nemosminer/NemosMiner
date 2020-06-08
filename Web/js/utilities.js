// fix bootstrap-table icons
window.icons = {
    refresh: 'fa-sync',
    toggle: 'fa-id-card',
    columns: 'fa-columns',
    clear: 'fa-trash'
};

function formatMiners(data) {
    // This function can alter the returned data before building the table, formatting it in a way
    // that is easier to display and manipulate in a table
    $.each(data, function(index, item) {
        // Format the device(s)
        item.tDevices = item.DeviceName.toString();

        // Format the algorithm(s)
        if (Array.isArray(item.Speed)) {
            item.tPrimaryAlgorithm = item.Algorithm[0];
            item.tSecondaryAlgorithm = item.Algorithm[1];
        } else {
            item.tPrimaryAlgorithm = item.Algorithm
        }

        // Format the speed(s)
        if (Array.isArray(item.Speed)) {
            item.tPrimarySpeed = item.Speed[0];
            item.tSecondarySpeed = item.Speed[1];
        } else {
            item.tPrimarySpeed = item.Speed;
        }

        // Format the live speed(s)
        if (Array.isArray(item.Speed)) {
            item.tPrimarySpeedLive = item.Speed_Live[0];
            item.tSecondarySpeedLive = item.Speed_Live[1];
        } else {
            item.tPrimarySpeedLive = item.Speed_Live;
        }

        // Get effective command line from argument json
        var arguments = new Object(item.Arguments);
        if (arguments.Commands) {
            item.Arguments = arguments.Commands;
        }

        // Format the reason(s)
        item.tReason = item.Reason.toString();

        // Format margin of error
        if (Array.isArray(item.Earning_Accuracy)) {
            item.tEarningAccuracy = formatPercent(item.Earning_Accuracy[0]);
            item.tEarningAccuracy = formatPercent(item.Earning_Accuracy[1]);
        } else {
            item.tEarningAccuracy = formatPercent(item.Earning_Accuracy)
        }

        // Format status
        const enumstatus = ["Running", "Idle", "Failed"];
        item.tStatus = enumstatus[item.Status];
    });
    return data;
}

function timeSince(date) {
    var seconds = Math.floor((new Date() - date) / 1000);
    var interval = Math.floor(seconds / 31536000);
    if (interval > 1) {
        return interval + ' years ago"';
    }
    interval = Math.floor(seconds / 2592000);
    if (interval > 1) {
        return interval + ' months ago';
    }
    interval = Math.floor(seconds / 86400);
    if (interval > 1) {
        return interval + ' days ago';
    }
    interval = Math.floor(seconds / 3600);
    if (interval > 1) {
         return interval + ' hours ago';
    }
    interval = Math.floor(seconds / 60);
    if (interval > 1) {
        return interval + ' minutes ago';
    }
    return Math.floor(seconds) + ' seconds ago';
}

function formatHashRateValue(value) {
    var sizes = ['H/s','kH/s','MH/s','GH/s','TH/s','PH/s','EH/s', 'ZH/s', 'YH/s'];
    if (isNaN(value)) return '-';
    if (value == "0.0") return '-';
    if (value > 0 && value <= 1) return value.toFixed(2) + ' H/s';
    var i = Math.floor(Math.log(value) / Math.log(1000));
    if (value >= 1) return parseFloat((value / Math.pow(1000, i)).toFixed(2)) + ' ' + sizes[i];
    return '-';
};

function formatHashRate(value) {
    if (Array.isArray(value)) {
        return value.map(formatHashRate).toString();
    } else {
        return formatHashRateValue(value);
    }
}
    
function formatBTC(value) {
        if (isNaN(value)) return '-';
        if (value > 0) return parseFloat(value * rate).toFixed(8);
        if (value == 0) return parseFloat(0).toFixed(8);
        if (value < 0) return parseFloat(value * rate).toFixed(8);
        return '-';
};

function formatDate(value) {
    return timeSince(new Date(value));
};

function formatWatt(value) {
    if (value > 0) return parseFloat(value).toFixed(2) + ' W';
    return '-';
};

function formatPercent(value) {
    if (isNaN(value)) return '-';
    return parseFloat(value * 100).toFixed(2) + ' %';
};

function formatPrices(value) {
    return (value * 1000000000).toFixed(10);
};

function formatArrayAsString(value) {
    return value.toString();
};

function formatMinerHashRatesAlgorithms(value) {
    return Object.keys(value).toString();
};

function formatMinerHashRatesValues(value) {
    hashrates = [];
    for (var property in value) {
        hashrates.push(formatHashRateValue(value[property]));
    }
    return hashrates.toString();
}

function detailFormatter(index, row) {
    var html = [];
    $.each(row, function (key, value) {
        html.push('<p class="mb-0"><b>' + key + ':</b> ' + JSON.stringify(value) + '</p>');
    });
    return html.join('');
}

function formatBytes(bytes) {
    if(bytes == null) return '-';
    if(bytes == 0) return '0 Bytes';
    decimals = 2
    var k = 1024,
    dm = decimals || 2,
    sizes = ['Bytes', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
    i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}
