<#
.SYNOPSIS
	Gets the Astronomy Picture of the Day and sets it as your wallpaper.
.DESCRIPTION
 	Get-Apod parses the Astronomy Picture of the Day website and downloads the current day's image. It then sets the image as the desktop wallpaper for the system.
.LINK
	http://antwrp.gsfc.nasa.gov/apod/astropix.html
.EXAMPLE
	C:PS> Get-Apod.ps1
	
	This example downloads the image and sets it as the desktop wallpaper.
.EXAMPLE
	c:PS> Get-Apod.ps1 C:\Images
	
	This example also downloads the image and sets it as the desktop wallpaper, but it allows you to choose the folder to download the pictures to. 
.PARAMETER Folder
	The folder were you want to download the pictures to.
.NOTES
  Name:         Get-APOD.ps1
  Author:       Mark E. Schill
  Date Created: 12/24/2008
  Date Revised: 01/17/2010
  Version:      1.1
  History:      1.1 01/17/2010 - Updated Help information
  				1.0 12/24/2008 - Initial Revision
  
  #requires -Version 2.0
  ** Licensed under a Creative Commons Attribution 3.0 License ** 
#>
[CmdletBinding(SupportsShouldProcess=$False)]
param
(
[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$false)]
[String]$Folder = ((Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" -Name "My Pictures")."My Pictures" )
)

add-type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper
{
   public enum Style : int
   {
       Tiled, Centered, Stretched, Fit
   }


   public class Setter {
      public const int SetDesktopWallpaper = 20;
      public const int UpdateIniFile = 0x01;
      public const int SendWinIniChange = 0x02;

      [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
      private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
      
      public static void SetWallpaper ( string path, Wallpaper.Style style ) {
         SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
         
         RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
         switch( style )
         {
             case Style.Stretched :
                 key.SetValue(@"WallpaperStyle", "2") ; 
                 key.SetValue(@"TileWallpaper", "0") ;
                 break;
             case Style.Centered :
                 key.SetValue(@"WallpaperStyle", "1") ; 
                 key.SetValue(@"TileWallpaper", "0") ; 
                 break;
             case Style.Tiled :
                 key.SetValue(@"WallpaperStyle", "1") ; 
                 key.SetValue(@"TileWallpaper", "1") ;
                 break;
             case Style.Fit :
                 key.SetValue(@"WallpaperStyle", "6") ; 
                 key.SetValue(@"TileWallpaper", "0") ;
                 break;
         }
         key.Close();
      }
   }
}
"@ 

if ( ! (Test-Path -path "$Folder\APODImages")) { mkdir $Folder\APODImages | Out-Null }
$Web = New-Object System.Net.WebClient
$Page = $Web.DownloadString("http://antwrp.gsfc.nasa.gov/apod/astropix.html")
$Text = $Page.Replace("`n","")
$RegEx = [regex]'<a href="image/(?<URL>.*?)">'

$Text -match $RegEx | Out-Null
$URL = $Matches['URL']

$FileName = $Folder + "\APODImages\" + ($URL -split "/" | Select-Object -Last 1)
$Address = "http://antwrp.gsfc.nasa.gov/image/" + $URL
$Web.DownloadFile( $Address, $FileName )

[Wallpaper.Setter]::SetWallpaper( (Convert-Path $FileName), "Fit" )

$RegEx = [regex]'<b> Explanation: </b>(?<Text>.*?)<hr>'
$Text -match $Regex | Out-Null
$APODText = $Matches['Text']

# SIG # Begin signature block
# MIIQnAYJKoZIhvcNAQcCoIIQjTCCEIkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+XG80NiXEeCxqMHAbaF+onXu
# SV2ggg3RMIIGwzCCBaugAwIBAgICAJYwDQYJKoZIhvcNAQEFBQAwgYwxCzAJBgNV
# BAYTAklMMRYwFAYDVQQKEw1TdGFydENvbSBMdGQuMSswKQYDVQQLEyJTZWN1cmUg
# RGlnaXRhbCBDZXJ0aWZpY2F0ZSBTaWduaW5nMTgwNgYDVQQDEy9TdGFydENvbSBD
# bGFzcyAyIFByaW1hcnkgSW50ZXJtZWRpYXRlIE9iamVjdCBDQTAeFw0xMDAxMTYy
# MTMxNTVaFw0xMjAxMTgxMDU1MzZaMIHAMSAwHgYDVQQNExcxMjk1MzItNFBoT1Bq
# N1dRZVd4T2RaOTELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0dlb3JnaWExDzANBgNV
# BAcTBkR1bHV0aDEtMCsGA1UECxMkU3RhcnRDb20gVmVyaWZpZWQgQ2VydGlmaWNh
# dGUgTWVtYmVyMRQwEgYDVQQDEwtNYXJrIFNjaGlsbDEnMCUGCSqGSIb3DQEJARYY
# TWFyay5TY2hpbGxAY21zY2hpbGwubmV0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAyRfyMAfNacizoi0sN5/GWBClZpRAG9V9Sgvy+n+Hpak5JXIQBPH/
# INKyTNRriH8zyRuptwRhrTle0+IULgEZa1U3RpyaQ/mOYc3dJwvIcw/wqEisJPAm
# ZGfY+sMANnwLO4ZJsAFIsvXsqrbhmOoO+D7foB3RLiOoakoDELfR5BIonsoujOcF
# bftkjhtCaWpX65sJ/obK5A+fiEdSpWDqnm+QgG741zfCL+IKIrgQi2hPGuL0ukx5
# k7dr0xxf/ezU8dI41Ssdcadz1X4g4kPnNuddBU94ajgXgMvX0VVER/dyuoQuL323
# zTM8UYgw1tgbJEcMbHA+sqanBk/G4wVEvQIDAQABo4IC9zCCAvMwCQYDVR0TBAIw
# ADAOBgNVHQ8BAf8EBAMCB4AwOgYDVR0lAQH/BDAwLgYIKwYBBQUHAwMGCisGAQQB
# gjcCARUGCisGAQQBgjcCARYGCisGAQQBgjcKAw0wHQYDVR0OBBYEFATHxBovkt2Q
# OkyTZjEZxJODI/i4MB8GA1UdIwQYMBaAFNBOD0CZbLhLGW87KLjg44gHNKq3MIIB
# QgYDVR0gBIIBOTCCATUwggExBgsrBgEEAYG1NwECATCCASAwLgYIKwYBBQUHAgEW
# Imh0dHA6Ly93d3cuc3RhcnRzc2wuY29tL3BvbGljeS5wZGYwNAYIKwYBBQUHAgEW
# KGh0dHA6Ly93d3cuc3RhcnRzc2wuY29tL2ludGVybWVkaWF0ZS5wZGYwgbcGCCsG
# AQUFBwICMIGqMBQWDVN0YXJ0Q29tIEx0ZC4wAwIBARqBkUxpbWl0ZWQgTGlhYmls
# aXR5LCBzZWUgc2VjdGlvbiAqTGVnYWwgTGltaXRhdGlvbnMqIG9mIHRoZSBTdGFy
# dENvbSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSBQb2xpY3kgYXZhaWxhYmxlIGF0
# IGh0dHA6Ly93d3cuc3RhcnRzc2wuY29tL3BvbGljeS5wZGYwYwYDVR0fBFwwWjAr
# oCmgJ4YlaHR0cDovL3d3dy5zdGFydHNzbC5jb20vY3J0YzItY3JsLmNybDAroCmg
# J4YlaHR0cDovL2NybC5zdGFydHNzbC5jb20vY3J0YzItY3JsLmNybDCBiQYIKwYB
# BQUHAQEEfTB7MDcGCCsGAQUFBzABhitodHRwOi8vb2NzcC5zdGFydHNzbC5jb20v
# c3ViL2NsYXNzMi9jb2RlL2NhMEAGCCsGAQUFBzAChjRodHRwOi8vd3d3LnN0YXJ0
# c3NsLmNvbS9jZXJ0cy9zdWIuY2xhc3MyLmNvZGUuY2EuY3J0MCMGA1UdEgQcMBqG
# GGh0dHA6Ly93d3cuc3RhcnRzc2wuY29tLzANBgkqhkiG9w0BAQUFAAOCAQEAcu8P
# T2mlw3hedsFiiLj5pl9ix0gvwwztxaM9nug3fxzmmjlNtyxRSXHsyUX66eyZ2OZG
# //q2PT+lbZ/PBjWyYFM8Q1vh+1dFcKVBz6aOb356XS4NZR9Rjg7n4YXhoP1Ui074
# A85il9SJ5fZFzI04z20CsfU+3kslWWn2K9yL8ABjqk5avDHJ8FXEh48KAQFigh70
# hUwllY7CT2Vxk8lcuuC6yUAEu9PkkF5jgMVA2N0JmtmgX8gQBkSp6vPbAEbxXQ01
# c/ESTrfhhWmD84dJ8aZDo/x/KVqyyhFTk6NyDmcOAkvC3Kj3qMAz1l6cgQOVj4Kh
# gYCBagE3NHNI/982lzCCBwYwggTuoAMCAQICARUwDQYJKoZIhvcNAQEFBQAwfTEL
# MAkGA1UEBhMCSUwxFjAUBgNVBAoTDVN0YXJ0Q29tIEx0ZC4xKzApBgNVBAsTIlNl
# Y3VyZSBEaWdpdGFsIENlcnRpZmljYXRlIFNpZ25pbmcxKTAnBgNVBAMTIFN0YXJ0
# Q29tIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTA3MTAyNDIyMDE0NVoXDTEy
# MTAyNDIyMDE0NVowgYwxCzAJBgNVBAYTAklMMRYwFAYDVQQKEw1TdGFydENvbSBM
# dGQuMSswKQYDVQQLEyJTZWN1cmUgRGlnaXRhbCBDZXJ0aWZpY2F0ZSBTaWduaW5n
# MTgwNgYDVQQDEy9TdGFydENvbSBDbGFzcyAyIFByaW1hcnkgSW50ZXJtZWRpYXRl
# IE9iamVjdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMojiyI1
# HpqgGzydSdA/DJc4Fim6+H2JW0VY74Rw7X4RTekUMatD400MUYFs8BUDSiQnVOX7
# SqDOTeGEoyHemTWr3EmuvzHFZ4QwEJvvB9x1qA9N9DVTsW44A/yIdx2ld/8/defZ
# 578sUBHJEWX6SQdin5Omh6ltyZ0r0Xvl1WUrnw1Qnv77cRkhMCgmja7C3PaW6FKG
# CAt6Ms1qFE2eufnNB+KWkfHPHiv5gvdeJgaOjdHUOddv25EnWnmPWGkKRrVv4f1v
# xZG0EU97AqbbS1ZSI55LmOK/fs76oU6D48XHw2BH/lw/FRpAKpXvAGvIUPjNahnU
# IwMnvDs21blDsO8CAwEAAaOCAn8wggJ7MAwGA1UdEwQFMAMBAf8wCwYDVR0PBAQD
# AgEGMB0GA1UdDgQWBBTQTg9AmWy4SxlvOyi44OOIBzSqtzCBqAYDVR0jBIGgMIGd
# gBROC+8apEBbpRdphzDKNGhD0EGu8qGBgaR/MH0xCzAJBgNVBAYTAklMMRYwFAYD
# VQQKEw1TdGFydENvbSBMdGQuMSswKQYDVQQLEyJTZWN1cmUgRGlnaXRhbCBDZXJ0
# aWZpY2F0ZSBTaWduaW5nMSkwJwYDVQQDEyBTdGFydENvbSBDZXJ0aWZpY2F0aW9u
# IEF1dGhvcml0eYIBATAJBgNVHRIEAjAAMD0GCCsGAQUFBwEBBDEwLzAtBggrBgEF
# BQcwAoYhaHR0cDovL3d3dy5zdGFydHNzbC5jb20vc2ZzY2EuY3J0MGAGA1UdHwRZ
# MFcwLKAqoCiGJmh0dHA6Ly9jZXJ0LnN0YXJ0Y29tLm9yZy9zZnNjYS1jcmwuY3Js
# MCegJaAjhiFodHRwOi8vY3JsLnN0YXJ0c3NsLmNvbS9zZnNjYS5jcmwwgYIGA1Ud
# IAR7MHkwdwYLKwYBBAGBtTcBAQUwaDAvBggrBgEFBQcCARYjaHR0cDovL2NlcnQu
# c3RhcnRjb20ub3JnL3BvbGljeS5wZGYwNQYIKwYBBQUHAgEWKWh0dHA6Ly9jZXJ0
# LnN0YXJ0Y29tLm9yZy9pbnRlcm1lZGlhdGUucGRmMBEGCWCGSAGG+EIBAQQEAwIA
# ATBQBglghkgBhvhCAQ0EQxZBU3RhcnRDb20gQ2xhc3MgMiBQcmltYXJ5IEludGVy
# bWVkaWF0ZSBPYmplY3QgU2lnbmluZyBDZXJ0aWZpY2F0ZXMwDQYJKoZIhvcNAQEF
# BQADggIBAFCi0Jj0cEBwALZu7JaNNX17oDcaf4EyWN/miIYbPBqIPiMCLE++UNZC
# 7J531EH2xaZf1K5QdNhUEjmfuA59kvZe3sF0ISF8LbsCokINzXQ/bbgPDobt3mNX
# D5e3jmmOEKr6ko/Pjpe39GaeqkxokWcQr/2jTyG6dL96w/RnYRrT7yi0UtAqioLB
# 9p8HqL5OIX140UI6eTeT53wVtV9gwkk6po8HloZZXkNig4Pd1utU8OjOshiQBhtx
# p828GnRfQVFvPFnEbJzlhyLteO92zSgZ39TiscQENf91sCRmVieVMYQqQPsK/pfj
# Wxz+ceV2efMYYcbu1kO68CA4/Hf5RlPQOhGnl79zcMHGyKP2qLub/cvePpXgGKq/
# G2wTQBU19aU8UCcpX7Cq5AfBDiMfma5cGtFhN9gIMWioVgBoaPz4e3elF1Ep+W8N
# vrrL4XZFuJ6VKMQJN0YU9/p7qYtX4nODRu4kBvOD2dm20uWMTpmiCLCAMXJX9uRc
# LLFo4njMFdJPdZ5c1BQdR0DLhOk7qwGpEu7ZyCkyfmViQQ3blG3A9dPeF9/DrzDv
# /vh+UuOSot6/9d2E5tAFhjrzBZBABfC27hMnnCk2iTE4jUXwRjIJ6hgX6ojp88cU
# VTTsNoUkKdAfgvSI/6t++c94gCGAmylHf+UkhC3JpS5fgbjZJ1xNMYICNTCCAjEC
# AQEwgZMwgYwxCzAJBgNVBAYTAklMMRYwFAYDVQQKEw1TdGFydENvbSBMdGQuMSsw
# KQYDVQQLEyJTZWN1cmUgRGlnaXRhbCBDZXJ0aWZpY2F0ZSBTaWduaW5nMTgwNgYD
# VQQDEy9TdGFydENvbSBDbGFzcyAyIFByaW1hcnkgSW50ZXJtZWRpYXRlIE9iamVj
# dCBDQQICAJYwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAw
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARYwIwYJKoZIhvcNAQkEMRYEFIBSURg8jh7j6tgSUPUspK1aMN0NMA0G
# CSqGSIb3DQEBAQUABIIBABUAuvWkNzcvSxxVs4uBjHp5PlV1I/uSAELiYAIPfdjI
# ctHKls5XEPdcA9fKjHWE5hGDbwLcBIvQF7IKICsZ7zsYQI7QgKY9jkV/PbSX6BF0
# MueOQHVYJ3c+u0d+sbgv340kRnhAnMrLj8DSwUentrFFX59BoPoUECpN9lVDrGx3
# nYdm/SWp4/TbISDBplsjIO1iXKerq3cnSdddXyGf7pj00ZtWhLTCGXbdXIwFmLAa
# hBlH7EVhdQWGy2gbzXRUL00IuwQaYOBzeEF+VyRVgA/t8yX2xckDBIVpw68GHT9m
# iL54PtC22Wv0FA0AOxY5L5zPVdxIQ7HnQbQUrMlmaaM=
# SIG # End signature block