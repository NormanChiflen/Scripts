for %%i in (
DNWBMTPA01
DNWBMTPA02
DNWBMTPA03
DNWBMTPA04
DNWBOTPA01
DNWBOTPA02
) do (c:\devtools\mdutil5 ENUM_ALL /dn%%i/w3svc >  \\expcpfs01\Releases\R18\Dumps\Meta_Dumps\Post\dn%%i_2_1011_metabase.txt)

