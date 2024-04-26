#!/bin/bash

# Function to verify certificate expiration and copy non-expired certificates
verify_and_copy_certificates() {
    # Extract bucket and prefix from input
    bucket="$1"
    prefix="$2"

    # List files in the specified S3 bucket with the given prefix
    aws s3 ls "$bucket/$prefix" | while read -r line; do
        # Extract file name from the output
        file_name=$(echo "$line" | awk '{print $NF}')
        # Check if the file has a .pem extension
        if [[ "$file_name" == *.pem ]]; then
            # Download the certificate file
            aws s3 cp "$bucket/$prefix/$file_name" /tmp/"$file_name"
            # Verify if the certificate is expired
            expiration_date=$(openssl x509 -enddate -noout -in /tmp/"$file_name" | sed 's/notAfter=//')
            expiration_timestamp=$(date -d "$expiration_date" +%s)
            current_timestamp=$(date +%s)
            if [[ $expiration_timestamp -gt $current_timestamp ]]; then
                # Copy non-expired certificates to the destination folder
                cp /tmp/"$file_name" /usr/share/pki/ca-trust/source/anchors/
                echo "Certificate $file_name copied to /usr/share/pki/ca-trust/source/anchors/"
            else
                # Print the name of expired certificate
                echo "Expired Certificate: $file_name"
            fi
            # Remove temporary certificate file
            rm /tmp/"$file_name"
        fi
    done
}

# Call the function with the input parameter
verify_and_copy_certificates "$1" "$2"


./cert_verification.sh s3://bucket/prefix
