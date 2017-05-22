
For R18:
These are the values it should be 30 mins PRIOR to Gateway shunts
[HKEY_LOCAL_MACHINE\SOFTWARE\Expedia\TravelServer\NotSP\NewTrade]
"NewTradeGlobalSetting"=dword:off
"SpoofNewTradeCalls"=dword:00000001
"ApplyNow"=dword:00000001

For a normal pause:
[HKEY_LOCAL_MACHINE\SOFTWARE\Expedia\TravelServer\NotSP\NewTrade]
"NewTradeGlobalSetting"=dword:pause
"ApplyNow"=dword:00000001