
#!/bin/bash

# Define the path to the ca-bundle.trust.crt file
cert_file="/etc/pki/ca-trust/extrafted/openssl/ca-bundle.trust.crt"

# Iterate through each certificate in the file
while IFS= read -r line; do
    # Check if the line contains "-----BEGIN CERTIFICATE-----", indicating the start of a certificate
    if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
        # Extract the certificate into a temporary file
        tmp_cert=$(mktemp)
        echo "$line" >> "$tmp_cert"
        # Continue reading until the end of the certificate
        while IFS= read -r inner_line; do
            # Append lines to the temporary file until the end of the certificate is reached
            echo "$inner_line" >> "$tmp_cert"
            # Check if the line contains "-----END CERTIFICATE-----", indicating the end of a certificate
            if [[ "$inner_line" == "-----END CERTIFICATE-----" ]]; then
                # Check if the certificate is expired
                expiration_date=$(openssl x509 -enddate -noout -in "$tmp_cert" | sed 's/notAfter=//')
                expiration_timestamp=$(date -d "$expiration_date" +%s)
                current_timestamp=$(date +%s)
                if [[ $expiration_timestamp -lt $current_timestamp ]]; then
                    # Extract CN name
                    cn_name=$(openssl x509 -subject -noout -in "$tmp_cert" | sed -n 's/subject=.*CN=\([^\/]*\).*/\1/p')
                    # Print CN name and expiration date
                    echo "Expired Certificate: $cn_name, Expiration Date: $expiration_date"
                fi
                # Remove the temporary file
                rm "$tmp_cert"
                break
            fi
        done
    fi
done < "$cert_file"
