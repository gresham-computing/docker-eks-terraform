FROM alpine:3.7
MAINTAINER James Laverack <jlaverack@greshamtech.com>

# Install kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# Install Hepito Authenticator for AWS
ADD https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/bin/linux/amd64/heptio-authenticator-aws /usr/local/bin/heptio-authenticator-aws
RUN echo "c7867c698a38acb3e0a2976cb7b3d0f9  /usr/local/bin/heptio-authenticator-aws" | md5sum -c -
RUN chmod +x /usr/local/bin/heptio-authenticator-aws

# Install Terraform
ADD https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip /tmp/terraform_0.11.7_linux_amd64.zip
RUN echo "6b8ce67647a59b2a3f70199c304abca0ddec0e49fd060944c26f666298e23418  /tmp/terraform_0.11.7_linux_amd64.zip" | sha256sum -c -
RUN unzip /tmp/terraform_0.11.7_linux_amd64.zip -d /usr/local/bin/
RUN chmod +x /usr/local/bin/terraform
RUN rm /tmp/terraform_0.11.7_linux_amd64.zip
