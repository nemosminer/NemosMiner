<#
Copyright (c) 2018-2022 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           ServerSide.psm1
Version:        4.2.2.0
Version date:   09 October 2022
#>

While ($true) { 
    $Response = @{}
    $Response.ContentType = "text/event-stream"
    $Response.Expires = -1
    $Response.Data = "The server time is: $(Get-Date())"
    $Response


    $Response.Headers.Add("Content-Type", $ContentType)
    $Response.StatusCode = $StatusCode
    $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($Data)
    $Response.ContentLength64 = $ResponseBuffer.Length
    $Response.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
    $Response.Close()

    Start-Sleep 1
}