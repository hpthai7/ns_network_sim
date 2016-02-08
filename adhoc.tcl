# ======================================================================
# Define options
# ======================================================================
set val(rp)           AODV                     ;# ad-hoc routing protocol 
set val(ll)           LL                       ;# Link layer type
set val(mac)          Mac/802_11               ;# MAC type - TODO: study Mac/802_11Ext
set val(ifq)          Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(netif)        Phy/WirelessPhy          ;# network interface type - TODO: study Phy/WirelessPhyExt
set val(chan)         Channel/WirelessChannel  ;# channel type
set val(nn)           3                        ;# number of mobilenodes
set val(stop)         50                       ;# time of simulation end
set val(x) 1000;
set val(y) 1000;
#create simulator
set simadhoc [new Simulator]

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

# Variable de random utilisée pour un point sur la grille
set size_ [new RandomVariable/Uniform]; # Variable Random uniforme
$size_ set min_ 1; # Valeur minimum
$size_ set max_ 999; # Valeur maximum

# nn = 7
for {set i 0} {$i < $val(nn) } {incr i} {
    puts $i;
    # set X [expr round([$size_ value])]; # Position X en random sur la grille
    # set Y [expr round([$size_ value])]; # Position Y en random sur la grille
    set node_($i) [$simadhoc node]
    # $node_($i) random-motion 0; # disable random motion
    # $node_($i) set X_ $X]; # Position X du nœud sur la grille
    # $node_($i) set Y_ $Y]; # Position Y du nœud sur la grille
    # $node_($i) set Z_ 0.0; # Position Z du nœud sur la grille
}

$node_(0) set X_ 50.0
$node_(0) set Y_ 200.0
$node_(0) set Z_ 0.0

$node_(1) set X_ 350.0
$node_(1) set Y_ 200.0
$node_(1) set Z_ 0.0

$node_(2) set X_ 150.0
$node_(2) set Y_ 230.0
$node_(2) set Z_ 0.0

# $simadhoc at 5.0 "$node_(0) setdest 250.0 250.0 3.0"
# $simadhoc at 12.0 "$node_(1) setdest 45.0 285.0 5.0"
# $simadhoc at 18.0 "$node_(0) setdest 480.0 300.0 5.0"


# $node_(3) set X_ 35.0;
# $node_(3) set Y_ 100.0;
# $node_(3) set Z_ 0.0;

# $node_(4) set X_ 50.0;
# $node_(4) set Y_ 20.0;
# $node_(4) set Z_ 0.0;

# $node_(5) set X_ 20.0;
# $node_(5) set Y_ 50.0;
# $node_(5) set Z_ 0.0;

# $node_(6) set X_ 45.0;
# $node_(6) set Y_ 10.0;
# $node_(6) set Z_ 0.0;

# #CBR/UDP
# #create a CBR traffic source and attach it to udp
# set cbr [new Application/Traffic/CBR]
# $cbr set packetSize_ 1000
# $cbr set interval_ 0.005

# #create a UDP agent and attach it to node_(1)
# set udp [new Agent/UDP]
# $simadhoc attach-agent $node_(0) $udp
# #create and attach null agent to node_(6)
# set null [new Agent/Null]
# $simadhoc attach-agent $node_(2) $null
# $simadhoc connect $udp $null

# $cbr attach-agent $udp

#FTP/TCP
set tcp [new Agent/TCP]; #create TCP sender agent
$tcp set class_ 2;
set sink [new Agent/TCPSink]; #create receiver agent
$simadhoc attach-agent $node_(0) $tcp; #put sender on node_(5)
$simadhoc attach-agent $node_(1) $sink; #put receiver on node_(2)
$simadhoc connect $tcp $sink; #establish TCP connection

set ftp [new Application/FTP]; #create FTP source application
$ftp attach-agent $tcp; #associate FTP with the TCP sender

# $simadhoc at 1.0 "$cbr start"
# $simadhoc at 10.0 "$cbr stop"

$simadhoc at 1 "$ftp start"
$simadhoc at $val(stop) "$ftp stop"

# Printing the window size
proc plotWindow {tcpSource file} {
    global simadhoc
    set time 0.01
    set now [$simadhoc now]
    set cwnd [$tcpSource set cwnd_]
    puts $file "$now $cwnd"
    $simadhoc at [expr $now+$time] "plotWindow $tcpSource $file"
}
$simadhoc at $val(stop) "plotWindow $tcp $tr_windowVsTime2"

# Define node initial position in nam
for {set i 0} {$i < $val(nn)} { incr i } {
    # 30 defines the node size for nam
    $simadhoc initial_node_pos $node_($i) 30
}

# Telling nodes when the simulation ends
for {set i 0} {$i < $val(nn) } { incr i } {
    $simadhoc at $val(stop) "$node_($i) reset";
}

# ending nam and the simulation
$simadhoc at $val(stop) "$simadhoc nam-end-wireless $val(stop)"
$simadhoc at $val(stop) "finish"
$simadhoc at $val(stop) "puts \"end simulation\" ; $simadhoc halt"

proc finish {} {
    global simadhoc tr_events tr_nam
    $simadhoc flush-trace
    close $tr_events
    close $tr_nam
    exit 0
}

# $simadhoc at 10.1 "finish"

$simadhoc run