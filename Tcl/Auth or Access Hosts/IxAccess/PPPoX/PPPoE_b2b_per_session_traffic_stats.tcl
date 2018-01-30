#################################################################################
# Version 1.1    $Revision: 2 $
# $Author: LRaicea $
#
#    Copyright � 1997 - 2008 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    07-04-2006 LRaicea - Created sample
#    06-11-2008 LRaicea - Updated keys for per session traffic stats
#
#################################################################################

################################################################################
#                                                                              #
#                                LEGAL  NOTICE:                                #
#                                ==============                                #
# The following code and documentation (hereinafter "the script") is an        #
# example script for demonstration purposes only.                              #
# The script is not a standard commercial product offered by Ixia and have     #
# been developed and is being provided for use only as indicated herein. The   #
# script [and all modifications, enhancements and updates thereto (whether     #
# made by Ixia and/or by the user and/or by a third party)] shall at all times #
# remain the property of Ixia.                                                 #
#                                                                              #
# Ixia does not warrant (i) that the functions contained in the script will    #
# meet the user's requirements or (ii) that the script will be without         #
# omissions or error-free.                                                     #
# THE SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, AND IXIA        #
# DISCLAIMS ALL WARRANTIES, EXPRESS, IMPLIED, STATUTORY OR OTHERWISE,          #
# INCLUDING BUT NOT LIMITED TO ANY WARRANTY OF MERCHANTABILITY AND FITNESS FOR #
# A PARTICULAR PURPOSE OR OF NON-INFRINGEMENT.                                 #
# THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SCRIPT  IS WITH THE #
# USER.                                                                        #
# IN NO EVENT SHALL IXIA BE LIABLE FOR ANY DAMAGES RESULTING FROM OR ARISING   #
# OUT OF THE USE OF, OR THE INABILITY TO USE THE SCRIPT OR ANY PART THEREOF,   #
# INCLUDING BUT NOT LIMITED TO ANY LOST PROFITS, LOST BUSINESS, LOST OR        #
# DAMAGED DATA OR SOFTWARE OR ANY INDIRECT, INCIDENTAL, PUNITIVE OR            #
# CONSEQUENTIAL DAMAGES, EVEN IF IXIA HAS BEEN ADVISED OF THE POSSIBILITY OF   #
# SUCH DAMAGES IN ADVANCE.                                                     #
# Ixia will not be required to provide any software maintenance or support     #
# services of any kind (e.g., any error corrections) in connection with the    #
# script or any part thereof. The user acknowledges that although Ixia may     #
# from time to time and in its sole discretion provide maintenance or support  #
# services for the script, any such services are subject to the warranty and   #
# damages limitations set forth herein and will not obligate Ixia to provide   #
# any additional maintenance or support services.                              #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
# Description:                                                                 #
#    This sample configures a PPPoE tunnel with 20 sessions between the        #
#    access and network ports. Traffic is configured with imix option and sent #
#    over the tunnel. After that a few statistics are being retrieved.         #
#    The sample should be run on 2 Ixia ports back to back.                    #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM1000STXS4 module.                            #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 4/1 4/3]
set sess_count 20
# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -reset                      \
        -device    $chassisIP       \
        -port_list $port_list       \
        -username  ixiaApiUser]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [list]
foreach port $port_list {
    if {![catch {keylget connect_status port_handle.$chassisIP.$port} \
                temp_port]} {
        lappend port_handle $temp_port
    }
}

set port_src_handle [lindex $port_handle 0]
set port_dst_handle [lindex $port_handle 1]

puts "Ixia port handles are $port_handle ..."
################################################################################
# Configure SRC interface in the test
################################################################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_src_handle     \
        -mode             config               \
        -speed            ether100             \
        -phy_mode         copper               \
        -autonegotiation  1                    ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

################################################################################
# Configure DST interface  in the test
################################################################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_dst_handle     \
        -mode             config               \
        -speed            ether100             \
        -phy_mode         copper               \
        -autonegotiation  1                    ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

################################################################################
# Configure sessions
################################################################################
set config_status [::ixia::pppox_config      \
        -port_handle      $port_src_handle   \
        -protocol         pppoe              \
        -encap            ethernet_ii        \
        -num_sessions     $sess_count        \
        -port_role           access                \
        -disconnect_rate  10                 \
        -redial                 1                        \
        -redial_max          10                    \
        -redial_timeout      20                    \
        -ip_cp            ipv4_cp            \
        -ppp_local_mode   peer_only          \
        -ppp_peer_mode    peer_only          \
        -attempt_rate     300                \
        -l4_flow_type     tcp_udp            \
        -l4_flow_variant  source             \
        -l4_src_port      2000               \
        -l4_dst_port      4000               \
        -l4_flow_number   1000               ]
if {[keylget config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status log]"
}
set pppox_handle [keylget config_status handle]
puts "Ixia pppox_handle is $pppox_handle ..."

set config_status2 [::ixia::pppox_config     \
        -port_handle      $port_dst_handle   \
        -protocol         pppoe              \
        -encap            ethernet_ii        \
        -num_sessions     $sess_count        \
        -port_role           network                  \
        -ip_cp            ipv4_cp            \
        -ppp_local_mode   local_may          \
        -ppp_local_ip     25.10.10.1         \
        -ppp_peer_mode    local_only         \
        -ppp_peer_ip      26.10.10.2         \
        -ppp_peer_ip_step 0.0.0.1            \
        -l4_flow_type     tcp_udp            \
        -l4_flow_variant  source             \
        -l4_src_port      2000               \
        -l4_dst_port      4000               \
        -l4_flow_number   1000               ]
if {[keylget config_status2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status2 log]"
}
set pppox_handle2 [keylget config_status2 handle]
puts "Ixia pppox_handle2 is $pppox_handle2 ..."

################################################################################
# Connect sessions
################################################################################
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle2        \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

puts "Sessions connected ..."

################################################################################
# Get PPPoE session aggregate statistics
################################################################################
set pppoe_attempts  0
set pppoe_sessions_up 0
while {($pppoe_attempts < 20) && ($pppoe_sessions_up < $sess_count)} {
    after 10000
    set pppox_status [::ixia::pppox_stats \
            -handle   $pppox_handle       \
            -mode     aggregate           ]
    
    if {[keylget pppox_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget pppox_status log]"
    }
    set  aggregate_stats   [keylget pppox_status aggregate]
    set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
    puts "pppoe_sessions_up=$pppoe_sessions_up"
    incr pppoe_attempts
}

if {$pppoe_sessions_up < $sess_count} {
    return "FAIL - $test_name - Not all sessions are up."
}


################################################################################
# Configure traffic
################################################################################
set traffic_status [::ixia::traffic_config      \
        -mode                 reset             \
        -port_handle          $port_src_handle  \
        -emulation_src_handle $pppox_handle     \
        ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

set traffic_status [::ixia::traffic_config      \
        -mode                 reset             \
        -port_handle          $port_dst_handle  \
        -emulation_src_handle $pppox_handle2    \
        ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}


set traffic_status [::ixia::traffic_config       \
        -mode                  create            \
        -bidirectional         1                 \
        -port_handle           $port_src_handle  \
        -port_handle2          $port_dst_handle  \
        -l3_protocol           ipv4              \
        -ip_src_mode           emulation         \
        -ip_src_count          $sess_count       \
        -emulation_src_handle  $pppox_handle     \
        -emulation_dst_handle  $pppox_handle2    \
        -ip_dst_mode           emulation         \
        -rate_percent          1                 \
        -duration              1                 \
        -mac_dst_mode          discovery         \
        -length_mode           imix              \
        -l3_imix1_size         128               \
        -l3_imix1_ratio        45                \
        -l3_imix2_size         256               \
        -l3_imix2_ratio        30                \
        -l3_imix3_size         512               \
        -l3_imix3_ratio        15                \
        -l3_imix4_size         1024              \
        -l3_imix4_ratio        10                \
        -session_traffic_stats 1                 \
        ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}
set stream_list [lsort -unique [concat \
        [keylget traffic_status stream_id.$port_src_handle] \
        [keylget traffic_status stream_id.$port_dst_handle]]]

################################################################################
# Start traffic
################################################################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      run                    ]

if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}


################################################################################
# Stop traffic
################################################################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      stop                   ]

if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

###############################################################################
#   Retrieve aggregate stats after traffic stopped
###############################################################################
set aggregate_stats [::ixia::traffic_stats \
        -port_handle $port_handle          ]
if {[keylget aggregate_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggregate_stats log]"
}

proc post_stats {port_handle label key_list stat_key {stream ""} {session ""}} {
    puts -nonewline [format "%-16s" $label]
    
    set second 0
    foreach port $port_handle {
        incr second
        if {$stream != ""} {
            set key $port.stream.$stream.$stat_key
        } else {
            set key $port.$stat_key
        }
        
        puts -nonewline "[format "%-16s" [keylget key_list $key]]"
        
        if {($session != "") && ($second == 2)} {
            puts -nonewline "[format "%-8s"  $session]"
        }
    }
    puts ""
}


puts "\n******************* TX/RX STATS **********************"
puts "\t\t$port_src_handle\t\t$port_dst_handle"
puts "\t\t-----\t\t-----"

post_stats $port_handle "Elapsed Time"   $aggregate_stats \
        aggregate.tx.elapsed_time
post_stats $port_handle "Packets Tx"     $aggregate_stats aggregate.tx.pkt_count
post_stats $port_handle "Raw Packets Tx" $aggregate_stats \
        aggregate.tx.raw_pkt_count
post_stats $port_handle "Bytes Tx"       $aggregate_stats \
        aggregate.tx.pkt_byte_count
post_stats $port_handle "Bits Tx"        $aggregate_stats \
        aggregate.tx.pkt_bit_count
post_stats $port_handle "Packets Rx"     $aggregate_stats aggregate.rx.pkt_count
post_stats $port_handle "Raw Packets Rx" $aggregate_stats \
        aggregate.rx.raw_pkt_count
post_stats $port_handle "Collisions"     $aggregate_stats \
        aggregate.rx.collisions_count
post_stats $port_handle "Dribble Errors" $aggregate_stats \
        aggregate.rx.dribble_errors_count
post_stats $port_handle "CRCs"           $aggregate_stats \
        aggregate.rx.crc_errors_count
post_stats $port_handle "Oversizes"      $aggregate_stats \
        aggregate.rx.oversize_count
post_stats $port_handle "Undersizes"     $aggregate_stats \
        aggregate.rx.undersize_count
post_stats $port_handle "RX PCKTS TOS0"  $aggregate_stats aggregate.rx.qos0_count
post_stats $port_handle "RX PCKTS TOS1"  $aggregate_stats aggregate.rx.qos1_count
post_stats $port_handle "RX PCKTS TOS2"  $aggregate_stats aggregate.rx.qos2_count
post_stats $port_handle "RX PCKTS TOS3"  $aggregate_stats aggregate.rx.qos3_count
post_stats $port_handle "RX PCKTS TOS4"  $aggregate_stats aggregate.rx.qos4_count
post_stats $port_handle "RX PCKTS TOS5"  $aggregate_stats aggregate.rx.qos5_count
post_stats $port_handle "RX PCKTS TOS6"  $aggregate_stats aggregate.rx.qos6_count
post_stats $port_handle "RX PCKTS TOS7"  $aggregate_stats aggregate.rx.qos7_count
puts "******************************************************\n"

###############################################################################
#   Retrieve per session stats after traffic stopped
###############################################################################
set session_stats [::ixia::traffic_stats   \
        -port_handle $port_handle        \
        -mode         session            ]
if {[keylget session_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget session_stats log]"
}

puts "\n******************* TX/RX PER SESSION STATS **********************"
puts "\t\t$port_src_handle\t\t$port_dst_handle\t\tSession"
puts "\t\t-----\t\t-----"

foreach {key} [keylkeys session_stats $port_src_handle.session.tx] {
    post_stats $port_handle "Packets Tx 128"     $session_stats \
            session.tx.$key.128.pkt_count "" $key
    
    post_stats $port_handle "Packets Rx 128"     $session_stats \
            session.rx.$key.128.pkt_count "" $key
    
    post_stats $port_handle "Min. Delay 128"     $session_stats \
            session.rx.$key.128.min_delay "" $key
    
    post_stats $port_handle "Avg. Delay 128"     $session_stats \
            session.rx.$key.128.avg_delay "" $key
    
    post_stats $port_handle "Max. Delay 128"     $session_stats \
            session.rx.$key.128.max_delay "" $key
    
    post_stats $port_handle "Packets Tx 256"     $session_stats \
            session.tx.$key.256.pkt_count "" $key
    
    post_stats $port_handle "Packets Rx 256"     $session_stats \
            session.rx.$key.256.pkt_count "" $key
    
    post_stats $port_handle "Min. Delay 256"     $session_stats \
            session.rx.$key.256.min_delay "" $key
    
    post_stats $port_handle "Avg. Delay 256"     $session_stats \
            session.rx.$key.256.avg_delay "" $key
    
    post_stats $port_handle "Max. Delay 256"     $session_stats \
            session.rx.$key.256.max_delay "" $key
    
    post_stats $port_handle "Packets Tx 512"     $session_stats \
            session.tx.$key.512.pkt_count "" $key
    
    post_stats $port_handle "Packets Rx 512"     $session_stats \
            session.rx.$key.512.pkt_count "" $key
    
    post_stats $port_handle "Min. Delay 512"     $session_stats \
            session.rx.$key.512.min_delay "" $key
    
    post_stats $port_handle "Avg. Delay 512"     $session_stats \
            session.rx.$key.512.avg_delay "" $key
    
    post_stats $port_handle "Max. Delay 512"     $session_stats \
            session.rx.$key.512.max_delay "" $key
    
    post_stats $port_handle "Packets Tx 1024"     $session_stats \
            session.tx.$key.1024.pkt_count "" $key
    
    post_stats $port_handle "Packets Rx 1024"     $session_stats \
            session.rx.$key.1024.pkt_count "" $key
    
    post_stats $port_handle "Min. Delay 1024"     $session_stats \
            session.rx.$key.1024.min_delay "" $key
    
    post_stats $port_handle "Avg. Delay 1024"     $session_stats \
            session.rx.$key.1024.avg_delay "" $key
    
    post_stats $port_handle "Max. Delay 1024"     $session_stats \
            session.rx.$key.1024.max_delay "" $key
    
}
puts "******************************************************\n"

if {0} {
    puts "Disconnecting sessions ... "
    set control_status [::ixia::pppox_control \
            -handle     $pppox_handle         \
            -action     disconnect            ]
    if {[keylget control_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget control_status log]"
    }
    
    set control_status [::ixia::pppox_control \
            -handle     $pppox_handle2        \
            -action     disconnect            ]
    if {[keylget control_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget control_status log]"
    }
    
    set cleanup_status [::ixia::cleanup_session ]
    
    if {[keylget cleanup_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget cleanup_status log]"
    }
    
}
return "SUCCESS - $test_name - [clock format [clock seconds]]"

