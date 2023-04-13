provider "aws" {
    region = "eu-central-1"
}


resource "aws_vpc" "main_net" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "Main"
  }
}


resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_net.id

  tags = {
    Name = "main_rt"
  }  
}


resource "aws_route_table_association" "rt_association_public_web" {
  subnet_id = aws_subnet.public_net.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_route_table_association" "rt_association_private_web" {
  subnet_id = aws_subnet.private_net.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_route_table_association" "rt_association_db_web" {
  subnet_id = aws_subnet.db_net.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_internet_gateway" "main_inet_gw" {
  vpc_id = aws_vpc.main_net.id

  tags = {
    Name = "main_inet_gw"
  }
}


resource "aws_route" "internet_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.main_rt.id
  gateway_id = aws_internet_gateway.main_inet_gw.id
}

resource "aws_subnet" "public_net" {
  vpc_id = aws_vpc.main_net.id
  availability_zone = "eu-central-1a"
  cidr_block = "192.168.5.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public_net"
  }
}

resource "aws_subnet" "private_net" {
  vpc_id = aws_vpc.main_net.id
  availability_zone = "eu-central-1a"
  cidr_block = "192.168.6.0/24"

  tags = {
    Name = "Privat_net"
  }
}

resource "aws_subnet" "db_net" {
  vpc_id = aws_vpc.main_net.id
  availability_zone = "eu-central-1a"
  cidr_block = "192.168.7.0/24"

  tags = {
    Name = "DB_net"
  }
}


resource "aws_network_interface" "public_web_nic" {
  subnet_id = aws_subnet.public_net.id
  private_ips = ["192.168.5.5"]
  security_groups = [aws_security_group.allow_public_http.id]
}


resource "aws_security_group" "allow_public_http" {
  name        = "allow_public_http"
  description = "Allow 80 inbound traffic to public web server"
  vpc_id      = aws_vpc.main_net.id

  ingress {
    description      = "80 to public_web"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "22 to public_web"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_public_http"
  }
}

resource "aws_security_group" "allow_private_http" {
  name        = "allow_private_http"
  description = "Allow 80 inbound traffic to private web server"
  vpc_id      = aws_vpc.main_net.id

  ingress {
    description      = "80 from public_web"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["192.168.5.5/32"]
  }

  ingress {
    description      = "allow 22"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["192.168.5.5/32"]
  }

  ingress {
    description      = "allow 80 to 5000"
    from_port        = 80
    to_port          = 5000
    protocol         = "tcp"
    cidr_blocks      = ["192.168.5.5/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_private_http"
  }
}

resource "aws_security_group" "allow_postgre" {
  name        = "allow_postgre_5432"
  description = "Allow 5432 inbound traffic to postgresql server"
  vpc_id      = aws_vpc.main_net.id

  ingress {
    description      = "from private_web to postgre"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["192.168.6.5/32"]
  }

  ingress {
    description      = "22 to db"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["192.168.5.5/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_private_http"
  }
}


resource "aws_instance" "public_web" {
    ami = "ami-0ec7f9846da6b0f61"
    instance_type = "t2.micro"
    key_name = "<your_key_pair>"

    network_interface {
      network_interface_id = aws_network_interface.public_web_nic.id
      device_index = 0
    }
    
    credit_specification {
    cpu_credits = "unlimited"
    }

    tags = {
      Name = "Public_web"
    }
}

resource "aws_instance" "private_web" {
    ami = "ami-0ec7f9846da6b0f61"
    instance_type = "t2.micro"
    key_name = "<your_key_pair>"
    vpc_security_group_ids = [aws_security_group.allow_private_http.id]
    subnet_id = aws_subnet.private_net.id
    private_ip = "192.168.6.5"
    associate_public_ip_address = true

    tags = {
      Name = "Private_web"
    }
}

resource "aws_instance" "db" {
    ami = "ami-0ec7f9846da6b0f61"
    instance_type = "t2.micro"
    key_name = "<your_key_pair>"
    vpc_security_group_ids = [aws_security_group.allow_postgre.id]
    subnet_id = aws_subnet.db_net.id
    private_ip = "192.168.7.5"
    associate_public_ip_address = true

    tags = {
      Name = "Db"
    }
}

resource "aws_eip" "public_web_ip" {
 vpc = true
 network_interface = aws_network_interface.public_web_nic.id
}
