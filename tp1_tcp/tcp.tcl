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

# when the link has higher capacity
# $sim duplex-link $Node1 $Node2 2Mb 10ms DropTail

#when the link has longer distance
# $sim duplex-link $Node1 $Node2 2Mb 100ms DropTail

# queue parameters: 20 packets
$sim queue-limit $Node1 $Node2 20

# when the system is overbuffered
# $sim queue-limit $Node1 $Node2 50

# when the system is underbuffered
# $sim queue-limit $Node1 $Node2 5

##create sender agent
set tcp [new Agent/TCP/Reno]         		

# when we have an small packet size
$tcp set packetSize_ 1000

# when we have an large packet size
# $tcp set packetSize_ 4000

# when changing some internal parameters
# $tcp set window_ 50
# $tcp set windowInit_ 4
# $tcp set increase_num_ 2.0
# $tcp set decrease_num_ 0.7
# $tcp set decrease_num_ 0.9
# $tcp set decrease_num_ 1.0
# $tcp set decrease_num_ 1.2

# create receiver agent
set sink [new Agent/TCPSink]
# put sender on node $Node1
$sim attach-agent $Node1 $tcp
# put receiver on node $Node2
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
