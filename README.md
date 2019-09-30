# PSClass

This is a PowerShell module to help determine class dependencies, and also to determine the order that you need to import classes into your module.

## Usage

All classes/enums need to be within a `/Classes` directory. Then in each of your classes, have at the top a reference to the other classes/enums it depends on:

```powershell
# using class ClassA
# using enum EnumZ
```

For example, if you have some class `ClassA` and some other class `ClassB`, if `ClassA` depends on `ClassB` then at the top of `ClassA`:

```powershell
# using class ClassB

class ClassA
{
    # normal logic
}
```

PSClass will use the `# using class` and `# using enum` lines to determine the order that classes/enums are required to be imported - as well as detecting cyclic dependencies.

### Sub-Directories

If you have your classes/enums in sub-directories (within `/Classes` directory), then you'll need to reference dependencies using a namespace system.

For example, if again have `ClassA` depending on `ClassB` but this time `ClassB` is within the directory `Other`, then your using statement would be:

```powershell
# using class Other.ClassB

class ClassA
{
    # normal logic
}
```

## Functions

### Get-PSClassOrder

```powershell
Get-PSClassOrder [-Path <string>]
```

When run, this function will look for the `/Classes` folder at the `-Path` specified (default is current).

It will then return an array of the class/enum paths in the precise order that they should be imported:

```powershell
Get-PSClassOrder | ForEach-Object { . $_ }
```

### Show-PSClassGraph

```powershell
Show-PSClassgraph [-Path <string>] [-Namespace <string>]
```

Will return the full dependency graph of the classes/enums, or just the dependencies of the namespace specified.

### Test-PSClassCyclic

```powershell
Test-PSClassCyclic [-Path <string>] [-Namespace <string>]
```

Will test for cyclic dependencies on a classes/enums.
