<#
.SYNOPSIS
Lists subdomains based on certificate transparency logs
 
.DESCRIPTION
Lists subdomains based on certificate transparency logs

Can also list the certificate transparency logs of a given domain, and outputs in json or csv
 
.EXAMPLE
./Get-CertTransparencyLogs -domain example.com [-output csv|json] [-subdomains $FALSE]
 
 .EXAMPLE
./Get-CertTransparencyLogs -domain example.com -output csv
 
  
.NOTES
 
 
.LINK
 
#>
 
 
param(
        [string]$output="json",
        [boolean]$subdomains=$true,
        [Parameter(Mandatory)][string]$domain
)

# Couldn't get unique to work without writing to a file
$TempFile=New-TemporaryFile

# using crt.sh for the certificate data
$request="https://crt.sh/?q=$domain&output=$output"

# query crt.sh
$response=Invoke-RestMethod -Uri $request

if ($subdomains)
{
        # remove some non domain name responses, newlines, remove wildcard domains, remove email addresses
        $nameValues = $response | ForEach-Object { $_.name_value }
        $filtered = $nameValues | Where-Object { $_ -notlike "*CN=*" }
        $processed = $filtered | ForEach-Object { $_ -replace '\\n', "`n" }
        $processed = $processed | select-string -pattern '\*' -NotMatch
        $processed = $processed | select-string -pattern '@' -NotMatch
        
        # write to the temp file
        foreach ($line in $processed)
        {
                $line | add-content $TempFile
        }
        
        # read the temp file and sort it and get unique records
        $processed=get-content $TempFile | select-object -unique | sort
        $result=$processed
}
else
{
        $result=$response
}

remove-item $TempFile

write-output $result

