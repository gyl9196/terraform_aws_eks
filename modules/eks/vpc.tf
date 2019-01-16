#
# VPC Resources

variable cluster-name {}

variable "aws-region" {}
variable "vpc-subnet-cidr" {}

resource "aws_vpc" "eks" {
  cidr_block = "${var.vpc-subnet-cidr}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-eks-vpc",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "eks" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.77.${count.index+100}.0/24"
  vpc_id            = "${aws_vpc.eks.id}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-eks",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "eks" {
  vpc_id = "${aws_vpc.eks.id}"

  tags {
    Name = "${var.cluster-name}-eks-igw"
  }
}

resource "aws_route_table" "eks" {
  vpc_id = "${aws_vpc.eks.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks.id}"
  }
}

resource "aws_route_table_association" "eks" {
  count = 2

  subnet_id      = "${aws_subnet.eks.*.id[count.index]}"
  route_table_id = "${aws_route_table.eks.id}"
}


// ------ Private Subnets ------
resource "aws_eip" "nat" {
  vpc   = true
  count = 2
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.eks.*.id, count.index)}"
  count         = 2
  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["subnet_id"]
  }
}

resource "aws_subnet" "private" {
  count = 2
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.77.${count.index+1}.0/24"
  vpc_id            = "${aws_vpc.eks.id}"
  depends_on        = ["aws_nat_gateway.nat"]

  tags = "${
    map(
     "Name", "${var.cluster-name}-eks",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
     "kubernetes.io/role/internal-elb" , "1"
    )
  }"

}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = "${aws_vpc.eks.id}"
}

resource "aws_route" "nat_route" {
  count                  = 2
  route_table_id         = "${aws_route_table.private.*.id[count.index]}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.*.id[count.index]}"
  depends_on = ["aws_nat_gateway.nat"]
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_route_table.private.*.id[count.index]}"

  lifecycle {
    ignore_changes        = ["subnet_id"]
    create_before_destroy = true
  }
}