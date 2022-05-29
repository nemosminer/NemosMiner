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
    // Format miner link
    if (item.MinerUri) item.tName = "<a href='" + item.MinerUri + "' target ='_blank'>" + item.Name + "</a>";
    else item.tName = item.Name;

    // Format the device(s)
    if (item.DeviceNames) item.tDevices = item.DeviceNames.toString();
    else item.tDevices = '';

    // Format the pool and algorithm data
    if (item.Workers.length > 0) {
      item.tPrimaryMinerFee = item.Workers[0].Fee;
      item.tPrimaryHashrate = item.Workers[0].Hashrate;
      if (item.Workers[0].Pool) {
        item.tPrimaryAlgorithm = item.Workers[0].Pool.Algorithm;
        item.tPrimaryPool = item.Workers[0].Pool.Name;
        item.tPrimaryPoolFee = item.Workers[0].Pool.Fee;
        item.tPrimaryPoolUser = item.Workers[0].Pool.User;
      }
      if (item.Workers.length > 1) {
        item.tSecondaryHashrate = item.Workers[1].Hashrate;
        item.tSecondaryMinerFee = item.Workers[1].Fee;
        if (item.Workers[1].Pool) {
          item.tSecondaryAlgorithm = item.Workers[1].Pool.Algorithm;
          item.tSecondaryPool = item.Workers[1].Pool.Name;
          item.tSecondaryPoolFee = item.Workers[1].Pool.Fee;
          item.tSecondaryPoolUser = item.Workers[1].Pool.User;
        }
      }
    }

    try {
      if (item.WorkersRunning.length > 0) {
        item.tPrimaryMinerFee = item.WorkersRunning[0].Fee;
        item.tPrimaryHashrate = item.WorkersRunning[0].Hashrate;
        if (item.WorkersRunning[0].Pool) {
          item.tPrimaryAlgorithm = item.WorkersRunning[0].Pool.Algorithm;
          item.tPrimaryPool = item.WorkersRunning[0].Pool.Name;
          item.tPrimaryPoolFee = item.WorkersRunning[0].Pool.Fee;
          item.tPrimaryPoolUser = item.WorkersRunning[0].Pool.User;
        }

        if (item.WorkersRunning.length > 1) {
          item.tSecondaryHashrate = item.WorkersRunning[1].Hashrate;
          item.tSecondaryMinerFee = item.WorkersRunning[1].Fee;
          if (item.WorkersRunning[1].Pool) {
            item.tSecondaryAlgorithm = item.WorkersRunning[1].Pool.Algorithm;
            item.tSecondaryPool = item.WorkersRunning[1].Pool.Name;
            item.tSecondaryPoolFee = item.WorkersRunning[1].Pool.Fee;
            item.tSecondaryPoolUser = item.WorkersRunning[1].Pool.User;
          }
        }
      }
    }
    catch (error) { }

    // Format margin of error
    item.tEarningAccuracy = formatPercent(item.Earning_Accuracy);

    // Format the live speed(s)
    if (item.Hashrates_Live) {
      if (item.Hashrates_Live.length > 0) item.tPrimaryHashrateLive = item.Hashrates_Live[0];
      if (item.Hashrates_Live.length > 1) item.tSecondaryHashrateLive = item.Hashrates_Live[1];
    }

    // Format Total Mining Duration (TimeSpan)
    item.tTotalMiningDuration = formatTimeSpan(item.TotalMiningDuration);

    // Format Mining Duration (TimeSpan)
    if (item.BeginTime == '') item.tMiningDuration = '';
    else item.tMiningDuration = formatTimeSince(item.BeginTime).replace(" ago", "").replace("just now", "");

    // Format status
    const enumstatus = ["Running", "Idle", "Failed", "Disabled"];
    item.tStatus = enumstatus[item.Status];
});
  return data;
}

function formatTimeSince(value) {
  var value = (new Date).getTime() - (new Date(value)).getTime();
  var localtime = new Date().getTime();
  var lastupdated = '';
  if (isNaN(value)) value = localtime - parseInt(kicked.replace("/Date(", "").replace(")/", ""));

  seconds = value / 1000;
  lastupdated = formatTime(seconds)

  if (lastupdated == '') return 'just now';
  else return lastupdated.trim() + ' ago';
}

function formatTime(seconds) {
  var formattedtime = "";

  interval = Math.floor(seconds / (24 * 3600));
  if (interval > 1) formattedtime = formattedtime + interval.toString() + ' days ';
  else if (interval == 1) formattedtime = formattedtime + interval.toString() + ' day ';

  if (interval > 0) seconds = seconds - interval * (24 * 3600);
  interval = Math.floor(seconds / 3600);
  if (interval > 1) formattedtime = formattedtime + interval.toString() + ' hours ';
  else if (interval == 1) formattedtime = formattedtime + interval.toString() + ' hour ';

  if (interval > 0) seconds = seconds - interval * 3600;
  interval = Math.floor(seconds / 60);
  if (interval > 1) formattedtime = formattedtime + interval.toString() + ' minutes ';
  else if (interval == 1) formattedtime = formattedtime + interval.toString() + ' minute ';

  if (interval > 0) seconds = seconds - interval * 60;
  interval = parseInt(seconds % 60);
  if (interval > 1) formattedtime = formattedtime + interval.toString() + ' seconds ';
  else if (interval == 1) formattedtime = formattedtime + interval.toString() + ' second ';

  return formattedtime.trim()
}

function formatHashrateValue(value) {
  if (value == null) return '';
  if (value === 0) return '0 H/s';
  if (value > 0) {
    var sizes = ['H/s', 'kH/s', 'MH/s', 'GH/s', 'TH/s', 'PH/s', 'EH/s', 'ZH/s', 'YH/s'];
    var i = Math.floor(Math.log(value) / Math.log(1000));
    unitvalue = value / Math.pow(1000, i);
    if (i <= 0) i = 1;
    if (unitvalue < 10) return unitvalue.toFixed(3) + ' ' + sizes[i];
    return unitvalue.toFixed(2) + ' ' + sizes[i];
  }
  return 'N/A';
};

function formatHashrate(value) {
  const values = value.split('<br/>')
  return values.map(formatHashrate).toString();
}

function formatmBTC(value) {
  if (value == null) return ''
  if (value > 0) return parseFloat(value * rate / 1000).toFixed(parseInt(rate).toString().length + 2);
  if (value == 0) return (0).toFixed(8);
  if (value < 0) return parseFloat(value * rate / 1000).toFixed(parseInt(rate).toString().length + 2);
  return 'N/A';
};

function formatBTC(value) {
  if (value == null) return ''
  if (value > 0) return parseFloat(value * rate).toFixed(parseInt(rate).toString().length + 2);
  if (value == 0) return (0).toFixed(8);
  if (value < 0) return parseFloat(value * rate).toFixed(parseInt(rate).toString().length + 2);
  return 'N/A';
};

function formatDate(value) {
  if (value === '') return "N/A";
  if (Date.parse(value)) return (new Date(value).toLocaleString(navigator.language));
  if (value == "Unknown") return "N/A";
  if (value == null) return "N/A";
  return value;
};

function formatWatt(value) {
  if (value == 0) return (0).toFixed(2) + ' W';
  if (value > 0) return parseFloat(value).toFixed(2) + ' W';
  return 'N/A';
};

function formatPercent(value) {
  if (value === 0) return '0.00 %';
  if (parseFloat(value)) return parseFloat(value * 100).toFixed(2) + ' %';
  return '';
};

function formatPrices(value) {
  if (value > 0) return (value * 1000000000).toFixed(10);
  return '';
};

function formatArrayAsString(value) {
  if (value === '') return ''
  if (value == null) return '';
  return value.sort().join('; <br>');
};

function formatDigits0(value) {
  if (value > 0) return (value).toFixed(0);
  return '';
};

function formatDigits1(value) {
  if (value > 0) return (value).toFixed(1);
  return '';
};

function formatDigits2(value) {
  if (value > 0) return (value).toFixed(2);
  return '';
};

function formatDigits3(value) {
  if (value > 0) return (value).toFixed(3);
  return '';
};

function formatDigits4(value) {
  if (value > 0) return (value).toFixed(4);
  return '';
};

function formatDigits5(value) {
  if (value > 0) return (value).toFixed(5);
  return '';
};

function formatDigits6(value) {
  if (value > 0) return (value).toFixed(6);
  return '';
};

function formatDigits7(value) {
  if (value > 0) return (value).toFixed(7);
  return '';
};

function formatDigits8(value) {
  if (value > 0) return (value).toFixed(8);
  return '';
};

function formatDigits9(value) {
  if (value > 0) return (value).toFixed(9);
  return '';
};

function formatDigits10(value) {
  if (value > 0) return (value).toFixed(10);
  return '';
};


function formatGBDigits0(value) {
  if (value > 0) return (value).toFixed(0) + " GB";
  return '';
};

function formatGBDigits1(value) {
  if (value > 0) return (value).toFixed(1) + " GB";
  return '';
};

function formatGBDigits2(value) {
  if (value > 0) return (value).toFixed(2) + " GB";
  return '';
};

function formatGBDigits3(value) {
  if (value > 0) return (value).toFixed(3) + " GB";
  return '';
};

function formatGBDigits4(value) {
  if (value > 0) return (value).toFixed(4) + " GB";
  return '';
};

function formatGBDigits5(value) {
  if (value > 0) return (value).toFixed(5) + " GB";
  return '';
};

function formatGBDigits6(value) {
  if (value > 0) return (value).toFixed(6) + " GB";
  return '';
};

function formatGBDigits7(value) {
  if (value > 0) return (value).toFixed(7) + " GB";
  return '';
};

function formatGBDigits8(value) {
  if (value > 0) return (value).toFixed(8) + " GB";
  return '';
};

function formatGBDigits9(value) {
  if (value > 0) return (value).toFixed(9) + " GB";
  return '';
};

function formatGBDigits10(value) {
  if (value > 0) return (value).toFixed(10) + " GB";
  return '';
};



function detailFormatter(index, row) {
  var html = [];
  $.each(row, function (key, value) {
    if (typeof value === 'string') html.push(`<p class="mb-0"><b>${key}:</b> ${JSON.stringify(value).replaceAll("\\\\", "\\")}</p>`);
    else html.push(`<p class="mb-0"><b>${key}:</b> ${JSON.stringify(value)}</p>`);
  });
  return html.join('');
}

function formatBytes(bytes) {
  if (bytes > 0) {
    decimals = 2;
    var k = 1024;
    dm = decimals || 2;
    sizes = ['Bytes', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }
  return '-';
}

function formatTimeSpan(timespan) {
  var duration = '-';
  if (timespan) {
    duration = timespan.Days + ' days ';
    duration = duration + timespan.Hours + ' hrs ';
    duration = duration + timespan.Minutes + ' min ';
    duration = duration + timespan.Seconds + ' sec ';
  }
  return duration;
}

function createUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}