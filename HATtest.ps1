############################################### Testing HAT AREA ##################################################################
####This test will run a functional test against Prod or DR HAT A or B based off what was used in $args[0] & $args[1]
####It will display the output and pipe it to \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\$Server-$AorB-Test.txt
# USEAGE: PS > HATtest.ps1 DRorPROD AorBConfig 
# EXAMPLE: HATtest.ps1 PROD A 
CLS
#######ARGS VARS######
# $env is Serverlist
$env = $args[0]
# $AorB is the A or B Config of hat to test
$AorB = $args[1]

##### TESTING PROD-A CONFIG #####
If (($args[0] + $args[1]) -eq "PRODA")
{
Write-host -foregroundcolor Magenta "Testing CHEXAIRHAT101 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.159/HatService.svc dsarver@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\CHEXAIRHAT101-A-Test.txt

Write-host -foregroundcolor Magenta "Testing CHEXAIRHAT102 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.160/HatService.svc dsarver@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\CHEXAIRHAT102-A-Test.txt

Write-host -foregroundcolor Magenta "Testing CHEXAIRHAT103 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.161/HatService.svc dsarver@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\CHEXAIRHAT103-A-Test.txt

Write-host -foregroundcolor Magenta "Testing CHEXAIRHAT104 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.193/HatService.svc dsarver@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\CHEXAIRHAT104-A-Test.txt
}

##### TESTING PROD-B CONFIG #####
elseif (($args[0] + $args[1]) -eq "PRODB")
{
Write-host -foregroundcolor Yellow "Testing CHEXAIRHAT101 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.175/HatService.svc dsarver@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\CHEXAIRHAT101-B-Test.txt

Write-host -foregroundcolor Yellow "Testing CHEXAIRHAT102 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.181/HatService.svc dsarver@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\CHEXAIRHAT102-B-Test.txt

Write-host -foregroundcolor Yellow "Testing CHEXAIRHAT103 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.187/HatService.svc dsarver@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\CHEXAIRHAT103-B-Test.txt

Write-host -foregroundcolor Yellow "Testing CHEXAIRHAT104 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.199/HatService.svc dsarver@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\CHEXAIRHAT104-B-Test.txt
}

##### TESTING DR-A CONFIG #####
elseif (($args[0] + $args[1]) -eq "DRA")
{
Write-host -foregroundcolor Magenta "Testing PHEDAIRHAT101 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.58/HatService.svc dsarver@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\PHEDAIRHAT101-A-Test.txt

Write-host -foregroundcolor Magenta "Testing PHEDAIRHAT102 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.64/HatService.svc dsarver@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\PHEDAIRHAT102-A-Test.txt

Write-host -foregroundcolor Magenta "Testing PHEDAIRHAT103 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.70/HatService.svc dsarver@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\PHEDAIRHAT103-A-Test.txt

Write-host -foregroundcolor Magenta "Testing PHEDAIRHAT104 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.113/HatService.svc dsarver@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\PHEDAIRHAT104-A-Test.txt
}

##### TESTING DR-B CONFIG #####
elseif (($args[0] + $args[1]) -eq "DRB")
{
Write-host -foregroundcolor Yellow "Testing PHEDAIRHAT101 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.94/HatService.svc dsarver@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\PHEDAIRHAT101-B-Test.txt

Write-host -foregroundcolor Yellow "Testing PHEDAIRHAT102 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.100/HatService.svc dsarver@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\PHEDAIRHAT102-B-Test.txt

Write-host -foregroundcolor Yellow "Testing PHEDAIRHAT103 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.106/HatService.svc dsarver@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\PHEDAIRHAT103-B-Test.txt

Write-host -foregroundcolor Yellow "Testing PHEDAIRHAT104 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.119/HatService.svc dsarver@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\chc-filidx\Public\T2Ops\AirTest\AirHAT\PHEDAIRHAT104-B-Test.txt
}
############################################### END Testing AREA ##################################################################
