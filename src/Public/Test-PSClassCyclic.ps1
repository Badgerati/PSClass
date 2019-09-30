function Test-PSClassCyclic
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = '.',

        [Parameter()]
        [string]
        $Namespace
    )

    # build the graph
    $graph = New-PSClassGraph -RootPath $Path

    # test for cyclic dependency
    $graph.DetectCyclicDependency($Namespace)
}