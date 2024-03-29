# /*******************************************************************************
# Copyright (c) 2018, Xilinx, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
#
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software
# without specific prior written permission.
#
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# *******************************************************************************/

if { $::argc < 3 } {
    puts "ERROR: Program \"$::argv0\" requires 3 arguments! The rest are optional.\n"
    puts "Usage: $::argv0 <xoname> <target> <device> [<path_to_hdl> [<kerneltcl> [<kernelxml>]]]\n"
    exit
}

set xoname    [lindex $::argv 0]
set target    [lindex $::argv 1]
set device    [lindex $::argv 2]

if { $::argc > 4 } {
    set path_to_hdl [lindex $::argv 3]
} else {
    set path_to_hdl "./src/IP"
}
if { $::argc > 4 } {
    set kerneltcl [lindex $::argv 4]
} else {
    set kerneltcl "./src/scripts/package_kernel.tcl"
}
if { $::argc > 5 } {
    set kernelxml [lindex $::argv 5]
} else {
    set kernelxml "./src/xml/kernel.xml"
}

set suffix "hastip_${target}_${device}"

if {[file exists "${xoname}"]} {
    file delete -force "${xoname}"
}

source -notrace "${kerneltcl}"
package_xo -xo_path ${xoname} -kernel_name hastip -ip_directory ./packaged_kernel_${suffix} -kernel_xml "${kernelxml}"
