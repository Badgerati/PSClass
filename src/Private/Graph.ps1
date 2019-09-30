function New-PSClassGraphModel
{
    $graph = (New-Object -TypeName PSObject -Property @{
        Classes = @{}
    })

    $graph | Add-Member -MemberType ScriptMethod -Name 'DetectCyclicDependency' -Value {
        param (
            [Parameter()]
            [string]
            $Namespace
        )

        $this.Classes.Values | Where-Object {
            [string]::IsNullOrWhiteSpace($Namespace) -or $_.Namespace -ieq $Namespace
        } | ForEach-Object {
            $class = $_

            # get all dependencies for the current class
            $dep = ($class.AllDependencies() | Where-Object { $_.Class.Namespace -ieq $class.Namespace })

            # if the list contains this class, error
            if ($null -ne $dep) {
                $message = Get-PSClassCyclicErrorMessage -Links ($dep.Links + $class.Namespace)
                throw "Cyclic dependency found on class '$($class.Path)':`n`n- - - - - - -`n$($message)`n- - - - - - -"
            }
        }
    }

    $graph | Add-Member -MemberType ScriptMethod -Name 'GetClassOrder' -Value {
        $order = @()

        do {
            # get first class where all dependencies are added
            $class = ($this.Classes.Values | Where-Object {
                !$_.Added -and (($_.DependentOn.Length -eq 0) -or @($_.DependentOn | Where-Object { !$_.Added }).Length -eq 0)
            } | Select-Object -First 1)

            # add the class
            Write-Verbose "Adding class: $($class.Namespace)"
            $order += $class.Path

            # flag as added
            $class.Added = $true

        } while (@($this.Classes.Values | Where-Object { !$_.Added }).Length -gt 0)

        return $order
    }

    $graph | Add-Member -MemberType ScriptMethod -Name 'ToString' -Force -Value {
        param (
            [Parameter()]
            [string]
            $Namespace
        )

        $this.Classes.Values | Where-Object {
            [string]::IsNullOrWhiteSpace($Namespace) -or $_.Namespace -ieq $Namespace
        } | ForEach-Object {
            Write-PSClassDependencyTree -Class $_ -Level 0
            Write-Host ([string]::Empty)
        }
    }

    return $graph
}

function Write-PSClassDependencyTree
{
    param (
        [Parameter(Mandatory=$true)]
        $Class,

        [Parameter(Mandatory=$true)]
        [int]
        $Level
    )

    $prefix = "$('   ' * $Level)| ->"
    Write-Host "$($prefix) $($Class.Namespace)"

    if ($Class.DependentOn.Length -eq 0) {
        return
    }

    $Class.DependentOn | ForEach-Object {
        Write-PSClassDependencyTree -Class $_ -Level ($Level + 1)
    }
}

function New-PSClassGraph
{
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $RootPath
    )

    # append class and test path
    $RootPath = (Join-Path (Resolve-Path $RootPath) 'Classes')
    if (!(Test-Path $RootPath)) {
        throw "The Classes directory path does not exist: $($RootPath)"
    }

    # intialise the graph
    $graph = New-PSClassGraphModel

    # get all classes, and build graph
    (Get-PSClassModels -RootPath $RootPath) | ForEach-Object {
        $graph.Classes[$_.Namespace] = $_
    }

    # regex for using
    $regex = '^\s*#\s*using\s+(class|enum)\s+(?<namespace>.+)\s*$'

    # now, get all class dependencies
    foreach ($class in $graph.Classes.Values) {
        # get file content
        $content = $class.Content()

        # parse for the "using class" comment
        $usings = @($content -imatch $regex)

        # if there are no dependencies, move along
        if ($usings.Length -eq 0) {
            continue
        }

        # loop through each using, adding dependencies and used by
        foreach ($using in $usings) {
            $using -imatch $regex | Out-Null
            $namespace = $Matches['namespace']

            # ensure the class namespace exists
            if (!$graph.Classes.ContainsKey($namespace)) {
                throw "The namespace '$($namespace)' does not exist: $($class.Path)"
            }

            # add dependency
            $graph.Classes[$class.Namespace].Link($graph.Classes[$namespace])
        }
    }

    # return the graph
    return $graph
}