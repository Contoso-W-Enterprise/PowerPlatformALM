param(
    [Parameter(
        Mandatory=$True)]
    [ValidateSet(
    'Development',
    'Staging',
    'Production'
    )]
    [string]$env,
    [Parameter (Mandatory = $true)]
    $solutionName,
    $commitMessage
)
{
    'Development'
    {
        $orgURL = 'https://org1b29da34.crm.dynamics.com'
    }
    'Staging'
    {
        $orgURL = 'https://org12a26e6e.crm.dynamics.com/'
        
    }
    'Production'
    {
        $orgURL = ''
    }
}
git pull
pac solution pack -z ('release\' +$solutionName + '.zip') -f ($srcPath +'\' + $solutionName ) -p Managed
pac auth create --url $orgURL
pac solution import -p  ('release\' +$solutionName + '_managed.zip')
pac auth clear