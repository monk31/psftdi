# -----------------------------------------------------------------------------
# Script: ngoc.ps1
# Author: y.brengel
# Date: 05/22/2020 16:33:28
# Keywords: Scripting Techniques
# comments: 
# PowerShell 5.0
#
# -----------------------------------------------------------------------------
#---Requires -Modules ngoc
Import-Module './ftdi.psm1' -Force
################################################################################
#  init
Clear-Host
$handle = ftdi_init_com


###############################################################################
$status =  $handle.Close()
write-host "Close()", $status