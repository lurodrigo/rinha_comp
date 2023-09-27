FROM elixir:slim

RUN apt update

WORKDIR /rinha

COPY . /rinha/

RUN mix deps.get
RUN mix run

CMD ["mix", "run", "rinha.exs", "run", "/var/rinha/source.rinha.json"]