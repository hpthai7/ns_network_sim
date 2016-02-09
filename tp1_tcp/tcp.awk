BEGIN {
    FS = " ";
    nReceived = 0;
    nTotal = 0;
    delayOutput = "tcp_time_delay.txt";
    bitrateOutput = "tcp_time_bitrate.txt";
}
$5 == "tcp" {
    if ($1 == "+") {
        if ($12 == 0) {
            startTime = $2;
        }
        nTotal++;
        enqueueTime[$12] = $2 - startTime;
        packetSize[$12] = $6;
    }
    if ($1 == "-") {
        dequeueTime[$12] = $2 - startTime;
    }
    if ($1 == "r") {
        nReceiveds[$12] = ++nReceived;
        receiveTime[$12] = $2 - startTime;
        delay[$12] = receiveTime[$12] - enqueueTime[$12];
    }
}
END {
    averageBitrate = 0;
    for (i = 0; i < nTotal; i++) {
        # export to file, enqueue time to delay
        if (i in delay) {
            printf(enqueueTime[i] " " delay[i] "\n") > delayOutput;
        }

        # export to file, time to bitrate
        if (i in receiveTime) {
            bitrate[i] = 8*packetSize[i]*nReceiveds[i] / receiveTime[i];
            averageBitrate = bitrate[i];
            printf(receiveTime[i] " " bitrate[i] "\n") > bitrateOutput;
        }
    }
    print "nReceived = " nReceived ", nTotal = " nTotal ", packetSize[5] = " packetSize[5] "\n";

    average_delay = getAverageDelay(delay, nTotal);
    print "Valeur moyenne de delai  = " average_delay " s";

    # average bitrate should be the last calculated bitrate
    print "Valeur moyenne de debit  = " averageBitrate " bps";
}

function getAverageDelay(arr, max_size) {
    j = 0;
    total_delay = 0;
    for (i = 0; i < max_size; i++) {
        if (i in arr) {
            j++;
            total_delay += arr[i];
        }
    }
    if (j == 0) {
        return 0;
    }
    return total_delay / j;
}