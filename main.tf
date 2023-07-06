resource "aws_vpc" "my_VPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Terraform-VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_VPC.id

  tags = {
    Name = "Terraform_IGateway"
  }
}

resource "aws_subnet" "subnet-1" { //publi subnet1
  vpc_id     = aws_vpc.my_VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Terraform-Subnet-1"
  }
}

resource "aws_subnet" "subnet-2" { //private subnet1
  vpc_id     = aws_vpc.my_VPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1c"
}



resource "aws_subnet" "subnet-3" { //public subnet2
  vpc_id     = aws_vpc.my_VPC.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "Terraform-Subnet-3"
  }
}

resource "aws_subnet" "subnet-4" { //private subnet2
  vpc_id     = aws_vpc.my_VPC.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "Terraform-Subnet-4"
  }
}


resource "aws_route_table" "prod-public-crt" {
    vpc_id = aws_vpc.my_VPC.id
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        gateway_id = aws_internet_gateway.gw.id 
    }
    tags = {
    Name = "Route_Table-1"
  }
    
   
}

resource "aws_route_table" "prod-private-crt" {
    vpc_id = aws_vpc.my_VPC.id
    
    route {
        cidr_block = "0.0.0.0/0" 
        nat_gateway_id = aws_nat_gateway.Terraform_NAT.id
    }
    tags = {
    Name = "Route_Table-2"
  }
    
   
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  //subnet_id      = aws_subnet.subnet-3.id
  route_table_id = aws_route_table.prod-public-crt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet-2.id
  //subnet_id      = aws_subnet.subnet-4.id
  route_table_id = aws_route_table.prod-private-crt.id
}

resource "aws_nat_gateway" "Terraform_NAT" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.subnet-1.id
  //subnet_id         = aws_subnet.subnet-3.id
  tags = {
    Name = "NAT-Gate"
  }
}


resource "aws_security_group" "allow_tls" {      //Transport layer security
  name        = "allow_tls"
  vpc_id      = aws_vpc.my_VPC.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.my_VPC.cidr_block]
    //ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    //ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow-transport-layer-security"
  }
}

resource "aws_launch_template" "foobar" {
  name_prefix   = "foobar"
  image_id      = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "bar" {
  availability_zones = ["ap-south-1b"]
  desired_capacity   = 2
  max_size           = 2
  min_size           = 2

  launch_template {
    id      = aws_launch_template.foobar.id
    version = "$Latest"
  }
}

resource "aws_lb" "Load-Balancer" {
  name               = "Load-Balancer"
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
  security_groups    = [aws_security_group.allow_tls.id]

  tags = {
    Name = "Application-load-balancer"
  }
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.Load-Balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

resource "aws_lb_target_group" "target-group" {
  name     = "Target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_VPC.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }
}


resource "aws_instance" "app_server" {
  ami                    = "ami-0f5ee92e2d63afc18"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["sg-069eea9c3b8711f6d"]
  key_name= "jenkins"
  tags = {
    Name = "Terraform-assignment"
  }
}
