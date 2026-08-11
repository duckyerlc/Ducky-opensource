FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    git \
    openssl \
    ca-certificates \
    libgcc1 \
    lua-cjson \
    libsqlite3-dev \
    sqlite3 \
    procps \
    imagemagick \
    luarocks \
    libssl-dev \
    wget \
    make \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://luarocks.org/releases/luarocks-3.11.1.tar.gz \
    && tar zxpf luarocks-3.11.1.tar.gz \
    && cd luarocks-3.11.1 \
    && ./configure && make && make install \
    && cd .. && rm -rf luarocks-3.11.1*

WORKDIR /app/bot

COPY . .

RUN chmod +x luvi luvit lit

EXPOSE 8001

ENV LUA_CPATH="/usr/local/lib/lua/5.1/?.so;/usr/lib/x86_64-linux-gnu/lua/5.1/?.so;/usr/lib/x86_64-linux-gnu/?.so;;"

CMD ["./luvit", "watchduck.lua"]