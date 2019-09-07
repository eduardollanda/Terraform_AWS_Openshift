provider "aws" {
    access_key = "XXXXXXXXXXX"
    secret_key = "XXXXXXXXXXX"
    region     = "us-west-2"
}
resource "aws_instance" "web"{
    ami           = "ami-00f7c900d2e7133e1"
    instance_type = "t2.micro"
    key_name      = "chave"
    associate_public_ip_address = "true"
tags {
    Name = "NAME OF YOUR CONTAINER"
}
connection {
    type = "ssh"
    user = "centos"
    private_key = "${file("[PATH OF YOUR KEY]")}"
    timeout = "2m"
}
## INSTALLING THE DOCKER ##
provisioner "remote-exec"  {
    inline = [
     "sudo yum install -y yum-utils device-mapper-persistent-data lvm2",
     "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
     "sudo yum-config-manager --enable docker-ce-edge",
     "sudo yum-config-manager --enable docker-ce-test",
     "sudo yum-config-manager --disable docker-ce-edge",
     "sudo yum install -y docker-ce",
     "sudo systemctl start docker",
     "sudo usermod -aG docker centos"
 ]
}
## UPLOADING A DOCKER USING THE REDIS IMAGE ##
provisioner "remote-exec"  {
    inline = [
     "sudo docker run -d --volume /srv/docker/gitlab/redis:/var/lib/redis --restart=always  --name=gitlab-redis sameersbn/redis:4.0.9-1"
 ]
}
## UPLOADING A DOCKER USING THE POSTGRESQL IMAGE ##
provisioner "remote-exec"  {
    inline = [
        "sudo docker run -d --volume /srv/docker/gitlab/postgresql:/var/lib/postgresql --env 'DB_USER=YOUR-USER' --env 'DB_PASS=PASSWORD' --env 'DB_NAME=NAME-OF-YOUR-DB' --env 'DB_EXTENSION=pg_trgm' --restart=always --name=gitlab-postgresql sameersbn/postgresql:10"
    ]
}
## UPLOADING A DOCKER USING THE GITLAB RUNNER IMAGE ##
provisioner "remote-exec"  {
    inline = [
        "sudo docker run -d --volume /srv/gitlab-runner/config:/etc/gitlab-runner --volume /var/run/docker.sock:/var/run/docker.sock --restart=always --name=gitlab-runner gitlab/gitlab-runner:latest"
    ]
}
provisioner "remote-exec"  {
    inline = [
     "sudo docker run -d --volume /srv/docker/gitlab/gitlab:/home/git/data --link gitlab-postgresql:postgresql --link gitlab-redis:redisio --publish 10080:80 --publish 10022:22 --env 'DEBUG=false' --env 'DB_ADAPTER=postgresql' --env 'DB_HOST=gitlab-postgresql' --env 'DB_PORT=5432' --env 'DB_USER=root' --env 'DB_PASS=Cdt@12345678' --env 'DB_NAME=gitlab_hqproduction' --env 'GITLAB_PORT=10080' --env 'GITLAB_SSH_PORT=10022' --env 'GITLAB_SECRETS_DB_KEY_BASE=secrettest' --env 'GITLAB_SECRETS_SECRET_KEY_BASE=secrettest' --env 'GITLAB_SECRETS_OTP_KEY_BASE=secrettest' --env 'GITLAB_ROOT_PASS=Cdt@12345678'  --env 'GITLAB_HTTPS=false' --restart=always --name=gitlab sameersbn/gitlab:latest"
 ]
}

## CREATING HOST FILE FOR USE OF THE ANSIBLE ##
provisioner "local-exec" {
    command = "echo [RESOURCE_GROUP:vars] >> /etc/ansible/hosts"
}
provisioner "local-exec" {
    command = "sudo echo ansible_ssh_user=centos >> /etc/ansible/hosts"
    }
provisioner "local-exec" {
    command = "sudo echo ansible_ssh_private_key_file = /etc/ansible/chave.pem >> /etc/ansible/hosts"
}
provisioner "local-exec" {
    command = "sudo echo >> /etc/ansible/hosts"
    }
provisioner "local-exec" {
    command = "sudo echo [RESOURCE_GROUP] >> /etc/ansible/hosts"
    }
provisioner "local-exec" {
    command = "sudo echo ${aws_instance.web.public_ip} >> /etc/ansible/hosts"   
  }
provisioner "local-exec" {
    command = "sudo echo >> /etc/ansible/hosts"
    }

}

resource "aws_security_group" "security_group" {
  ingress {
      protocol = "0"
      from_port = 22
      to_port = 22
      cidr_blocks = ["10.0.1.0/24"]
  }
  ingress {
      protocol = "0"
      from_port = 0
      to_port = 65535
      cidr_blocks = ["10.0.0.0/24"]
  }
  ingress {
      protocol = "0"
      from_port = 8443
      to_port = 8443
      cidr_blocks = ["10.0.0.0/24"]
 }
  ingress {
         protocol = "0"
         from_port = 10022
         to_port = 10022
         cidr_blocks = ["10.0.0.0/24"]
     }
  ingress {
         protocol = "0"
         from_port = 10080
         to_port = 10080
         cidr_blocks = ["10.0.0.0/24"]
     }
  ingress {
         protocol = "0"
         from_port = 53
         to_port = 53
         cidr_blocks = ["10.0.0.0/24"]
     }
  ingress {
         protocol = "0"
         from_port = 80
         to_port = 80
         cidr_blocks = ["10.0.0.0/24"]
     }
  ingress {
         protocol = "0"
         from_port = 443
         to_port = 443
         cidr_blocks = ["10.0.0.0/24"]
     }
  egress {
         protocol = "0"
         from_port = 8443
         to_port = 8443
         cidr_blocks = ["10.0.0.0/24"]
     }
  egress {
         protocol = "0"
         from_port = 10022
         to_port = 10022
         cidr_blocks = ["10.0.0.0/24"]
     }
  egress {
         protocol = "0"
         from_port = 10080
         to_port = 10080
         cidr_blocks = ["10.0.0.0/24"]
     }
  egress {
         protocol = "0"
         from_port = 53
         to_port = 53
         cidr_blocks = ["10.0.0.0/24"]
     }
  egress {
         protocol = "0"
         from_port = 80
         to_port = 80
         cidr_blocks = ["10.0.0.0/24"]
     }
  egress {
         protocol = "0"
         from_port = 443
         to_port = 443
         cidr_blocks = ["10.0.0.0/24"]
     }
}
