#
# Hastlayer auto frequency scaling Vivado TCL script
#

set set_rate_sh_fname ./xclbin/set_rate.sh

set clock_freq_topology_json_fname ./xclbin/clock_freq_topology.json

set open_run_impl_1 1

proc save_set_rate_sh { } {
  global wns_table
  global freq_org
  global freq_new
  global set_rate_sh_fname

  set fp [open $set_rate_sh_fname w] 

  puts $fp "#!/bin/bash"
  puts $fp "# The original frequency was $freq_org MHz"

  foreach {req slk} [array get wns_table] {
    puts $fp "# Requirement: $req ns, WNS: $slk ns"
  }

  puts $fp "# The new scaled frequency is $freq_new MHz"

  set freqHz [expr int($freq_new * 1e6)]
  set set_rate "echo $freqHz > /sys/devices/soc0/fclk0/set_rate"
  puts $fp $set_rate

  puts "INFO: \[HASTLAYER\] set_rate.sh file saved: $set_rate_sh_fname"
  
  close $fp    
}

proc save_clock_freq_topology_json { } {
  global freq_new
  global clock_freq_topology_json_fname

  set fp [open $clock_freq_topology_json_fname w] 

  puts $fp "{                                               "
  puts $fp "    \"clock_freq_topology\":                    "
  puts $fp "    {                                           "
  puts $fp "        \"m_count\": \"2\",                     "
  puts $fp "        \"m_clock_freq\":                       "
  puts $fp "        \[                                      "
  puts $fp "            {                                   "
  puts $fp "                \"m_freq_Mhz\": \"$freq_new\",  "
  puts $fp "                \"m_type\": \"DATA\",           "
  puts $fp "                \"m_name\": \"DATA_CLK\"        "
  puts $fp "            },                                  "
  puts $fp "            {                                   "
  puts $fp "                \"m_freq_Mhz\": \"$freq_new\",  "
  puts $fp "                \"m_type\": \"KERNEL\",         "
  puts $fp "                \"m_name\": \"KERNEL_CLK\"      "
  puts $fp "            }                                   "
  puts $fp "        \]                                      "
  puts $fp "    }                                           "
  puts $fp "}                                               "

  puts "INFO: \[HASTLAYER\] Clock topology file saved: $clock_freq_topology_json_fname"
  
  close $fp    
}

proc scale_frequency { } {
  global open_run_impl_1
  global wns_table
  global freq_org
  global freq_new
  
  puts "INFO: \[HASTLAYER\] Starting auto-frequency scaling ..."
  
  if [info exists open_run_impl_1] {
    open_run impl_1
  }  
  
  set kernel_clock clk_fpga_0
  set clock [get_clocks $kernel_clock]
  if {$clock ne $kernel_clock} {
    puts "INFO: \[HASTLAYER\] Kernel clock $kernel_clock not found!"
  }
  puts "INFO: \[HASTLAYER\] Kernel clock $kernel_clock OK"
  puts "INFO: \[HASTLAYER\] [list_property $clock]"
  # puts "INFO: \[HASTLAYER\] [list_property_value $clock]"
  set period [get_property PERIOD $clock]
  set freq_org [expr int(1000.0 / $period)]
  set freq_new $freq_org
  puts "INFO: \[HASTLAYER\] Kernel clock $kernel_clock period is $period"
  puts "INFO: \[HASTLAYER\] Kernel clock $kernel_clock frequency is $freq_org"
  set tps [get_timing_paths -max_paths 1000000 -setup -sort_by group -group $kernel_clock -slack_lesser_than 0.1]
  set i 1
  foreach tp $tps {
    if {$i eq 1} {
      puts "INFO: \[HASTLAYER\] [list_property $tp]"
    }
    set slk [get_property SLACK $tp]
    set grp [get_property GROUP $tp]
    set req [get_property REQUIREMENT $tp]
    set exc [get_property EXCEPTION_ID $tp]
    set real_slack [expr $slk * $period / $req]
    # puts "INFO: \[HASTLAYER\] i:$i, slk:$slk, req:$req, $real_slack"
    if [info exists wns_table($req)] {
      if {$wns_table($req) > $slk} { set wns_table($req) $slk }
    } else {
      set wns_table($req) $slk
    } 
    incr i
  }
  set real_wns 0
  foreach {req slk} [array get wns_table] {
    puts "INFO: \[HASTLAYER\] req:$req, slk:$slk"
    set real_slack [expr $slk * $period / $req]
    if {$real_wns > $real_slack} {
      set real_wns $real_slack
    }
  }
  puts "INFO: \[HASTLAYER\] real_wns:$real_wns"
  if {$real_wns < 0} {
    set freq_new [expr int(1000.0 / ($period - $real_wns))]
  }
  puts "INFO: \[HASTLAYER\] freq_new:$freq_new"
  puts "INFO: \[HASTLAYER\] Auto-frequency scaling completed"
}

# main

proc main { } {

  puts "INFO: \[HASTLAYER\] argc = $::argc"
  puts "INFO: \[HASTLAYER\] argv0 = [lindex $::argv 0]"
  puts "INFO: \[HASTLAYER\] argv1 = [lindex $::argv 1]"

  scale_frequency
  save_clock_freq_topology_json
  save_set_rate_sh
}

main
