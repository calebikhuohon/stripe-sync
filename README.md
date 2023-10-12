# Stripe Sync

`NOTES.md` tells more about the solution!

## Background Information

We have a few apps that handle our infrastructure. Some are Phoenix (Elixir), and some are Rails (Ruby). 
Going forward, we expect to add new features primarily in a Phoenix app. One important thing our backend does is
take care of billing and invoicing:

* Handles billing for a bunch of different things. Invoices are a combination of metered product usage, one-off line items, and recurring subscription fees.
* Generates 10s of thousands of invoices each month.
* Models our global account data with concepts like `Organizations` and `Users`.
* Syncs regular usage data to Stripe, our payment processor, so we can bill developers for their usage.

Our current process for billing developers looks like this: we sync usage data from a variety of sources to Stripe. Then Stripe generates an invoice based on Stripe's knowledge of our products and pricing.
The challenge is that we bill for a whole lot of things in tiny increments, so we need to sync usage data to Stripe _all the time_.

We sync to Stripe so aggressively that we sometimes fail to sync at all, which means we can't tell our users how much they owe.

This strategy of aggressively pushing usage data to Stripe reduces our ability to provide a good developer experience (for the developers who use our platform).

### Install & Setup

#### Install Elixir (and Erlang)

If you don't have Elixir running locally already, we've left some instructions in [INSTALL.md](/INSTALL.md).

#### This app uses Postgres

Postgres is the default database that Phoenix uses. You'll need to have it installed locally to run the app. One way you
could do this is by running it in Docker:

```bash
docker run -d -p 5432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust postgres
```

#### Getting the app running

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
    - `setup` is defined in `mix.exs` under the `alias` function if you're curious what it's doing
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

#### Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

