FROM alpine:3.7
MAINTAINER James Laverack <jlaverack@greshamtech.com>

# Install kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl
