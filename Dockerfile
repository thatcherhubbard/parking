FROM elixir:1.9.4 AS backend

# Set environment variables for building the application
ENV MIX_ENV=prod
ENV LANG=C.UTF-8

# Install net-tools for debug purposes and supporting libs
RUN apt update && apt install -y argon2 libargon2-0-dev libargon2-0 libtinfo5 build-essential net-tools 

# Install hex and rebar
RUN mix local.hex --force && mix local.rebar --force

# Create the application build directory
RUN mkdir /app
WORKDIR /app

ENV MIX_ENV prod

COPY ./mix.* ./
COPY config config
COPY priv priv

# Fetch the application dependencies and build the application
RUN mix deps.get --only prod
RUN mix deps.compile

FROM node:13 AS frontend

WORKDIR /app

# Copy assets from Phoenix
COPY --from=backend /app/deps/phoenix /deps/phoenix
COPY --from=backend /app/deps/phoenix_html /deps/phoenix_html

# Install dependencies
COPY assets/package.json assets/package-lock.json ./
RUN npm install

# Copy and build out assets
COPY assets ./
RUN npm run deploy

FROM backend AS packager

# Pull in transpiled assets
COPY --from=frontend /priv/static ./priv/static
COPY . /app

# Digest assets and compile application
RUN mix do phx.digest, release

FROM ubuntu:disco

ENV LANG=C.UTF-8

ENV MIX_ENV prod

# Install openssl
RUN apt update && apt install openssl libncurses6 libtinfo5 argon2

RUN mkdir /app
WORKDIR /app

COPY --from=packager /app/_build/prod/rel/parking .

ENTRYPOINT [ "./bin/parking" ]
CMD [ "start" ]
