# mitsu
> Discord gateway client for transferring events to RabbitMQ queue.

## Why elixir
- Built-in scalability.
- Easy to learn.
- Quick and steady.

## Setup
To run mitsu install dependencies with `mix deps.get`, supply it with following env variables and start by `mix run --no-halt`
```env
AMQP_HOST="rabbitmq_host"
AMQP_USER="rabbitmq_user"
AMQP_PASSWORD="rabbitmq_password"
DISCORD_TOKEN="discord_token"
```

## Contributors
[@vocan](https://github.com/vocan) - Project creator, helper and motivator.
</br>
[@szymex73](https://github.com/szymex73) - Wrote most of the code.
