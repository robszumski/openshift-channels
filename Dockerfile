FROM nginx
COPY . /usr/share/nginx/html
RUN apt-get update \
    && apt-get install -y git curl
WORKDIR /usr/share/nginx/html
RUN curl -L https://github.com/mikefarah/yq/releases/download/3.2.1/yq_linux_amd64 > yq && chmod +x yq