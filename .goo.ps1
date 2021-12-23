<# goo.ps1 - Type less. Code more.

    Develop, build, test and run helper script built on Powershell

    Developed by Andre Sharpe on October, 24 2020.

    www.goo.dev

    1. '.\.goo' will output the comment headers for each implemented command
    
    2. Add a function with its purpose in its comment header to extend this project's goo file 

    3. 'goo <function>' will run your commands 
#>

<# --- NEW GOO INSTANCE --- #>

using module '.\.goo\goo.psm1'

$goo = [Goo]::new($args)


<# --- SET GLOBAL SCRIPT VARIABLES HERE --- #>

$script:SolutionName            = 'GooExample'

$script:SourceFolder            = '.\_example_solution_'
$script:SolutionFolder          = "$script:SourceFolder\Solution"
$script:SolutionFile            = "$script:SolutionFolder\Solution.sln"
$script:CliProjectFolder        = "$script:SourceFolder\ConsoleApp"
$script:CliProjectFile          = "$script:CliProjectFolder\ConsoleApp.csproj"

$script:DefaultEnvironment      = 'Development'
$script:DockerContainerName     = 'goo_example_solution'
$script:DockerDbPort            = '1433'

$script:DbServer                = '127.0.0.1'
$script:DbPort                  = '1433'
$script:DbName                  = 'model'
$script:DbUser                  = 'sa'
$script:DbPassword              = 'D3v3loper!987'
$script:DbPort                  = '1433'

$script:DbConnectionstring = (
    "Server=$script:DbServer,$script:DockerDbPort;" +
    "Database=$script:DbName;" + 
    "User ID=$script:DbUser;" +
    "Password=$script:DbPassword;" + 
    "Integrated Security=false;" +
    "Connection Timeout=120;" +
    "Application Name=$script:SolutionName;" 
)


<# --- SET YOUR PROJECT'S ENVIRONMENT VARIABLES HERE --- #>

if($null -eq $Env:Environment)
{
    $Env:ENVIRONMENT = $script:DefaultEnvironment
    $Env:ASPNETCORE_ENVIRONMENT = $script:DefaultEnvironment
}

$Env:GOO_CONTAINER_NAME = $script:DockerContainerName
$Env:GOO_CONTAINER_PORT = $script:DockerDbPort
$Env:GOO_DB_SERVER      = $script:DbServer     
$Env:GOO_DB_NAME        = $script:DbName
$Env:GOO_DB_USER        = $script:DbUser
$Env:GOO_DB_PASSWORD    = $script:DbPassword
$Env:GOO_DB_PORT        = $script:DbPort

$Env:ConnectionStrings:DefaultConnection = $script:DbConnectionstring


<# --- ADD YOUR COMMAND DEFINITIONS HERE --- #>

<# 
    A good 'init' command will ensure a freshly cloned project will run first time.
    Guide the developer to do so easily. Check for required tools. Install them if needed. Set magic environment variables if needed.
    This should ideally replace your "Getting Started" section in your README.md
    Type less. Code more. (And get your team or collaboraters started quickly and productively!)
#>

# command: goo init | Run this command first, or to reset project completely. 
$goo.Command.Add( 'init', {
    $goo.Command.Run( 'install' )
    $goo.Docker.StopAllRunningContainers()
    $goo.Command.Run( 'clean' )
    $goo.Command.Run( 'build' )
    $goo.Console.WriteInfo("Waiting for docker to start...")
    if( -not $goo.Sql.WaitForConnection( $script:DbConnectionstring, 30 )){
        $goo.Error("Could not connect to SqlServer on [$script:DbServer,$script:DockerDbPort]")
    }
    $goo.Command.Run( 'load' )
})

# command: goo install | Ensures docker desktop, dotnet and other prerequisistes for the project is installed
$goo.Command.Add( 'install', {
    
    if( -not $goo.IsAdminSession() ) { 
        $goo.Console.WriteLine("To check if required software is installed start Powershell with 'Run as Administrator'"); 
        return 
    }
    
    $goo.Choco.EnsureAppInstalled('git')
    $goo.Choco.EnsureAppInstalled('dotnetcore-sdk')
    $goo.Choco.EnsureAppInstalled('postman')

    if ( $goo.Choco.EnsureAppInstalled('docker-desktop') ) { 
        $goo.Command.Run('configureAndStartDocker') 
    }
})

$goo.Command.Add( 'configureAndStartDocker', {
    # configure docker
    $goo.IO.JsonUpdateFile( "$env:USERPROFILE\AppData\Roaming\Docker\settings.json", @{
        displayedTutorial = $true;
        wslEngineEnabled = $false;
        filesharingDirectories = @("C:\","D:\");
    })
    # and start it..
    $goo.Console.WriteInfo("Waiting a minute for Docker to start. DO NOT ENABLE the WSL 2 engine when prompted! ...")
    $goo.Command.StartProcess('C:\Program Files\Docker\Docker\Docker Desktop.exe')
    $goo.Sleep(45)
})

# command: goo clean | Removes data and build output
$goo.Command.Add( 'clean', {
    $goo.Console.WriteInfo( "Cleaning data and distribution folders..." )
    $goo.Command.Run('dockerDownIfUp')
    $goo.IO.EnsureRemoveFolder("$script:SourceFolder\_containers\")
    $goo.IO.EnsureRemoveFolder("$script:SourceFolder\dist\")
    $goo.Command.RunExternal('dotnet','clean --verbosity:quiet --nologo',$script:SolutionFolder)
    $goo.StopIfError("Failed to clean previous builds. (Release)")
})

# command: goo build | Builds the solution and command line app. 
$goo.Command.Add( 'build', {
    $goo.Command.Run('buildSolution')
    $goo.Command.Run('refreshDocker')
    $goo.Command.Run('up')
})

$goo.Command.Add( 'buildSolution', {
    $goo.Console.WriteInfo("Building Sample solution...")
    $goo.Command.RunExternal('dotnet','build /clp:ErrorsOnly --configuration Release', $script:SolutionFolder)
    $goo.StopIfError("Failed to build solution. (Release)")

    $goo.Command.RunExternal('dotnet','publish --configuration Release --output ..\dist --no-build', $script:CliProjectFolder)
    $goo.StopIfError("Failed to publish CLI project. (Release)")
})

$goo.Command.Add( 'refreshDocker', {
    $goo.Console.WriteInfo("Refreshing container [$script:DockerContainerName]...")
    $goo.Command.Run('dockerDownIfUp')
})

$goo.Command.Add( 'dockerDownIfUp', {
    $goo.Docker.Down( $script:SourceFolder )
    $goo.StopIfError("Failed to stop container.")
})

# command: goo up | Starts your Docker containers
$goo.Command.Add( 'up', {
    $goo.Console.WriteInfo('Starting containers...')
    $goo.Docker.Up( $script:SourceFolder ) 
    $goo.StopIfError('Failed to start container.')
})

# command: goo down | Stops API server and your Docker container
$goo.Command.Add( 'down', {
    $goo.Console.WriteInfo("Stopping API & local containers...")
    $goo.Command.EnsureProcessStopped('dotnet')
    $goo.Command.Run( 'dockerDownIfUp' )
})

# command: goo attach | Attaches to your running SQL Server Docker container
$goo.Command.Add( 'attach', {
    $goo.Console.WriteInfo('Attaching to local SQL Server...')
    $goo.Command.RunExternal('docker',"attach $script:DockerContainerName" )
    $goo.StopIfError("Failed to attach to container [$script:DockerContainerName].")
})

# command: goo env | Show all environment variables
$goo.Command.Add( 'env', { param($dbEnvironment,$dbInstance)

    $goo.Console.WriteLine( "environment variables" )
    $goo.Console.WriteLine( "=====================" )
    Get-ChildItem -Path Env: | Sort-Object -Property Name | Out-Host

    $goo.Console.WriteLine( "dotnet user-secrets" )
    $goo.Console.WriteLine( "===================" )
    $goo.Console.WriteLine() 
    $goo.Command.RunExternal('dotnet',"user-secrets list --project $script:CliProjectFile")

})

# command: goo setenv <env>     | Sets local environment to <env> environment
$goo.Command.Add( 'setenv', { param( $Environment )
    $oldEnv = $Env:ENVIRONMENT
    $Env:ENVIRONMENT = $Environment
    $Env:ASPNETCORE_ENVIRONMENT = $Environment
    $goo.Console.WriteInfo("Environment changed from [$oldEnv] to [$Env:ENVIRONMENT]")
})

# command: goo dev | Start up Visual Studio and VS Code for solution
$goo.Command.Add( 'dev', { 
    $goo.Command.StartProcess($script:SolutionFile)
    $goo.Command.StartProcess('code','.')
})

# command: goo load | Create tbles and load fresh data for the pplication
$goo.Command.Add( 'load', {
    $goo.Command.RunExternal('dotnet','run -- load',$script:CliProjectFolder)
})

# command: goo run | Run the console application
$goo.Command.Add( 'run', {
    $goo.Command.RunExternal('dotnet','run -- all',$script:CliProjectFolder)
})

# command: goo sql <query> | Executes a query on your local SQL server container
$goo.Command.Add( 'sql', { param( $sql )
    $goo.Sql.Query( $script:DbConnectionstring, $sql )
})

# command: goo feature <name> | Creates a new feature branch from your main git branch
$goo.Command.Add( 'feature', { param( $featureName )
    $goo.Git.CheckoutFeature($featureName)
    $goo.GooBumpVersion('build')
})

# command: goo main | Checks out the main branch and prunes features removed at origin
$goo.Command.Add( 'main', { param( $featureName )
    $goo.Git.CheckoutMain()
})

# command: goo push <message> | Performs 'git add -A', 'git commit -m <message>', 'git -u push origin'
$goo.Command.Add( 'push', { param( $message )
    $current = $goo.Git.CurrentBranch()
    $head = $goo.Git.HeadBranch()
    if($head -eq $current) {
        $goo.Error("You can't push directly to the '$head' branch")
    }
    else {
        $goo.Git.AddCommitPushRemote($message)
    }
})


# command: goo pull | Pull everything from master and creates a new branch
$goo.Command.Add( 'xpull', {
    # save current changes into a separate backup branch
    $date = "{0:d}" -f (get-date)
    $branchName =-join($env:UserName,'-', $date) 
    $anyPendingChanges = Invoke-Expression "& git status"
    if ($anyPendingChanges -contains "nothing to commit, working tree clean") {
        $goo.Command.RunExternal('git', 'checkout -b temp/' + $branchName)
        $goo.Command.RunExternal('git', 'add -A')
        $goo.Command.RunExternal('git', 'commit -m "Save local change to branch : temp/' + $branchName)
    }
    # create a new branch
    $date = "{0:d}" -f (get-date)
    $branchName =-join($env:UserName,'-', $date) 
    $goo.Command.RunExternal('git', 'checkout master')
    $goo.Command.RunExternal('git', 'reset --hard')
    $goo.Command.RunExternal('git','pull')
    $goo.Command.RunExternal('git','checkout -b feature/' + $branchName)
})

# command: goo push | Push current branch to remote git
$goo.Command.Add( 'xpush', {

    # check if it's master branch and abort if so
    $currentBranch = Invoke-Expression "& git branch --show-current"
    if( @('master', 'main') -contains $currentBranch ){
        # ignore
    }
    else{
        $goo.Command.RunExternal('git','push -u origin ' + $currentBranch)
    }
})

<# --- START GOO EXECUTION --- #>

$goo.Start()


<# --- EOF --- #>
