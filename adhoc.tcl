# ======================================================================
# Define options
# ======================================================================
set val(rp)           AODV                     ;# ad-hoc routing protocol 
set val(ll)           LL                       ;# Link layer type
set val(mac)          Mac/802_11Ext            ;# MAC type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(ifq)          Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(netif)        Phy/WirelessPhy          ;# network interface type
set val(nn)           7                        ;# number of mobilenodes
set val(chan)         Channel/WirelessChannel  ;# channel type

#create simulator
set simadhoc [new Simulator]

set tr_events [open adhoc_trace_events.tr w]
set tr_nam [open adhoc_trace_nam.nam w]

#create trace files
$simadhoc trace-all $tr_events
$simadhoc namtrace-all $tr_nam

#create plane of size 1000x1000 (m)
set val(x) 1000
set val(y) 1000
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)


set god_ [create-god $nn]

#configure nodes
$simadhocadhoc node-config -adhocRouting $val(rp) \
                 -llType $val(ll) \
                 -macType $val(mac) \
                 -ifqType $val(ifq) \
                 -ifqLen $val(ifqlen) \
                 -antType $val(ant) \
                 -propType $val(prop) \
                 -phyType $val(netif) \
                 -channelType $val(chan) \
                 -topoInstance $topo \
                 -agentTrace ON \
                 -routerTrace ON \
                 -macTrace OFF \
                 -phyTrace ON \
#                -movementTrace OFF

# nn = 7
for {set i 0} {$i < $val(nn) } {incr i} {
    set Node($i) [$simadhocadhoc node ]
    $Node($i) random-motion 0; # disable random motion
}

$ns duplex-link $Node5 $Node4 1Mb 10ms DropTail
$ns duplex-link $Node4 $Node0 1Mb 10ms DropTail
$ns duplex-link $Node0 $Node2 1Mb 10ms DropTail

$ns duplex-link $Node1 $Node0 1Mb 10ms DropTail
$ns duplex-link $Node0 $Node3 1Mb 10ms DropTail
$ns duplex-link $Node3 $Node6 1Mb 10ms DropTail

#CBR/UDP
#create a CBR traffic source and attach it to udp0
set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 1000
$cbr set interval_ 0.005

#create a UDP agent and attach it to node n0
set udp1 [new Agent/UDP]
$simadhoc attach-agent $Node1 $udp1
set null1 [new Agent/Null]
$simadhoc attach-agent $Node6 $null2
$simadhoc connect $udp1 $null1
$cbr attach-agent $udp1

set udp2 [new Agent/UDP]
$simadhoc attach-agent $Node5 $udp2
set null2 [new Agent/Null]
$simadhoc attach-agent $Node2 $null2
$simadhoc connect $udp2 $null2
$cbr attach-agent $udp2

$simadhoc at 1.0 "$cbr start"
$simadhoc at 10.0 "$cbr stop"

proc finish {} {
    global simadhoc tr_events
    $simadhoc flush-trace
    close $tr_events
    exit 0
}

$simadhoc at 10.1 "finish"

$simadhoc run

