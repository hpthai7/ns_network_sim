# ======================================================================
# Define options
# ======================================================================
set val(rp)           AODV; #DSDV                     ;# ad-hoc routing protocol 
set val(ll)           LL                       ;# Link layer type
set val(mac)          Mac/802_11               ;# MAC type - TODO: study Mac/802_11Ext
set val(ifq)          Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(prop)         Propagation/TwoRayGround ;#FreeSpace; #Shadowing;# radio-propagation model
set val(netif)        Phy/WirelessPhy          ;# network interface type - TODO: study Phy/WirelessPhyExt
set val(chan)         Channel/WirelessChannel  ;# channel type
set val(nn)           7                        ;# number of mobilenodes
set val(endtime)      50                       ;# time of simulation end
set val(endtimeX)     50.1                     ;# extra time of simulation end
set val(x) 1000;
set val(y) 1000;

# Propagation/Shadowing set pathlossExp_ 2.0  ;# path loss exponent
# Propagation/Shadowing set std_db_ 4.0       ;# shadowing deviation (dB)
# Propagation/Shadowing set dist0_ 1.0        ;# reference distance (m)
# Propagation/Shadowing set seed_ 0           ;# seed for RNG

#create simulator
set simadhoc [new Simulator]
#Define different colors for data flows (for NAM)
$simadhoc color 1 Blue
$simadhoc color 2 Red

set tr_events [open adhoc_trace_events.tr w]
set tr_windowVsTime2 [open adhoc_win.tr w]
set tr_nam [open adhoc_trace_nam.nam w]

#create trace files
$simadhoc trace-all $tr_events
$simadhoc namtrace-all-wireless $tr_nam $val(x) $val(y)

#create plane of size 1000x1000 (m)
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)
set god_ [create-god $val(nn)]

#configure nodes
$simadhoc node-config -adhocRouting $val(rp) \
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
                 -macTrace ON \
                 -phyTrace ON \
                 -movementTrace ON

set size_ [new RandomVariable/Uniform];
$size_ set min_ 1;
$size_ set max_ 999;

for {set i 0} {$i < $val(nn) } {incr i} {
    puts $i;
    # set Y [expr round([$size_ value])];
    # set X [expr round([$size_ value])];
    set X [expr { floor(rand() * 1001) }];
    set Y [expr { floor(rand() * 1001) }];
    set node_($i) [$simadhoc node];
    $node_($i) set X_ $X;
    $node_($i) set Y_ $Y;
    $node_($i) set Z_ 0.0;
}

#CBR/UDP
#create a UDP agent and attach it to node_(1)
set udp [new Agent/UDP]
$simadhoc attach-agent $node_(1) $udp
#create and attach null agent to node_(6)
set null [new Agent/Null]
$simadhoc attach-agent $node_(6) $null
$simadhoc connect $udp $null
$udp set fid_ 1
#create a CBR traffic source and attach it to udp
set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 1000
$cbr set interval_ 0.005
$cbr attach-agent $udp

#FTP/TCP
set tcp [new Agent/TCP]; #create TCP sender agent
set sink [new Agent/TCPSink]; #create receiver agent
$simadhoc attach-agent $node_(5) $tcp; #put sender on node_(5)
$simadhoc attach-agent $node_(2) $sink; #put receiver on node_(2)
$simadhoc connect $tcp $sink; #establish TCP connection
$tcp set fid_ 2
$tcp set type_ FTP

set ftp [new Application/FTP]; #create FTP source application
$ftp attach-agent $tcp; #associate FTP with the TCP sender

$simadhoc at 1.0 "$cbr start"
$simadhoc at $val(endtime) "$cbr stop"

$simadhoc at 1 "$ftp start"
$simadhoc at $val(endtime) "$ftp stop"

# Printing the window size
# proc plotWindow {tcpSource file} {
#     global simadhoc
#     set time 0.01
#     set now [$simadhoc now]
#     set cwnd [$tcpSource set cwnd_]
#     puts $file "$now $cwnd"
#     $simadhoc at [expr $now+$time] "plotWindow $tcpSource $file"
# }
# $simadhoc at $val(endtime) "plotWindow $tcp $tr_windowVsTime2"

# Define node initial position in nam
for {set i 0} {$i < $val(nn)} { incr i } {
    # 30 defines the node size for nam
    $simadhoc initial_node_pos $node_($i) 30
}

# Telling nodes when the simulation ends
for {set i 0} {$i < $val(nn) } { incr i } {
    $simadhoc at $val(endtime) "$node_($i) reset";
}

proc finish {} {
    global simadhoc tr_events tr_nam
    $simadhoc flush-trace
    close $tr_events
    close $tr_nam
    exit 0
}

# ending nam and the simulation
$simadhoc at $val(endtime) "$simadhoc nam-end-wireless $val(endtime)"
$simadhoc at $val(endtimeX) "finish"
$simadhoc at $val(endtimeX) "puts \"end simulation\" ; $simadhoc halt"

$simadhoc run