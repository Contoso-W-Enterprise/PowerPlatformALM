Copyright Microsoft Corporation
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree:
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained within the Premier Customer Services Description.
 
# PowerPlatform ALM Samples
Repository used to host Power Platform ALM with Dataverse for demo and lab purpose.
___
# Workflows
## export-solution-dev(action).yml

 This YAML file contains the configuration for the "export-solution-dev" action.

The "export-solution-dev" action is responsible for exporting a solution in a development environment.

### Usage:
- name: Export Solution (Dev)
  uses: your-org/export-solution-dev-action@v1
  with:
    solution-name: 'My Solution'
    output-folder: './exported-solutions'

### Inputs:
- solution-name: The name of the solution to export.
- output-folder: The folder where the exported solution will be saved.

### Outputs:
 - exported-solution-path: The path to the exported solution file.

### Example:
- name: Export Solution (Dev)
  uses: your-org/export-solution-dev-action@v1
  with:
    solution-name: 'My Solution'
    output-folder: './exported-solutions'
___
## pack-solution(action).yml

This YAML file defines the configuration for the "pack-solution" action.
The action is responsible for packaging a solution in a specific format.

### Inputs:
 - solution-file: The path to the solution file that needs to be packaged.
 - output-folder: The folder where the packaged solution will be saved.

### Outputs:
 - packaged-solution: The path to the packaged solution file.

### Example usage:
 - name: Pack Solution
   uses: some-action/pack-solution@v1
   with:
     solution-file: ./path/to/solution.sln
     output-folder: ./path/to/output
___

## deploy-managed-solution(action).yml
This YAML file contains the configuration for deploying a managed solution.
It is used as an action in a CI/CD pipeline to automate the deployment process.

### Parameters:
- solutionName: The name of the managed solution to deploy.
- environment: The target environment where the solution will be deployed.
- connection: The connection string or credentials for accessing the target environment.

### Steps:
1. Connect to the target environment using the provided connection string or credentials.
2. Retrieve the managed solution file based on the provided solution name.
3. Deploy the managed solution to the target environment.
4. Log the deployment status and any errors encountered during the deployment process.

### Usage:
- name: Deploy Managed Solution
  uses: my-org/deploy-managed-solution-action@v1
  with:
    solutionName: 'MySolution'
    environment: 'Production'
    connection: ${{ secrets.CONNECTION_STRING }}
___
## deploy-unmanaged-solution(action).yml
This YAML file contains the configuration for deploying an unmanaged solution.
It is used to define the steps and actions required to deploy the solution to a target environment.

### Steps:
1. Authenticate with the target environment.
2. Retrieve the unmanaged solution file.
3. Validate the solution file.
4. Deploy the solution to the target environment.
5. Perform post-deployment tasks.

### Usage:
- name: Deploy Unmanaged Solution
  uses: your-action-repo/deploy-unmanaged-solution-action@v1
  with:
    solution-file: 'path/to/solution.zip'
    target-environment: 'https://example.com'
    username: ${{ secrets.USERNAME }}
    password: ${{ secrets.PASSWORD }}
___
# Reusable Workflows
## workflow-export-solution.yml
This YAML file contains the configuration for exporting a solution in a workflow.

### Steps:
1. Authenticate with the target environment.
2. Export the solution using the specified parameters.
3. Save the exported solution to the specified output directory.

### Usage:
- Ensure that the necessary environment variables are set.
- Run this workflow to export the solution.

 Note: Make sure to update the values of the environment variables and parameters according to your specific requirements.
___
## workflow-pack-solution.yml
This YAML file defines the workflow for packing a solution.
The workflow consists of multiple steps that are executed in a specific order.

### Step 1
1. Checkout code: This step checks out the code from the repository.
2. Build solution:This step builds the solution using the specified build configuration.
3. Pack solution: This step packs the solution into a distributable format, such as a NuGet package.
4. Publish artifact: This step publishes the packed solution artifact to a specified location.
5: Cleanup: This step performs any necessary cleanup tasks.
The workflow can be triggered manually or automatically based on specific events, such as a push to the repository.
___
## workflow-import-solution.yml
This YAML file contains the workflow for importing a solution in your project.

### Steps:
1. Checkout the repository.
2. Set up the environment.
3. Import the solution.
4. Run tests.
5. Publish the solution.

### Usage:
- name: Import Solution
  uses: [Your Workflow Action]
  with:
    solution-file: [Path to the solution file]
___
# PowerShell
## PowerPlatform-Utility.ps1
### SYNOPSIS
This script contains utility functions for working with the Power Platform.

### DESCRIPTION
The PowerPlatform-Utility.ps1 script provides a collection of utility functions that can be used to interact with the Power Platform. It includes functions for authentication, data retrieval, and data manipulation.
___
## dataverse-webapi-functions.psm1

### SYNOPSIS
This module contains functions for interacting with the Dataverse Web API.

### DESCRIPTION
The dataverse-webapi-functions module provides a set of functions that can be used to perform various operations on the Dataverse Web API. These functions encapsulate common tasks such as creating, updating, and deleting records, as well as querying data from the Dataverse.

### FUNCTIONS
The module includes the following functions:
- Get-DataverseRecord: Retrieves a record from the Dataverse based on the specified criteria.
- New-DataverseRecord: Creates a new record in the Dataverse with the specified data.
- Update-DataverseRecord: Updates an existing record in the Dataverse with the specified data.
- Remove-DataverseRecord: Deletes a record from the Dataverse based on the specified criteria.
- Get-DataverseRecords: Retrieves a collection of records from the Dataverse based on the specified criteria.

### PARAMETERS
The functions in this module accept various parameters depending on the specific operation being performed. These parameters include criteria for filtering records, data for creating or updating records, and options for controlling the behavior of the functions.

### EXAMPLES
Example 1: Get a record from the Dataverse
    PS C:\> Get-DataverseRecord -EntityName "account" -Id "12345"

    This command retrieves the record with the specified ID from the "account" entity in the Dataverse.

Example 2: Create a new record in the Dataverse
    PS C:\> New-DataverseRecord -EntityName "contact" -Data @{ "firstname" = "John"; "lastname" = "Doe" }

    This command creates a new record in the "contact" entity in the Dataverse with the specified data.

### NOTES
- This module requires the Microsoft.PowerApps.Cds.Client module to be installed.
- The functions in this module require valid credentials for accessing the Dataverse Web API.
- For more information on the Dataverse Web API, refer to the official documentation.


<br />

# Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

<br />

# Copyright

Copyright (c) 2021 Microsoft Corporation. All rights reserved.
