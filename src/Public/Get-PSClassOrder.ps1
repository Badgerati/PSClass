function Get-PSClassOrder
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = '.'
    )

    # build the graph
    $graph = New-PSClassGraph -RootPath $Path

    # test for cyclic dependency
    $graph.DetectCyclicDependency()

    # import the classes
    $graph.GetClassOrder()
}