data "aws_ami" "amazon_linux" {
  count       = var.enable_compute ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_iam_role" "ec2" {
  count = var.enable_compute ? 1 : 0
  name  = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_compute ? 1 : 0
  role       = aws_iam_role.ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  count = var.enable_compute ? 1 : 0
  name  = "${local.name_prefix}-ec2-profile"
  role  = aws_iam_role.ec2[0].name
}

resource "aws_launch_template" "app" {
  count         = var.enable_compute ? 1 : 0
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = data.aws_ami.amazon_linux[0].id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2[0].name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable --now nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!doctype html><html><head><title>AWS DevOps Demo</title></head>
    <body><h1>AWS DevOps Assessment Demo</h1><p>Instance provisioned by Terraform.</p></body></html>
    HTML
    echo OK > /usr/share/nginx/html/health.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${local.name_prefix}-app" })
  }

  tags = local.common_tags
}

resource "aws_lb" "app" {
  count              = var.enable_alb ? 1 : 0
  name               = substr("${local.name_prefix}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  access_logs {
    bucket  = aws_s3_bucket.logs.bucket
    enabled = true
  }
  depends_on = [aws_s3_bucket_policy.logs]
  tags       = local.common_tags
}

resource "aws_lb_target_group" "app" {
  count       = var.enable_alb ? 1 : 0
  name        = substr("${local.name_prefix}-tg", 0, 32)
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/health.html"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "http" {
  count             = var.enable_alb ? 1 : 0
  load_balancer_arn = aws_lb.app[0].arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.app[0].arn
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.enable_alb && var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.app[0].arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }

  lifecycle {
    precondition {
      condition     = var.acm_certificate_arn != ""
      error_message = "Set acm_certificate_arn when enable_https=true."
    }
  }
}

resource "aws_autoscaling_group" "app" {
  count               = var.enable_compute && var.enable_alb ? 1 : 0
  name                = "${local.name_prefix}-asg"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
  vpc_zone_identifier = aws_subnet.private_app[*].id
  target_group_arns   = [aws_lb_target_group.app[0].arn]
  health_check_type   = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.app[0].id
    version = aws_launch_template.app[0].latest_version
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app-asg"
    propagate_at_launch = true
  }

  depends_on = [aws_route.private_app_nat]
}
