#requires -version 2.0

# Highlight-Syntax.ps1
# version 2.0
# by Jeff Hillman
#
# this script uses the System.Management.Automation.PsParser class
# to highlight PowerShell syntax with HTML.

param( [string] $code, [switch] $LineNumbers )

if ( Test-Path $code -ErrorAction SilentlyContinue )
{
    $code = Get-Content $code | Out-String
}

$backgroundColor = "#DDDDDD"
$foregroundColor = "#000000"
$lineNumberColor = "#404040"

$PSTokenType = [System.Management.Automation.PSTokenType]

$colorHash = @{ 
#    $PSTokenType::Unknown            = $foregroundColor; 
    $PSTokenType::Command            = "#C86400";
#    $PSTokenType::CommandParameter   = $foregroundColor;
#    $PSTokenType::CommandArgument    = $foregroundColor;
    $PSTokenType::Number             = "#800000";
    $PSTokenType::String             = "#800000";
    $PSTokenType::Variable           = "#000080";
#    $PSTokenType::Member             = $foregroundColor;
#    $PSTokenType::LoopLabel          = $foregroundColor;
#    $PSTokenType::Attribute          = $foregroundColor;
    $PSTokenType::Type               = "#404040";
    $PSTokenType::Operator           = "#C86400";
#    $PSTokenType::GroupStart         = $foregroundColor;
#    $PSTokenType::GroupEnd           = $foregroundColor;
    $PSTokenType::Keyword            = "#C86400";
    $PSTokenType::Comment            = "#008000";
    $PSTokenType::StatementSeparator = "#C86400";
#    $PSTokenType::NewLine            = $foregroundColor;
    $PSTokenType::LineContinuation   = "#C86400";
#    $PSTokenType::Position           = $foregroundColor;
    
}

filter Html-Encode
{
    $_ = $_ -replace "&", "&amp;"
    $_ = $_ -replace " ", "&nbsp;"
    $_ = $_ -replace "<", "&lt;"
    $_ = $_ -replace ">", "&gt;"

    $_
}

# replace the tabs with spaces
$code = $code -replace "\t", ( " " * 4 )

if ( $LineNumbers )
{
    $highlightedCode = "<li style='color: $lineNumberColor; padding-left: 5px'>"
}
else
{
    $highlightedCode = ""
}

$parser = [System.Management.Automation.PsParser]
$lastColumn = 1
$lineCount = 1

foreach ( $token in $parser::Tokenize( $code, [ref] $null ) | Sort-Object StartLine, StartColumn )
{
    # get the color based on the type of the token
    $color = $colorHash[ $token.Type ]
    
    if ( $color -eq $null ) 
    { 
        $color = $foregroundColor
    }

    # add whitespace
    if ( $lastColumn -lt $token.StartColumn )
    {
        $highlightedCode += ( "&nbsp;" * ( $token.StartColumn - $lastColumn ) )
    }
    $lastColumn = $token.EndColumn
    switch ( $token.Type )
    {
        $PSTokenType::String {
            $string = "<span style='color: {0}'>{1}</span>" -f $color, 
                ( $code.SubString( $token.Start, $token.Length ) | Html-Encode )

            # we have to highlight each piece of multi-line strings
            if ( $string -match "\r\n" )
            {
                # highlight any line continuation characters as operators
                $string = $string -replace "(``)(?=\r\n)", 
                    ( "<span style='color: {0}'>``</span>" -f $colorHash[ $PSTokenType::Operator ] )

                $stringHtml = "</span><br />`r`n"
                
                if ( $LineNumbers )
                {
                     $stringHtml += "<li style='color: $lineNumberColor; padding-left: 5px'>"
                }

                $stringHtml += "<span style='color: $color'>"

                $string = $string -replace "\r\n", $stringHtml
            }

            $highlightedCode += $string
            break
        }

        $PSTokenType::NewLine {
            $highlightedCode += "<br />`r`n"
            
            if ( $LineNumbers )
            {
                $highlightedCode += "<li style='color: $lineNumberColor; padding-left: 5px'>"
            }
            
            $lastColumn = 1
            ++$lineCount
            break
        }

        default {
            if ( $token.Type -eq $PSTokenType::LineContinuation )
            {
                $lastColumn = 1
                ++$lineCount
            }

            $highlightedCode += "<span style='color: {0}'>{1}</span>" -f $color, 
                ( $code.SubString( $token.Start, $token.Length ) | Html-Encode )
        }
    }
    #$lastColumn = $token.EndColumn
}

# put the highlighted code in the pipeline
"<div style='width: 100%; " + 
            "/*height: 100%;*/ " +
            "overflow: auto; " +
            "font-family: Consolas, `"Courier New`", Courier, mono; " +
            "font-size: 12px; " +
            "background-color: $backgroundColor; " +
            "color: $foregroundColor; " + 
            "padding: 2px 2px 2px 2px; white-space: nowrap'>"

if ( $LineNumbers )
{
    $digitCount =  $lineCount.ToString().Length

    "<ol start='1' style='border-left: " +
                         "solid 1px $lineNumberColor; " +
                         "margin-left: $( ( $digitCount * 10 ) + 15 )px; " +
                         "padding: 0px;'>"
}

$highlightedCode

if ( $LineNumbers )
{
    "</ol>"
}

"</div>"