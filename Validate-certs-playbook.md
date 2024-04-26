<pre>
## Linux Bash
#!/bin/bash

# Set the S3 bucket prefix
S3_BUCKET_PREFIX="s3://your-bucket/prefix"

# Directory to download pem files
DOWNLOAD_DIR="/tmp/cert"

# Download pem files from S3 bucket
aws s3 cp ${S3_BUCKET_PREFIX} ${DOWNLOAD_DIR} --recursive

# Check if there are more than 5 pem files
num_files=$(ls -l ${DOWNLOAD_DIR}/*.pem | wc -l)
if [[ ${num_files} -lt 5 ]]; then
    echo "Error: There are less than 5 pem files in the specified prefix."
    exit 1
fi

# Loop through each pem file
for pem_file in ${DOWNLOAD_DIR}/*.pem; do
    # Verify if the cert is expired
    if openssl x509 -checkend 0 -noout -in ${pem_file}; then
        # Copy the valid cert to /etc/pki/anchro
        cp ${pem_file} /etc/pki/anchro
    else
        echo "Error: Certificate ${pem_file} is expired."
        exit 1
    fi
done

echo "All valid certificates have been copied to /etc/pki/anchro"

  
## Linux Ansible
---
- name: Download and verify pem files from S3 bucket
  hosts: localhost
  gather_facts: no
  vars:
    s3_bucket_prefix: "your-bucket/prefix"
    download_dir: "/tmp/cert"
    expired_certs: []
  tasks:
    - name: Download pem files from S3 bucket
      aws_s3_sync:
        bucket: "{{ s3_bucket_prefix }}"
        dest: "{{ download_dir }}"

    - name: Check if there are more than 5 pem files
      shell: "ls -l {{ download_dir }}/*.pem | wc -l"
      register: num_files
      changed_when: false
      check_mode: no

    - name: Fail if less than 5 pem files are found
      fail:
        msg: "Error: There are less than 5 pem files in the specified prefix."
      when: num_files.stdout|int < 5

    - name: Verify pem files
      command: "openssl x509 -checkend 0 -noout -in {{ item }}"
      register: cert_validity
      changed_when: false
      check_mode: no
      loop: "{{ lookup('fileglob', download_dir + '/*.pem') }}"
      ignore_errors: yes

    - name: Add expired certs to the list
      set_fact:
        expired_certs: "{{ expired_certs + [item.item] }}"
      when: cert_validity.rc != 0

    - name: Copy valid pem files to /etc/pki/anchro
      copy:
        src: "{{ item }}"
        dest: "/etc/pki/anchro/"
      loop: "{{ lookup('fileglob', download_dir + '/*.pem') }}"
      when: cert_validity.rc == 0

    - name: Fail if any certificate is expired
      fail:
        msg: "Error: One or more certificates are expired."
      when: cert_validity.rc != 0

    - name: Print success message
      debug:
        msg: "All valid certificates have been copied to /etc/pki/anchro"

    - name: Print expired certificates
      debug:
        msg: "Expired certificate: {{ expired_certs }}"
      when: expired_certs | length > 0


## Windows
  # Set S3 bucket and prefix
$S3Bucket = "your-bucket"
$S3Prefix = "prefix"

# Set local directory to copy certificates
$LocalDirectory = "C:\temp\cert"

# Set directory to import certificates
$ImportDirectory = "C:\root"

# Download certificates from S3
aws s3 cp s3://$S3Bucket/$S3Prefix $LocalDirectory --recursive

# Check if certificates are downloaded
if (!(Test-Path $LocalDirectory)) {
    Write-Host "Error: No certificates found in specified S3 prefix."
    Exit 1
}

# Iterate through each certificate file
$CertFiles = Get-ChildItem -Path $LocalDirectory -Recurse -Filter "*.pem"
foreach ($CertFile in $CertFiles) {
    # Verify certificate expiration
    $Cert = Get-PfxCertificate -FilePath $CertFile.FullName
    if ($Cert -eq $null) {
        Write-Host "Error: Unable to read certificate from file $($CertFile.FullName)"
        Continue
    }
    $ExpiryDate = $Cert.NotAfter
    $Now = Get-Date
    if ($Now -ge $ExpiryDate) {
        Write-Host "Error: Certificate $($CertFile.FullName) is expired."
        Exit 1
    }

    # Import certificate to root directory
    $CertFilePath = $CertFile.FullName
    $CertFileName = $CertFile.Name
    $ImportPath = Join-Path -Path $ImportDirectory -ChildPath $CertFileName
    Copy-Item -Path $CertFilePath -Destination $ImportPath
}

Write-Host "Certificates are successfully imported to $ImportDirectory"

  
</pre>
