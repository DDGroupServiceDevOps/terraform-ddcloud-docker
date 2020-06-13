# ---------------------------------------------------------------------------------------------------------------------
# Terraform Build Image

# FROM golang:alpine as Build
FROM golang:1.12.1-alpine as Build

ENV TERRAFORM_VERSION=0.12.24
ENV DDCLOUD_VERSION=3.0

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
    # git checkout v${DDCLOUD_VERSION} && \
    git checkout terraform_v12_upgrade && \
    go get github.com/pkg/errors && \
    go get golang.org/x/crypto/pkcs12 && \
    go get github.com/DimensionDataResearch/go-dd-cloud-compute/compute && \
    make dev

## Ansible Provider
WORKDIR $GOPATH/src/github.com/nbering/terraform-provider-ansible
RUN git clone https://github.com/nbering/terraform-provider-ansible.git ./ && \
    make 
#RUN ls -l $GOPATH/bin/
    # git checkout
    #git checkout master && \
#    make
#RUN go get github.com/nbering/terraform-provider-ansible && \
##    cd $GOPATH/src/github.com/nbering/terraform-provider-ansible && \
##   make


# ---------------------------------------------------------------------------------------------------------------------
# Create Minimal Image

FROM alpine
RUN apk add --update git bash openssh curl
COPY --from=build /go/bin/terraform /bin 
COPY --from=build /go/src/github.com/DimensionDataResearch/dd-cloud-compute-terraform/_bin/terraform-provider-ddcloud /bin
COPY --from=build /go/bin/terraform-provider-ansible /bin
COPY --from=build /go/bin/terraform-provider-ansible ~/.terraform.d/plugins

## Kubectl binadry download (The K8s/Helm Terraform providers are not yet able to perform all the configuration required during a deployment)
RUN wget https://storage.googleapis.com/kubernetes-release/release/v1.15.10/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

WORKDIR /bin

ENTRYPOINT ["terraform"]