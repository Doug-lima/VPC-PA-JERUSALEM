##Create client VPN endpoint
resource "aws_ec2_client_vpn_endpoint" "client_vpn" {
  description            = "pa-vpn-client-to-site"
  server_certificate_arn = "arn:aws:acm:us-east-1:991925387373:certificate/07ea4b33-0f8e-4328-a5c5-ff50ce40c7a1" ##substituir arn certificado

  client_cidr_block = "10.128.0.0/22" ##substituir ip ja criado

  authentication_options {
    type                           = "federated-authentication"
    saml_provider_arn              = "arn:aws:iam::991925387373:saml-provider/aws-client-vpn"                     ##substituir arn provider
    self_service_saml_provider_arn = "arn:aws:iam::991925387373:saml-provider/aws-client-vpn-self-service-portal" ##substituir arn provider
  }

  split_tunnel = true

  connection_log_options {
    enabled = false
  }

  vpc_id             = aws_vpc.vpc_jerusalem.id          ##substituir vpc
  security_group_ids = [aws_security_group.webserver.id] ##substituir security group
  
  tags = {
    Name = "pa-vpn-client-to-site"
  }
}

#Target network associations
resource "aws_ec2_client_vpn_network_association" "client_vpn_association_1" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn.id
  subnet_id              = aws_subnet.subnet2.id
}

resource "aws_ec2_client_vpn_network_association" "client_vpn_association_2" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn.id
  subnet_id              = aws_subnet.subnet4.id
}

#Authorization rules
resource "aws_ec2_client_vpn_authorization_rule" "client_vpn_auth_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
}