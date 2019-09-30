function Get-PSClassCyclicErrorMessage
{
    param (
        [Parameter(Mandatory=$true)]
        [string[]]
        $Links
    )

    # get middle length
    $length = [int](($Links | Measure-Object -Property Length -Minimum).Minimum * 0.5) - 1
    $space = [string]::new(' ', $length)

    # build the separator
    $separator = "`n$($space)$(@('|', 'V') -join "`n$($space)")`n"

    # build and return the sting
    return ($Links -join $separator)
}