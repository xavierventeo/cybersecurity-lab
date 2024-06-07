# AWS Network Firewall 
# Stateful rule to monitor all 443 traffic by session
resource "aws_networkfirewall_rule_group" "stateful_rule_group" {
  name     = "stateful-rule-group"
  capacity = 100
  type     = "STATEFUL"

  rule_group {
    rules_source {
      stateful_rule {
        action = "ALERT" # Alert instead of drop traffic
        header {
          source           = "0.0.0.0/0"
          destination      = "0.0.0.0/0" # All addresses in internal network
          protocol         = "TCP"
          source_port      = 443 # HTTPS Port
          destination_port = 443
          direction        = "FORWARD"
        }
        rule_option {
          keyword = "sid:100"
        }
      }
    }
  }
}

# Stateful rule to block forbidden domains
resource "aws_networkfirewall_rule_group" "domains_black_list_rule_group" {
  capacity = 100
  name     = "stateful-rule-domain-black-list-group"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = ["www.amazon.com"]
      }
    }
  }

  tags = {
    Name = "stateful-rule-domain-black-list-group"
  }
}

# Stateless rule to monitor all SSL traffic
resource "aws_networkfirewall_rule_group" "stateless_rule_group" {
  name     = "stateless-rule-group"
  capacity = 100
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [6] # TCP Protocol
              destination_port {
                from_port = 22
                to_port   = 22
              }
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
}

# Firewall policy attaching rule stateless and statefull defined
resource "aws_networkfirewall_firewall_policy" "lab_firewall_policy" {
  name = "lab-firewall-policy"
  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:pass"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_rule_group.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.domains_black_list_rule_group.arn
    }

    stateless_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateless_rule_group.arn
      priority     = 1
    }
  }
}

# AWS Network Firewall creation attached to the VPC and firewall subnet. Previous policy attached
resource "aws_networkfirewall_firewall" "lab_firewall" {
  name                = "lab-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.lab_firewall_policy.arn
  vpc_id              = aws_vpc.lab.id

  subnet_mapping {
    subnet_id = aws_subnet.firewall_subnet.id
  }
}

# Create a CloudWatch Log Group
resource "aws_cloudwatch_log_group" "network_firewall_log_group" {
  name              = "/aws/network_firewall/logs"
  retention_in_days = 30
}

# Create Network Firewall Logging Configuration
resource "aws_networkfirewall_logging_configuration" "network_firewall_log_configuration" {
  firewall_arn = aws_networkfirewall_firewall.lab_firewall.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.network_firewall_log_group.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.network_firewall_log_group.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}


###########################
/*
resource "aws_iam_role" "log_delivery_role" {
  name = "AWSLogDeliveryRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "log_delivery_policy" {
  name        = "AWSLogDeliveryWritePolicy"
  description = "Policy to allow AWS log delivery to write to CloudWatch Logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite20150319"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:eu-west-1:762501385471:log-group:network_firewall_log_group:log-stream:*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "762501385471"
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:eu-west-1:762501385471:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "log_delivery_policy_attachment" {
  role       = aws_iam_role.log_delivery_role.name
  policy_arn = aws_iam_policy.log_delivery_policy.arn
}

*/
#############################





/*
# Create IAM Role for Network Firewall Logging
resource "aws_iam_role" "firewall_logging_role" {
  name = "NetworkFirewallLoggingRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "network-firewall.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "firewall_logging_policy" {
  name = "NetworkFirewallLoggingPolicy"
  role = aws_iam_role.firewall_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Sid    = "FirewallLogging"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries"
        ]
        Resource = "*"
      }
    ]
  })
}
*/