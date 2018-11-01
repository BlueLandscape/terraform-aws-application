data "aws_availability_zones" "available" {}

# Virtual private cloud
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags {
      Name = "${var.project_name}-vpc"
    }
}

# Gateway
resource "aws_internet_gateway" "gateway" {
    vpc_id = "${aws_vpc.main.id}"
    tags {
        Name = "${var.project_name}"
    }
}

# Public subnet
resource "aws_subnet" "main-public" {
    count                   = "${var.az_count}"
    cidr_block              = "${cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)}"
    availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
    vpc_id                  = "${aws_vpc.main.id}"
    map_public_ip_on_launch = true

    tags {
      Name = "${var.project_name}-public"
    }
}

# Private subnet
resource "aws_subnet" "main-private" {
    count             = "${var.az_count}"
    cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    vpc_id            = "${aws_vpc.main.id}"

    tags {
      Name = "${var.project_name}-private"
    }
}

resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gateway.id}"
    }
    tags {
        Name = "${var.project_name}-public-route"
    }
}

resource "aws_route_table_association" "public" {
    count          = "${var.az_count}"
    subnet_id      = "${element(aws_subnet.main-public.*.id, count.index)}"
    route_table_id = "${aws_route_table.public.id}"
}

# Create a NAT gateway with an EIP for each private subnet to get internet connectivity
resource "aws_eip" "gw" {
    count      = "${var.az_count}"
    vpc        = true
    depends_on = ["aws_internet_gateway.gateway"]
}

resource "aws_nat_gateway" "gw" {
    count         = "${var.az_count}"
    subnet_id     = "${element(aws_subnet.main-public.*.id, count.index)}"
    allocation_id = "${element(aws_eip.gw.*.id, count.index)}"

    tags {
        Name = "${var.project_name}-nat-gateway"
    }
}

# Create a new route table for the private subnets
# And make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
    vpc_id = "${aws_vpc.main.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${element(aws_nat_gateway.gw.*.id, count.index)}"
    }

    tags {
        Name = "${var.project_name}-private-route"
    }
}

# Explicitely associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
    count          = "${var.az_count}"
    subnet_id      = "${element(aws_subnet.main-private.*.id, count.index)}"
    route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}