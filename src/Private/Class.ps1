function New-PSClassModel
{
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ClassPath,

        [Parameter(Mandatory=$true)]
        [string]
        $RootPath
    )

    $class = (New-Object -TypeName PSObject -Property @{
        Path = $ClassPath
        Name = [System.IO.Path]::GetFileNameWithoutExtension($ClassPath)
        Namespace = (Get-PSClassNamespace -ClassPath $ClassPath -RootPath $RootPath)
        Added = $false
        DependentOn = @()
        UsedBy = @()
    })

    $class | Add-Member -MemberType ScriptMethod -Name 'Content' -Value {
        return @(Get-Content -Path $this.Path -Force -Encoding UTF8)
    }

    $class | Add-Member -MemberType ScriptMethod -Name 'Link' -Value {
        param (
            [Parameter(Mandatory=$true)]
            $Class
        )

        # add dependency
        $deps = @($this.DependentOn | Select-Object -ExpandProperty Namespace)
        if ($deps -inotcontains $Class.Namespace) {
            $this.DependentOn += $Class
        }

        # add used by
        $used = @($Class.UsedBy | Select-Object -ExpandProperty Namespace)
        if ($used -inotcontains $this.Namespace) {
            $Class.UsedBy += $this
        }
    }

    $class | Add-Member -MemberType ScriptMethod -Name 'AllDependencies' -Value {
        $dependencies = @()
        $visitor = @()

        # setup dependencies
        $this.DependentOn | ForEach-Object {
            $dependencies += @{
                Class = $_
                Links = @($this.Namespace)
            }
        }

        # find all dependencies and links
        for ($i = 0; $i -lt $dependencies.Length; $i++)
        {
            $class = $dependencies[$i].Class

            if ($visitor -inotcontains $class.Namespace)
            {
                foreach ($dep in $class.DependentOn) {
                    $dependencies += @{
                        Class = $dep
                        Links = ($dependencies[$i].Links + $class.Namespace)
                    }
                }

                $visitor += $class.Namespace
            }
        }

        return $dependencies
    }

    return $class
}

function Get-PSClassNamespace
{
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ClassPath,

        [Parameter(Mandatory=$true)]
        [string]
        $RootPath
    )

    $Path = ($ClassPath.Replace($RootPath, [string]::Empty)).Trim('\/')
    $Parent = (Split-Path -Parent -Path $Path)
    $File = [System.IO.Path]::GetFileNameWithoutExtension($Path)

    if ([string]::IsNullOrWhiteSpace($Parent)) {
        $namepsace = ($File -replace '(\\|/)', '.')
    }
    else {
        $namepsace = ((Join-Path $Parent $File) -replace '(\\|/)', '.')
    }

    return $namepsace
}

function Get-PSClassModels
{
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $RootPath
    )

    return @((Get-ChildItem -Path $RootPath -Filter '*.ps1' -Recurse -Force).FullName | ForEach-Object {
        New-PSClassModel -ClassPath $_ -RootPath $RootPath
    })
}