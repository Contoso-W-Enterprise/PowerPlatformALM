# Set your environment ID
$environmentId = "02fcb635-6177-ef13-bb23-481c089f1f04"

Import-Module MSAL.PS

# Authenticate
$AuthResult = Get-MsalToken -ClientId '49676daf-ff23-4aac-adcc-55472d4e2ce0' -Scope 'https://api.powerplatform.com/.default'

$Headers = @{
   Authorization  = "Bearer $($AuthResult.AccessToken)"
   'Content-Type' = "application/json"
}

$uri = "https://api.powerplatform.com/usermanagement/environments/$environmentId/user/applyAdminRole?api-version=2022-03-01-preview";

try {

$postRequestResponse = Invoke-RestMethod -Method Post -Headers $Headers -Uri $uri 
   
} 
   
catch { 
   
   # Dig into the exception to get the Response details. 
   
   Write-Host "Response CorrelationId:" $_.Exception.Response.Headers["x-ms-correlation-id"] 
   
   Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__  
   
   Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription 
   
   $result = $_.Exception.Response.GetResponseStream() 
   
   $reader = New-Object System.IO.StreamReader($result) 
   
   $reader.BaseStream.Position = 0 
   
   $reader.DiscardBufferedData() 
   
   $responseBody = $reader.ReadToEnd(); 
   
   Write-Host $responseBody 
   
} 
   
$output = $postRequestResponse | ConvertTo-Json -Depth 2 
   
Write-Host $output
