# SpazioSolazzo

Spazio Solazzo is a cultural space in the heart of Palermo where people around the world gather to work, meet or play music.

Spazio Solazzo is managed by the Caravanserai cultural association and is found next to the Mojo Coliving project, which also makes part of Caravanserai.

This project allows Caravanserai to manage the different spaces inside Spazio Solazzo for rent. Spazio Solazzo at the moment is made out of three other spaces:

+ A Coworking space, where people can book desks to work and share during the day.
+ A meeting room that people and companies can book for their own meetings.
+ A music jam space that single musicians and bands can book for their rehearsals and other musical projects.

## Development

This site is build with Elixir.

I've decided to use the [Phoenix](https://www.phoenixframework.org/) web framework together with the [Ash](https://ash-hq.org/) framework,
together they allow me to build a rich interactive website with a rich data model easy to develop, test and maintain.

Personally, Phoenix is my go-to framework for any web projects that require any interactivity and real-time feedback to the users.

Ash helps modeling your domain and business logic in a very straight-forward way that integrates seamlessly with Phoenix.

### Setup DB

First you will need to have Docker and Docker compose installed. See [installation instructions](https://docs.docker.com/compose/install/).

Then, to spin up your local postgres database simply run:

```bash
docker compose up -d
```

### Setup Phoenix project

You'll need to make sure you have Elixir, Erlang and Phoenix installed in your system.

After that, download the dependencies:

```bash
mix deps.get
```

And setup the project with:

```bash
mix setup
```

This should run the DB migrations and seed the DB with mock data.

Now you should be ready to run the tests:

```bash
mix test
```

Or to run the compiler, formatter, tests, credo and more:

```bash
mix precommit
```

Now, to start your Phoenix server:

* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser and you're ready to go!

## License

Copyright 2026 Victor Martinez Montané

Licensed under the Apache License, Version 2.0 (the "License"),
subject to the Commons Clause License Condition v1.0.
You may not use this file except in compliance with the License.

See the [LICENSE](./LICENSE.md) file for details.
