## Method 1

#!/bin/bash

# Path to the directory containing the PEM certificates
cert_dir="/usr/share/pki/ca-trust-source/anchors"

# Function to list and delete expired certificates
check_and_delete_expired_certs() {
    local certs_found=0
    
    # Check if the certificate directory exists
    if [ ! -d "$cert_dir" ]; then
        echo "Certificate directory not found: $cert_dir"
        exit 1
    fi

    # List all PEM certificates in the directory
    cert_files=$(find "$cert_dir" -type f -name "*.pem")

    # Iterate over each certificate file
    for cert_file in $cert_files; do
        local expiration_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
        local expiration_epoch=$(date -d "$expiration_date" +"%s")
        local current_epoch=$(date +"%s")

        if [ "$expiration_epoch" -lt "$current_epoch" ]; then
            echo "Deleting expired certificate: $(basename "$cert_file")"
            rm "$cert_file"
            certs_found=1
        fi
    done

    # If no expired certs found, print message
    if [ $certs_found -eq 0 ]; then
        echo "No expired certs"
    fi
}

# Call the function
check_and_delete_expired_certs

exit 0

## Method 2
#!/bin/bash

# Path to the directory containing the PEM certificates
cert_dir="/usr/share/pki/ca-trust-source/anchors"

# Function to check if a certificate is expired
check_expiry() {
    local cert_file="$1"
    local expiration_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
    local expiration_epoch=$(date -d "$expiration_date" +"%s")
    local current_epoch=$(date +"%s")

    if [ "$expiration_epoch" -lt "$current_epoch" ]; then
        echo "$cert_file"
        return 0
    else
        return 1
    fi
}

# Check if the certificate directory exists
if [ ! -d "$cert_dir" ]; then
    echo "Certificate directory not found: $cert_dir"
    exit 1
fi

# List all PEM certificates in the directory
cert_files=$(find "$cert_dir" -type f -name "*.pem")

# Iterate over each certificate file
for cert_file in $cert_files; do
    if check_expiry "$cert_file"; then
        echo "Deleting expired certificate: $(basename "$cert_file")"
        rm "$cert_file"
    fi
done

exit 0
