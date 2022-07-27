FROM ubuntu:20.04
ENV DEBIAN_FRONTEND "noninteractive"

# Source: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
RUN apt-get update \
    && apt-get install -y curl \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/* \
    && az --version

RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin \
    && trivy -v

RUN trivy filesystem --exit-code 1 --severity HIGH,CRITICAL --no-progress .

CMD bash
