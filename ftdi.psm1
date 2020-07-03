# -----------------------------------------------------------------------------
# Script: ftdi.psm1
# Author: y.brengel
# Date: 05/22/2020 16:33:28
# Keywords: Scripting Techniques
# comments: 
# PowerShell 5.0
#
# -----------------------------------------------------------------------------

# init com
function ftdi_init_com {

  $FtdiDllPath = $PSScriptRoot + "\FTD2XX_NET_v1.1.0\FTD2XX_NET.dll"
  if ( Test-Path( $FtdiDllPath ) ) { [void][Reflection.Assembly]::LoadFile( $FtdiDllPath ) }
  else { status( "`nERROR: Unable to load $FtdiDllPath" ) }
  $objectFTDI = New-Object FTD2XX_NET.FTDI

  # rescan
  $status = $objectFTDI.Rescan()
  Write-Host "Rescan " ,$status

  $num_dev = 0
  $status = $objectFTDI.GetNumberOfDevices( [ref]$num_dev )
  if ( $status -ne "FT_OK" ) { write-host "ERROR: GetNumberOfDevices()", $status }
  else {write-host "GetNumberOfDevices =" ,  $num_dev }

  $devicelist = [FTD2XX_NET.FTDI+FT_DEVICE_INFO_NODE[]]::new($num_dev)
  $status = $objectFTDI.GetDeviceList($devicelist)
  # search FTDI device ,example TTL232R-3V3
  $index = 0
  Do {
    $name = $devicelist[$index].Description
    $index++
  }
  Until ($name -eq "TTL232R-3V3")

  # open follow index
  $status = $objectFTDI.OpenByIndex($index-1)
  if ( $status -ne "FT_OK" ) { write-host "ERROR: OpenByIndex()", $status }
  else {write-host "OpenByIndex      =" , $status} 

  # reset device
  $status = $objectFTDI.ResetDevice()
  Write-Host "ResetDevice " ,$status

  $status = $objectFTDI.SetBaudRate( 115200 ); # Set Serial Baud
  if ( $status -ne "FT_OK" ) { write-host "ERROR: SetBaudRate()", $status }
  else {write-host "SetBaudRate      =" , $status}   

  $flowctl = [FTD2XX_NET.FTDI+FT_FLOW_CONTROL]::FT_FLOW_NONE
  $status = $objectFTDI.SetFlowControl($flowctl,0,0)
  if ( $status -ne "FT_OK" ) { write-host "ERROR: SetFlowControl()", $status }
  else {write-host "SetFlowControl =" , $status}

  $data    = [FTD2XX_NET.FTDI+FT_DATA_BITS]::FT_BITS_8
  $parity  = [FTD2XX_NET.FTDI+FT_PARITY]::FT_PARITY_EVEN
  $stopbit = [FTD2XX_NET.FTDI+FT_STOP_BITS]::FT_STOP_BITS_2
  $status = $objectFTDI.SetDataCharacteristics($data,$parity,$stopbit)
  if ( $status -ne "FT_OK" ) { write-host "ERROR: SetDataCharacteristics()", $status }
  else {write-host "SetDataCharacteristics =" , $status}

return $objectFTDI

}



# example to send message in COM with response
function com_write()
{
  param (
    [Parameter(Mandatory=$true, Position=0)]
    [Object[]] $objectFTDI,
    [Parameter(Mandatory=$true, Position=1)]
    [Byte []] $message
  )
  # purge buffer
  $purge_tx = [FTD2XX_NET.FTDI+FT_PURGE]::FT_PURGE_TX
  $status = $objectFTDI.Purge($purge_tx)
  $purge_rx = [FTD2XX_NET.FTDI+FT_PURGE]::FT_PURGE_RX
  $status = $objectFTDI.Purge($purge_rx)

  # time out wait in ms
  $status = $objectFTDI.SetTimeouts(100,100)

  # write
  $bytes_written = 0
  $response = @()
  $status = $objectFTDI.Write( $message, $message.Length, [ref] $bytes_written)

  $bytes_to_rd = 0
  $bytes_read  = 0
  Start-Sleep -Milliseconds 10
  $status = $objectFTDI.GetRxBytesAvailable( [ref] $bytes_to_rd)

  
  $status = $objectFTDI.Read([ref]$response, $bytes_to_rd,[ref]$bytes_read)
  write-host "com write ",$status,$bytes_read,$response

  return $response
}



# export function
Export-ModuleMember -Function ftdi_init_com
Export-ModuleMember -Function com_write
