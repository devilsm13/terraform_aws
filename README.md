# terraform_aws

This is the project where I have launched an ec2 instance, an EBS volume, an s3, and a cluodfront in AWS using Terraform. 

Here is the objective of the above project:

1. Create the key and security group which allows the port 80.  

2. Launch EC2 instance.  

3. In this Ec2 instance use the key and security group which we have created in step 1.

4. Launch one Volume (EBS) and mount that volume into /var/www/html  

5. A developer has uploaded the code into GitHub repo also the repo has some images.  

6. Copy the GitHub repo code into /var/www/html 

7. Create S3 bucket, and copy/deploy the images from GitHub repo into the s3 bucket and change the permission to public readable. 

8. Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to update in code in /var/www/html

Please visit the "terraform_aws.tf file" for the complete code of the project. 
