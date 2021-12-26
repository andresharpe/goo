![logo](https://github.com/andresharpe/goo/blob/main/assets/logo/logo.png?raw=true)

# goo.dev

### Type less. Code more. Developer workflow accelerator with Poweshell.

Whilst developing and testing software you repeat many sequences of key strokes in your workflow that `goo` helps you automate.

You can share your automations with others on the team and with users and testers that may be less technical.

## Automate Workflows
`goo` lets you automate frequently used commands to initialize projects, check the dev environment for required software, build and run your solutions and projects, create and seed data, perform version control.

## Quickstart Projects
Many projects on Github and private repositories take hours to get working on a local dev environment.

They require a developer to follow (frequently out of date) ‘Getting Started’ instructions on which tools and dependencies to install to make a project work, which environment variables to set, docker containers to start, etc.

Use `goo` too make cloning and running a project as easy as..
```PowerShell
git clone <some_repo>
cd <my_awesome_project>
goo init
```
You can easily change what your init command does.

## Create Commands
Setup as many self-documented commands as you want in your `.\.goo.ps1`

![goo.ps1](https://github.com/andresharpe/goo/blob/main/assets/screenshots/goo-ps1.png?raw=true)

For example your goo commands can easily:-

- Check that all required tools or frameworks are installed
- Provide instructions on how to install them (or simply install them using scoop, winget or Chocolatey).
- Set required environment variables
- Confirm connectivity to VPN’s or corporate network resources
- Start or stop containers
- Build the project or solution
- Create and seed databases
- Run benchmarks and tests

…or anything else you need to make your project work, or be more productive.

## Self-document Projects
Typing `goo` anywhere in your project folder hierarchy will display all the commands that you have created for your project. This self-documents project workflows and helps others on your team be more productive.

![goo-cli](https://github.com/andresharpe/goo/blob/main/assets/screenshots/goo-goo.gif?raw=true)

## Leverage Powershell
As `goo` scripts are built on Powershell, you can leverage the full capability and power of any command that works at the command line.

You can use the rich set of class modules included with `goo` and add your own.

```PowerShell
# command: goo clean | Removes data and build output
$goo.Command.Add( 'clean', {
    $goo.Console.WriteInfo( "Cleaning project..." )
    $goo.Command.Run('dockerDownIfUp')
    $goo.IO.EnsureRemoveFolder(".\_containers\")
    $goo.IO.EnsureRemoveFolder(".\dist\")
    $goo.Command.RunExternal('dotnet','clean --verbosity:quiet --nologo','.\sln)
    $goo.StopIfError("Failed to clean the project.")
})
```

## Getting Started
To add `goo` to your project: Start Powershell and navigate to your project folder root. Then type:
```PowerShell
iwr get.goo.dev | iex
```
This will add `.goo` as a folder to your project and create a sample `.goo.ps1` script in your main project folder.

You can edit `.goo.ps1` and start adding commands to automate workflows in your project.