# Define source and destination folder paths
$sourceFolder = "G:\My Drive\TestFolder"
$destinationFolder = "G:\My Drive\TestFolder1"

# Initialize the previous file list
$previousFileList = @()

# Loop indefinitely to keep checking the folder
while ($true) {
    Write-Host "Checking folder for files..."

    # Get the current list of files in the source folder
    $currentFileList = Get-ChildItem -Path $sourceFolder

    # Debugging output to confirm folder contents
    Write-Host "Current files in source folder:"
    $currentFileList | ForEach-Object { Write-Host $_.Name }

    # If the current file list is different from the previous list, process the files
    foreach ($newFile in $currentFileList) {
        # Check if the file is new or modified by comparing modification times
        $previousFile = $previousFileList | Where-Object { $_.Name -eq $newFile.Name }

        # If the file is new or has been modified (i.e. doesn't exist or has a different timestamp)
        if ($previousFile -eq $null -or $previousFile.LastWriteTime -ne $newFile.LastWriteTime) {
            Write-Host "Processing new or modified file: $($newFile.FullName)"

            # Run FFmpeg to convert the new file (change the parameters as needed)
            $outputFile = Join-Path $destinationFolder ($newFile.BaseName + "_output.mp4")
            Write-Host "Running FFmpeg on $($newFile.FullName)..."

            # Execute the FFmpeg command to convert the file
            & "C:\ffmpeg\bin\ffmpeg.exe" -y -i $newFile.FullName -ss 00:01:00 -to 00:02:00 -c copy $outputFile

            # Confirm that the conversion has been completed
            Write-Host "File converted: $outputFile"

            # Move the processed file to the new folder (destination folder)
            $movedFilePath = Join-Path $destinationFolder $newFile.Name
            Write-Host "Moving file $($newFile.Name) to $movedFilePath..."

            # Check if the file already exists in the destination folder
            if (Test-Path -Path $movedFilePath) {
                # Rename the file by appending a timestamp to avoid conflict
                $timestamp = Get-Date -Format "yyyyMMddHHmmss"
                $newMovedFilePath = Join-Path $destinationFolder ($newFile.BaseName + "_$timestamp" + $newFile.Extension)
                Write-Host "File already exists. Renaming to: $newMovedFilePath"
                Move-Item -Path $newFile.FullName -Destination $newMovedFilePath
            } else {
                # Move the file as usual
                Move-Item -Path $newFile.FullName -Destination $movedFilePath
            }

            # Confirm that the file has been moved
            Write-Host "File moved to destination: $movedFilePath"

            # Check if the original file exists before attempting to delete it
            if (Test-Path -Path $newFile.FullName) {
                Write-Host "Deleting the original file from source folder..."
                Remove-Item -Path $newFile.FullName -Force
                Write-Host "Original file deleted."
            } else {
                Write-Host "File already deleted or moved, skipping deletion."
            }
        }
    }

    # Update the previous file list to reflect the current state
    $previousFileList = $currentFileList

    # Wait for 10 seconds before checking again
    Write-Host "Waiting for the next check..."
    Start-Sleep -Seconds 10
}
