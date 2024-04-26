## Method 1
# Function to check PEM file expiration date
function CheckPEMExpiration($pemFilePath) {
    # Run OpenSSL command to extract expiration date
    $opensslOutput = openssl x509 -enddate -noout -in $pemFilePath 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: $opensslOutput"
        return $false
    }
    
    # Extract expiration date from OpenSSL output
    $expirationDate = $opensslOutput -replace 'notAfter=', ''
    $expirationDate = $expirationDate -replace 'GMT', ''
    
    # Convert expiration date to a DateTime object
    $expirationDateTime = [datetime]::ParseExact($expirationDate.Trim(), "MMM dd HH:mm:ss yyyy", $null)
    
    # Check if the certificate has expired
    if ($expirationDateTime -lt (Get-Date)) {
        Write-Host "Certificate expired on $expirationDateTime"
        return $false
    } else {
        Write-Host "Certificate expires on $expirationDateTime"
        return $true
    }
}

# Usage example
$pemFilePath = "path/to/your/certificate.pem"
CheckPEMExpiration $pemFilePath


#Method 2 
# Function to check PEM file expiration date using .NET Framework
function CheckPEMExpiration($pemFilePath) {
    try {
        # Load the certificate from PEM file
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $certificate.Import($pemFilePath)
        
        # Check the expiration date
        $expirationDateTime = $certificate.NotAfter
        if ($expirationDateTime -lt (Get-Date)) {
            Write-Host "Certificate expired on $expirationDateTime"
            return $false
        } else {
            Write-Host "Certificate expires on $expirationDateTime"
            return $true
        }
    } catch {
        Write-Host "Error: $_"
        return $false
    }
}

# Usage example
$pemFilePath = "path/to/your/certificate.pem"
CheckPEMExpiration $pemFilePath
