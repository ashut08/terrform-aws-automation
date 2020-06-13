//declare cloud provider and credential 


provider "aws"{


region= "ap-south-1"
profile="ashu"

}

//declare key as avariable
variable "mykey"{
type=string
default="mykey11"

}

 //Launch ec2 instances


resource "aws_instance" "webserver"{

ami = "ami-07a8c73a650069cf3"
instance_type="t2.micro"
availability_zone = "ap-south-1b"

key_name=var.mykey
security_groups = ["sec_gp"]
user_data=<<-EOF
    #! /bin/bash
    sudo yum install git -y
    sudo yum install httpd -y
    sudo systemctl start httpd 
    sudo systemctl enable httpd
    sudo mkfs -t ext4 /dev/sdd
    sudo mount /dev/sdd /var/www/html
    EOF
tags={
Name="webserver"
}
}

//creating EBS volume
resource "aws_ebs_volume" "webstorage" {
  availability_zone = "ap-south-1b"
  size              = 1


  tags = {
    Name = "webstorage"
  }
}
//attach volume
resource "aws_volume_attachment" "storage-attach"{
  device_name   = "/dev/sdd"
  volume_id     = "${aws_ebs_volume.webstorage.id}"
  instance_id   = "${aws_instance.webserver.id}"
}

//creating s3 bucket 
resource "aws_s3_bucket" "ashutask-1bucket" {
bucket = "ashu08"
acl = "private"
versioning {
enabled = true
}
tags = {
Name = "ashutask-1bucket"
Environment = "Dev"
}
}

//upload img in s3 bucket
resource "aws_s3_bucket_object" "task1bucket_object" {
key = "myimage"
bucket = "${aws_s3_bucket.ashutask-1bucket.id}"
source = "/home/ashutosh/Downloads/ashu.png"

}
//allow public access
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = "${aws_s3_bucket.ashutask-1bucket.id}"

  block_public_acls   = false
  block_public_policy = false
}

// creating secuity group

resource "aws_security_group" "sec_gp" {
  name        = "sec_gp"
  description = "Allow Http and ssh"
   vpc_id      = "vpc-65f4e90d"


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "sec_gp"  
}


}
//creating 

resource "aws_cloudfront_distribution" "task1_cloudfront" {
    origin {
        domain_name = "ashu08.s3.amazonaws.com"
        origin_id = "S3-ashu08-id"


        custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }

 enabled = true


    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-ashu08-id"

        forwarded_values {
            query_string = false

            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
restrictions {
        geo_restriction {

            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }

//provisioner "local-exec" {
    //command = "google-chrome ${aws_instance.myin1.public_ip}"
 // }
}
