BEGIN {
    FS = " ";
    tcpSrcNode = "_5_"
    tcpDestNode = "_2_"
    udpSrcNode = "_1_"
    udpDestNode = "_6_"
    nTcpTotal = 0;
    nTcpReceivTotal = 0;
    nCbrTotal = 0;
    nCbrReceivTotal = 0;
    nTotal;

    tcpDelayOutput = "tcp_time_delay.txt";
    tcpBitrateOutput = "tcp_time_bitrate.txt";
    udpDelayOutput = "udp_time_delay.txt";
    udpBitrateOutput = "udp_time_bitrate.txt";
}
NR > 0 {
    event = $1;
    id = $6;
    time = $2;
    packet = $7;
    packetSize = $8;
    nodeId = $3;
    layer = $4;

    if (packet == "tcp" && layer == "AGT") {
        if (event == "s" && nodeId == tcpSrcNode) {
            if (id == 0) {
                startTime = time;
            }
            nTotal++;
            nTcpTotal++;
            tcpSendTime[id] = time - startTime;
            tcpPacketSize[id] = packetSize;
        }
        if (event == "r" && nodeId == tcpDestNode) {
            nTcpReceiv[id] = ++nTcpReceivTotal;
            tcpReceiTime[id] = time - startTime;
            tcpDelay[id] = tcpReceiTime[id] - tcpSendTime[id];
        }
    }

    if (packet == "cbr") {
        if (event == "s" && layer == "AGT" && nodeId == udpSrcNode) {
            if (id == 0) {
                startTime = time;
            }
            nTotal++;
            nCbrTotal++;
            cbrSendTime[id] = time - startTime;
            cbrPacketSize[id] = packetSize;
        }
        if (event == "D") {
            cbrDropTime[id] = time - startTime;
            nCbrReceiv[id] = nCbrReceivTotal;
        }
        if (event == "r" && layer == "AGT" && nodeId = udpDestNode) {
            nCbrReceiv[id] = ++nCbrReceivTotal;
            cbrReceiTime[id] = time - startTime;
            cbrDelay[id] = cbrReceiTime[id] - cbrSendTime[id];
        }
    }
}
END {
    # TCP CONNECTION
    for (i = 0; i < nTotal; i++) {
        # export to file, tcpSendTime to tcpDelay
        if (i in tcpDelay) {
            printf(tcpSendTime[i] " " tcpDelay[i] "\n") > tcpDelayOutput;
        }
        # export to file, receivTime to bitrate
        if (i in tcpReceiTime) {
            tcpBitrate[i] = 8*tcpPacketSize[i]*nTcpReceiv[i] / tcpReceiTime[i];
            tcpAverageBitrate = tcpBitrate[i];
            printf(tcpReceiTime[i] " " tcpBitrate[i] "\n") > tcpBitrateOutput;
        }
    }

    print "TCP: nTcpReceivTotal = " nTcpReceivTotal ", nTcpTotal = " nTcpTotal;

    average_tcp_delay = getAverageDelay(tcpDelay, nTotal);
    print "TCP: valeur moyenne de delai  = " average_tcp_delay " s";

    # average bitrate should be the last calculated bitrate
    print "TCP: Valeur moyenne de debit  = " tcpAverageBitrate / 1000 / 1000 " Mbps\n";

    # UDP CONNECTION
    for (i = 0; i < nTotal; i++) {
        # export to file, cbrSendTime to cbrDelay
        if (i in cbrDelay) {
            printf(cbrSendTime[i] " " cbrDelay[i] "\n") > udpDelayOutput;
        }

        # export to file, time to cbrBitrate
        if (i in cbrReceiTime) {
            cbrBitrate[i] = 8*cbrPacketSize[i]*nCbrReceiv[i] / cbrReceiTime[i];
            udpAverageBitrate = cbrBitrate[i];
            printf(cbrReceiTime[i] " " cbrBitrate[i] "\n") > udpBitrateOutput;
        }
        if (i in cbrDropTime) {
            cbrBitrate[i] = 8*cbrPacketSize[i]*nCbrReceiv[i] / cbrDropTime[i];
            udpAverageBitrate = cbrBitrate[i];
            printf(cbrDropTime[i] " " cbrBitrate[i] "\n") > udpBitrateOutput;
        }
    }
    
    # average values
    Loss = 100 * (1 - nCbrReceivTotal / nCbrTotal);
    print "UDP: Taux de perte = " Loss " %";

    average_delay = getAverageDelay(cbrDelay, nTotal);
    print "UDP: valeur moyenne de delai  = " average_delay " s";

    # average bitrate should be the last calculated bitrate
    print "UDP: Valeur moyenne de debit  = " udpAverageBitrate / 1000 / 1000 " Mbps";
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