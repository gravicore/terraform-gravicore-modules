# Set the root folder where your Terraform projects are located
$rootFolder = "C:\Users\Alison\Desktop\gravicore\celink\cel-srv-infra\terragrunt"

# Get all subfolders within the root folder
$subfolders = Get-ChildItem -Path $rootFolder -Directory -Recurse

# Loop through each subfolder and execute the `terraform 0.13upgrade` command
foreach ($subfolder in $subfolders) {
    # Change the current directory to the subfolder
    Set-Location -Path $subfolder.FullName

    # Execute the `terraform 0.13upgrade` command
    terraform13 0.13upgrade -yes

    # Output the subfolder name and status
    Write-Host "Upgraded Terraform in $($subfolder.Name)"
}
