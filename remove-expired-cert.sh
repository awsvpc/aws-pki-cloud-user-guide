sudo sed -i '/-----BEGIN CERTIFICATE-----/{:a;N;/-----END CERTIFICATE-----/!ba;/CN=YOUR_CERT_CN/d}' /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
