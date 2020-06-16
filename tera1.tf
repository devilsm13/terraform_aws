provider "aws" {
 region = "ap-south-1"
 profile = "shubham"
}

resource "aws_security_group" "tera_sg" {
 name = "tera1_sg"
 description = "For port 80 and 22"
 vpc_id = "vpc-f0001f98"
 
 ingress {
 description = "port 22, for SSH"
 from_port = 22
 to_port = 22
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }

 ingress {
 description = "port 80, for HTTP"
 from_port = 80
 to_port = 80
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 } 

 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 }

 tags = {
 Name = "ssh_http"
 }
}

resource "tls_private_key" "awskey3" {
 algorithm = "RSA"
}

resource "aws_key_pair" "awskey" {
 key_name = "tera1_key"
 public_key = tls_private_key.awskey3.public_key_openssh
}


resource "aws_instance" tera1_web {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "tera1_key"
  security_groups = [aws_security_group.tera_sg.name]

 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.awskey3.private_key_pem
    host     = aws_instance.tera1_web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

 tags = {
  Name = "tera1_os"
 }
}

resource "aws_ebs_volume" tera1_ebs{
  availability_zone = aws_instance.tera1_web.availability_zone
  size              = 1
  tags = {
    Name = "tera1_ebs"
  }
}

resource "aws_volume_attachment" "tera1_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.tera1_ebs.id
  instance_id = aws_instance.tera1_web.id
  force_detach = true
}


output "IP_of_OS" {
  value = aws_instance.tera1_web.public_ip
}


resource "null_resource" "tera1_null1"  {

depends_on = [
    aws_volume_attachment.tera1_ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.awskey3.private_key_pem
    host     = aws_instance.tera1_web.public_ip
  }

 provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/devilsm13/tera1_code.git /var/www/html/"
    ]
  }
}

resource "aws_s3_bucket" "tera1bucket" {
 bucket = "tera1bucket"
 acl = "public-read"
 force_destroy = true
 tags = {
  Name = "tera1bucket"
 }
}

resource "aws_s3_bucket_object" "tera1_img" {
 depends_on = [
  aws_s3_bucket.tera1bucket,
 ]
 bucket = "tera1bucket"
 key = "image1"
 content_type = "image/jpg"
 source = "C:/Users/Shubham/Desktop/tera_img/tera_image.jpg"
 acl = "public-read"
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "web_cf"
}

locals {
 s3_origin_id = "aws_s3_bucket.tera1bucket.id"
}

resource "aws_cloudfront_distribution" "tera_cf" {
 enabled = true
 is_ipv6_enabled = true
 origin {
  domain_name = aws_s3_bucket.tera1bucket.bucket_regional_domain_name
  origin_id = local.s3_origin_id

  s3_origin_config {
  origin_access_identity = "${aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path}"
  }
 }


 
 default_root_object = "image1"
 logging_config {
  include_cookies = false
  bucket = aws_s3_bucket.tera1bucket.bucket_domain_name
 }
 
 default_cache_behavior {
  allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  cached_methods = ["GET", "HEAD"]
  target_origin_id = local.s3_origin_id

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

 ordered_cache_behavior {
  path_pattern = "/content/immutable/*"
  allowed_methods = ["GET", "HEAD", "OPTIONS"]
  cached_methods = ["GET", "HEAD", "OPTIONS"]
  target_origin_id = local.s3_origin_id

  forwarded_values {
  query_string = false
  headers = ["ORIGIN"]
   cookies {
    forward = "none"
   }
  }

  viewer_protocol_policy = "allow-all"
  min_ttl = 0
  default_ttl = 3600
  max_ttl = 86400
  compress = true
 }

 ordered_cache_behavior {
  path_pattern = "/content/*"
  allowed_methods = ["GET", "HEAD"]
  cached_methods = ["GET", "HEAD"]
  target_origin_id = local.s3_origin_id

  forwarded_values {
  query_string = false
  headers = ["ORIGIN"]
   cookies {
    forward = "none"
   }
  }

  viewer_protocol_policy = "allow-all"
  min_ttl = 0
  default_ttl = 3600
  max_ttl = 86400
  compress = true
 }

 price_class = "PriceClass_200"
 restrictions {
  geo_restriction {
   restriction_type = "none"
  }
}


 viewer_certificate {
  cloudfront_default_certificate = true
 }
}

resource "null_resource" "mynull" {
depends_on = [ 
 aws_cloudfront_distribution.tera_cf,
]
 connection {
  type     = "ssh"
  user     = "ec2-user"
  private_key = tls_private_key.awskey3.private_key_pem
  host     = aws_instance.tera1_web.public_ip
 }

 provisioner "remote-exec" {
  inline = [
   "sudo su << EOF",
   "echo \"<img src='http://${aws_cloudfront_distribution.tera_cf.domain_name}/${aws_s3_bucket_object.tera1_img.key}' height='200' width = '200'>\" >> /var/www/html/index.php",
   "EOF",
   "sudo systemctl restart httpd",
  ]
 }
}

output "domain_name" {
 value = aws_cloudfront_distribution.tera_cf.domain_name
 }


data "aws_iam_policy_document" "tera_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.tera1bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tera1bucket.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.tera1bucket.id
  policy = data.aws_iam_policy_document.tera_s3_policy.json
}
































