resource "aws_iam_saml_provider" "saml_provider" {
  count = var.allow_gravicore_access ? 1 : 0
  name  = "grv-saml-provider"

  saml_metadata_document = <<XML
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" entityID="https://accounts.google.com/o/saml2?idpid=C04kc093k" validUntil="2023-03-18T02:15:19.000Z">
  <md:IDPSSODescriptor WantAuthnRequestsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <md:KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:X509Data>
          <ds:X509Certificate>MIIDdDCCAlygAwIBAgIGAWI8CjN/MA0GCSqGSIb3DQEBCwUAMHsxFDASBgNVBAoTC0dvb2dsZSBJ
bmMuMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MQ8wDQYDVQQDEwZHb29nbGUxGDAWBgNVBAsTD0dv
b2dsZSBGb3IgV29yazELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWEwHhcNMTgwMzE5
MDIxNTE5WhcNMjMwMzE4MDIxNTE5WjB7MRQwEgYDVQQKEwtHb29nbGUgSW5jLjEWMBQGA1UEBxMN
TW91bnRhaW4gVmlldzEPMA0GA1UEAxMGR29vZ2xlMRgwFgYDVQQLEw9Hb29nbGUgRm9yIFdvcmsx
CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEApCssSm/69cbhh++EIxoEHPhnySNgZsD+/Eh9kI8zP23lQvyNl3m2TACo/qP2OiLw
FSeroBOlM8IUEIP9oqKQ9dvEB/cgTdGPEudsCgN935uVegRsom4DxUjdnCgKqSwVxWwMOcXasfYT
J8sDyoirlCWNrG0jCNRdjyIjX4Xv7ENmXHv2IaBlDEZwlWZFQPCsod+PUYYij3tQST4Ai5dSfIMT
Y+OgfxKxxcgyRUUnlWtCb4+sVWSZGkuekp+7gHOzap1aukBDxFt/sH3KYpzcn11U5AUgDw/bKHcX
3kuM88weM0g2wNCJbvp8lh/5Yyht1JdSAu92/tDXLWY1D30nzwIDAQABMA0GCSqGSIb3DQEBCwUA
A4IBAQBk6Z8MOkLMfMy/d5aJUi/cvq1NU9niEpHLMBQYEoPtsZ7tHDPbkpvJ0YSE/nKgsRsRRREz
IAM4slIfer70XzN00Y+1vU7o2xouB3k9g+mkx7RYb7pnLcxAaMkSC66BJa6+a3TxTL4hnE8i+Mdm
UUknro7xkopmBJa0kj0eH9ykJHa7qiBsEHl26ZHwRc4Uvdf6AAwn3Q86hDsGbyNfaA262MjGvtyy
20edgWGuacFUOt9kU26RnAZFR9fXd0l9EdOVDodQxy743XM+HSVweYl2Fux6ko1JDuIefJTGToVN
O57MyYCnXv+hyyT2X43lyepw2Zsy+oy4LyfXjVBYH/e9</ds:X509Certificate>
        </ds:X509Data>
      </ds:KeyInfo>
    </md:KeyDescriptor>
    <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
    <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://accounts.google.com/o/saml2/idp?idpid=C04kc093k"/>
    <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://accounts.google.com/o/saml2/idp?idpid=C04kc093k"/>
  </md:IDPSSODescriptor>
</md:EntityDescriptor>
XML

}

# Gravicore SecOps Admin role
resource "aws_iam_role" "secops_admin" {
  count = var.allow_gravicore_access ? 1 : 0
  name  = "grv-secops-admin"

  assume_role_policy = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${var.trusted_entity_account_id}:saml-provider/grv-saml-provider"
      },
      "Action": "sts:AssumeRoleWithSAML",
      "Condition": {
        "StringEquals": {
          "SAML:aud": "https://signin.aws.amazon.com/saml"
        }
      }
    }
  ]
}
JSON

}

# Gravicore SecOps Admin role
resource "aws_iam_role_policy_attachment" "attach_secops_admin_access" {
  count = var.allow_gravicore_access ? 1 : 0

  role       = aws_iam_role.secops_admin[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

