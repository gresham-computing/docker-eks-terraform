# So the use of this "downloader" image is so we can download GPG keys, verify files, and other such
# stuff. The final Docker image contains only the binaries we actually download.
FROM alpine:3.7 AS downloader

RUN apk update && apk add gnupg
RUN mkdir -p /tmp/bin

# kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/linux/amd64/kubectl /tmp/bin/kubectl
RUN chmod +x /tmp/bin/kubectl

# Hepito Authenticator for AWS
ADD https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/bin/linux/amd64/heptio-authenticator-aws /tmp/bin/heptio-authenticator-aws
RUN echo "c7867c698a38acb3e0a2976cb7b3d0f9  /tmp/bin/heptio-authenticator-aws" | md5sum -c -
RUN chmod +x /tmp/bin/heptio-authenticator-aws

# Install the Hashicorp PGP Key for verification
ADD keys/hashicorp.asc /tmp/hashicorp.asc
RUN gpg --import /tmp/hashicorp.asc

# Terraform
ARG terraformVersion=0.11.7
ADD https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_linux_amd64.zip /tmp/

# Verify
ADD https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_SHA256SUMS /tmp/
ADD https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_SHA256SUMS.sig /tmp/
RUN gpg --verify /tmp/terraform_${terraformVersion}_SHA256SUMS.sig /tmp/terraform_${terraformVersion}_SHA256SUMS
RUN cd /tmp && cat /tmp/terraform_${terraformVersion}_SHA256SUMS | grep linux_amd64 | sha256sum -c -

# Install
RUN unzip /tmp/terraform_0.11.7_linux_amd64.zip -d /tmp/bin/
RUN chmod +x /tmp/bin/terraform

# Prepare directory for Terraform plugins
RUN mkdir -p /tmp/tf-plugins

# Terraform AWS Provider
ARG terraformAWSProviderVersion=1.26.0
ADD https://releases.hashicorp.com/terraform-provider-aws/${terraformAWSProviderVersion}/terraform-provider-aws_${terraformAWSProviderVersion}_linux_amd64.zip /tmp/

# Verify
ADD https://releases.hashicorp.com/terraform-provider-aws/${terraformAWSProviderVersion}/terraform-provider-aws_${terraformAWSProviderVersion}_SHA256SUMS /tmp/
ADD https://releases.hashicorp.com/terraform-provider-aws/${terraformAWSProviderVersion}/terraform-provider-aws_${terraformAWSProviderVersion}_SHA256SUMS.sig /tmp/
RUN gpg --verify /tmp/terraform-provider-aws_${terraformAWSProviderVersion}_SHA256SUMS.sig /tmp/terraform-provider-aws_${terraformAWSProviderVersion}_SHA256SUMS
RUN cd /tmp && cat /tmp/terraform-provider-aws_${terraformAWSProviderVersion}_SHA256SUMS | grep linux_amd64 | sha256sum -c -

# Install
RUN unzip /tmp/terraform-provider-aws_${terraformAWSProviderVersion}_linux_amd64.zip -d /tmp/tf-plugins

# Helm
ARG helmVersion=2.11.0
ADD https://storage.googleapis.com/kubernetes-helm/helm-v${helmVersion}-linux-amd64.tar.gz /tmp/
RUN mkdir -p /tmp/helm
RUN tar -xzf /tmp/helm-v${helmVersion}-linux-amd64.tar.gz --directory /tmp/helm
RUN mv /tmp/helm/linux-amd64/helm /tmp/bin/

# Terraform Helm Provider
ARG terraformHelmProviderVersion=0.6.0

ADD https://github.com/mcuadros/terraform-provider-helm/releases/download/v${terraformHelmProviderVersion}/terraform-provider-helm_v${terraformHelmProviderVersion}_linux_amd64.tar.gz /tmp/
RUN tar -xzf /tmp/terraform-provider-helm_v${terraformHelmProviderVersion}_linux_amd64.tar.gz --directory /tmp
RUN cp /tmp/terraform-provider-helm_linux_amd64/terraform-provider-helm /tmp/tf-plugins/

# Take a fresh image
FROM alpine:3.7
MAINTAINER James Laverack <jlaverack@greshamtech.com>

# The Terraform Helm plugin is dynamically linked against glibc, so we need it. See https://github.com/mcuadros/terraform-provider-helm/issues/59
RUN apk update && apk add ca-certificates libc6-compat

# Copy over verified artefacts
COPY --from=downloader /tmp/bin/* /usr/local/bin/
COPY --from=downloader /tmp/tf-plugins/* /.terraform.d/plugins/linux_amd64/
