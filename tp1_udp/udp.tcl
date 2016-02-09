#create simulator
set sim [new Simulator]

set tr_events [open udp_trace_events.tr w]
set tr_nam [open udp_trace_nam.nam w]

#create trace files
$sim trace-all $tr_events
$sim namtrace-all $tr_nam

# create two nodes
set Node1 [$sim node]
set Node2 [$sim node]

#create a link between two nodes
$sim duplex-link $Node1 $Node2 1Mb 5ms DropTail

#create a CBR traffic source and attach it to udp0
set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 1000
$cbr set interval_ 0.005

#create a UDP agent and attach it to node n0
set udp [new Agent/UDP]
$sim attach-agent $Node1 $udp
set null [new Agent/Null]
$sim attach-agent $Node2 $null

$sim connect $udp $null

$cbr attach-agent $udp

$sim at 1.0 "$cbr start"
$sim at 10.0 "$cbr stop"

proc finish {} {
    global sim tr_events
    $sim flush-trace
    close $tr_events
    exit 0
}

$sim at 10.1 "finish"

$sim run

