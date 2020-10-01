# ---------------------------------------------------------------------------------------------------------------------
# Terraform Build Image

# FROM golang:alpine as Build
FROM golang:1.12.1-alpine as Build

# # Terraform 0.11
# ENV TERRAFORM_VERSION=0.11.14
# ENV DDCLOUD_VERSION=development/v2.0

# Terraform 0.12
ENV TERRAFORM_VERSION=0.12.29
ENV DDCLOUD_VERSION=terraform_v12_upgrade

RUN apk add --update git bash openssh make

ENV TF_DEV=true
ENV TF_RELEASE=true


## Terraform
WORKDIR $GOPATH/src/github.com/hashicorp/terraform
RUN git clone https://github.com/hashicorp/terraform.git ./ && \
    git checkout v${TERRAFORM_VERSION} && \
    /bin/bash scripts/build.sh && \
    ls -l /bin


## DDCloud Provider
WORKDIR $GOPATH/src/github.com/DimensionDataResearch/dd-cloud-compute-terraform
RUN git clone https://github.com/DimensionDataResearch/dd-cloud-compute-terraform.git ./ && \
    git checkout ${DDCLOUD_VERSION} && \
    go get github.com/pkg/errors && \
    go get golang.org/x/crypto/pkcs12 && \
    go get github.com/DimensionDataResearch/go-dd-cloud-compute/compute && \
    make dev

# ---------------------------------------------------------------------------------------------------------------------
# Create Minimal Image 

FROM alpine
RUN apk add --update git bash openssh curl
COPY --from=build /go/bin/terraform /bin 
COPY --from=build /go/src/github.com/DimensionDataResearch/dd-cloud-compute-terraform/_bin/terraform-provider-ddcloud /bin
# COPY --from=build /go/src/github.com/DimensionDataResearch/dd-cloud-compute-terraform/_bin/terraform-provider-ddcloud /bin


RUN wget https://github.com/nbering/terraform-provider-ansible/releases/download/v1.0.3/terraform-provider-ansible-linux_amd64.zip && \
    unzip terraform-provider-ansible-linux_amd64.zip && \
    cp linux_amd64/terraform-provider-ansible_v1.0.3 /bin/terraform-provider-ansible

WORKDIR /bin

ENTRYPOINT ["terraform"]