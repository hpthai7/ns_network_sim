#create simulator
set sim [new Simulator]

set tr_events [open tcp_trace_events.tr w]
set tr_nam [open tcp_trace_nam.nam w]

#create trace files
$sim trace-all $tr_events
$sim namtrace-all $tr_nam

# create two nodes
set Node1 [$sim node]
set Node2 [$sim node]

#create a link between two nodes
$sim duplex-link $Node1 $Node2 1Mb 5ms DropTail

#create a CBR traffic source and attach it to udp0
#set cbr [new Application/Traffic/CBR]
#$cbr set packetSize_ 1000
#$cbr set interval_ 0.005

##create sender agent
set tcp [new Agent/TCP]         		
# set IP-layer flow ID
$tcp set fid_ 2
# create receiver agent
set sink [new Agent/TCPSink]
# put sender on node $n0
$sim attach-agent $Node1 $tcp
# put receiver on node $n3
$sim attach-agent $Node2 $sink
# establish TCP connection
$sim connect $tcp $sink

# create an FTP source "application"
set ftp [new Application/FTP]
# associate FTP with the TCP sender
$ftp attach-agent $tcp
#arrange for FTP to start at time 1.2 sec
$sim at 1.2 "$ftp start"
$sim at 10 "$ftp stop"

proc finish {} {
    global sim tr_events
    $sim flush-trace
    close $tr_events
    exit 0
}

$sim at 10.1 "finish"

$sim run
