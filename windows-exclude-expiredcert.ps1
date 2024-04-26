param (
    [string]$bucketAndPrefix
)

# Function to verify certificate expiration and copy non-expired certificates
function VerifyAndCopyCertificates {
    param (
        [string]$bucketAndPrefix
    )

    # Extract bucket and prefix from input
    $bucket = $bucketAndPrefix.Split('/')[2]
    $prefix = $bucketAndPrefix.Split('/')[3..($bucketAndPrefix.Split('/').Count - 1)] -join "/"

    # List files in the specified S3 bucket with the given prefix
    $files = aws s3 ls $bucket/$prefix
    foreach ($line in $files) {
        # Extract file name from the output
        $fileName = $line.Split()[-1]
        # Check if the file has a .pem extension
        if ($fileName -match '\.pem$') {
            # Download the certificate file
            aws s3 cp $bucket/$prefix/$fileName C:\Temp\$fileName
            # Verify if the certificate is expired
            $expirationDate = (openssl x509 -enddate -noout -in C:\Temp\$fileName | Select-String -Pattern 'notAfter=').Line -replace 'notAfter='
            $expirationTimestamp = [datetime]::ParseExact($expirationDate, 'MMM dd HH:mm:ss yyyy zzz', [System.Globalization.CultureInfo]::InvariantCulture).Ticks
            $currentTimestamp = [datetime]::UtcNow.Ticks
            if ($expirationTimestamp -gt $currentTimestamp) {
                # Copy non-expired certificates to the destination folder
                Copy-Item -Path C:\Temp\$fileName -Destination 'C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\'
                Write-Output "Certificate $fileName copied to C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\"
            } else {
                # Print the name of expired certificate
                Write-Output "Expired Certificate: $fileName"
            }
            # Remove temporary certificate file
            Remove-Item -Path C:\Temp\$fileName
        }
    }
}

# Call the function with the input parameter
VerifyAndCopyCertificates -bucketAndPrefix $bucketAndPrefix
