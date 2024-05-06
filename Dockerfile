FROM golang:latest

SHELL ["/bin/bash", "--login", "-c"]

ARG USERNAME=bot
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update && apt-get install -y curl libssl-dev wget

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

# Install node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN nvm install 21.6.1

# Build bot
ARG BUILD_DIR=/home/$USERNAME/sd-webui-discord
ARG INSTALL_DIR=/home/$USERNAME/discord-bot
ENV INSTALL_DIR=$INSTALL_DIR

COPY --chown=bot:bot --chmod=777 . $BUILD_DIR
RUN export PATH=/usr/local/go/bin:$PATH && $BUILD_DIR/build.sh --api -o $INSTALL_DIR

WORKDIR $INSTALL_DIR

ENTRYPOINT ["./sd-webui-discord"]

