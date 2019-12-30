# mitsu
> Discord gateway client for transferring events to RabbitMQ queue.

## Why elixir
- Built-in scalability.
- Easy to learn.
- Quick and steady.

## Setup (docker, easier way)
To run Mitsu you have to set up the environment variables (`cp .env.dist .env`) & build the Docker container
```docker-compose up -d```

## Setup (local)
To run mitsu install dependencies with `mix deps.get`, supply it with following env variables and start by `mix run --no-halt`
```env
AMQP_HOST="rabbitmq_host"
AMQP_PORT="rabbitmq_port"
AMQP_USER="rabbitmq_user"
AMQP_PASSWORD="rabbitmq_password"
DISCORD_TOKEN="discord_token"
```

## Contributors
[@vocan](https://github.com/vocan) - Project creator, helper and motivator.
[@szymex73](https://github.com/szymex73) - Wrote most of the code.
[@chonsser](https://github.com/chonsser) – Docker implementation.