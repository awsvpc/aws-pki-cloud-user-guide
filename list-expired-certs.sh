<pre>
Here are the commands:

List all expired certificates:

openssl x509 -in /etc/pki/tls/certs/ca-bundle.crt -text -noout | awk 'BEGIN { cert=""; } /^\s*$/ { if (cert !="") { print cert; cert=""; } } { cert=cert $0 "\n"; } END { if (cert !="") { print cert; } }' | grep -A 2 "Validity" | grep "Not After" | awk '{print $4 " " $5 " " $6 " " $7 " " $8 " " $9}'
List certificates with names starting with "APP-Montent":

openssl x509 -in /etc/pki/tls/certs/ca-bundle.crt -text -noout | grep -A 1 "Subject:" | grep "APP-Montent"
Remove a specific certificate (replace <certificate_name> with the actual name of the certificate you want to remove):

certutil -D -d /etc/pki/nssdb -n "<certificate_name>"
Remember to run these commands with appropriate permissions (often as root or using sudo). Additionally, the exact paths and commands might vary slightly depending on your Red Hat version and configuration.


Here's the command to update the trust store:

update-ca-trust

</pre>
