# PSClass

This is a PowerShell module to help determine class dependencies, and also to determine the order that you need to import classes into your module.

## Usage

All classes/enums need to be within a `/Classes` directory, and references to custom classes referenced as `[ClassA]`. Class names should also match the name of the PowerShell file - so a `ClassA` *must* be within a `ClassA.ps1` file.

For example, if you have some class `ClassA` and some other class `ClassB`, the PSClass will see `[ClassB]::Method()` and mark that it should be imported before `ClassA` automatically:

```powershell
class ClassA
{
    static [void] SomeMethod()
    {
        [ClassB]::Method()
    }
}
```

Here, PSClass will know that `ClassB` needs to be imported before `ClassA`.

PSClass will see any `[...]` lines and use them to determine the order that classes/enums are required to be imported - as well as detecting cyclic dependencies.

> Classes/enums can be within sub-directories within the `/Classes` directory.

## Functions

### Get-PSClassOrder

```powershell
Get-PSClassOrder [-Path <string>]
```

When run, this function will look for the `/Classes` folder at the `-Path` specified (default is the current path).

It will then return an array of the class/enum paths in the precise order that they should be imported:

```powershell
Get-PSClassOrder | ForEach-Object { . $_ }
```

### Show-PSClassGraph

```powershell
Show-PSClassgraph [-Path <string>] [-Namespace <string>]
```

Will return the full dependency graph of the classes/enums, or just the dependencies of the namespace specified. The namespace is the path to a class (with no extension), and the slashes are replaced for dots - such as `Tools.Helpers` for a class called `Helpers` at `/Classes/Tools/Helpers.ps1`.

### Test-PSClassCyclic

```powershell
Test-PSClassCyclic [-Path <string>] [-Namespace <string>]
```

Will test for cyclic dependencies on a classes/enums. The namespace is the path to a class (with no extension), and the slashes are replaced for dots - such as `Tools.Helpers` for a class called `Helpers` at `/Classes/Tools/Helpers.ps1`.
