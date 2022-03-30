
resource "aws_vpc" "bars_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.app_name}-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "aws_igw" {
  vpc_id = aws_vpc.bars_vpc.id
  tags = {
    Name        = "${var.app_name}-igw"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.bars_vpc.id
  count             = length(var.private_subnets)
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name        = "${var.app_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnets" {
  vpc_id                  = aws_vpc.bars_vpc.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.app_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.bars_vpc.id

  tags = {
    Name        = "${var.app_name}-routing-table-public"
    Environment = var.environment
  }
}

resource "aws_route" "aws_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.aws_igw.id
}

resource "aws_route_table_association" "public_route_association" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_security_group" "service_security_group" {
  vpc_id = aws_vpc.bars_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.app_name}-service-sg"
    Environment = var.environment
  }
}
