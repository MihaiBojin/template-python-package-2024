ARG VARIANT
FROM mcr.microsoft.com/devcontainers/python:1-${VARIANT}

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    fzf \
    gnupg2 \
    jq \
    libcrypt-ssleay-perl \
    libnet-ssleay-perl \
    swaks \
    vim \
    ;

RUN scversion="stable" && \
    wget -qO- "https://github.com/koalaman/shellcheck/releases/download/${scversion?}/shellcheck-${scversion?}.linux.x86_64.tar.xz" | tar -xJv && \
    cp "shellcheck-${scversion}/shellcheck" /usr/bin/ && \
    shellcheck --version

# [Optional] Uncomment the next lines to use go get to install anything else you need
USER vscode
