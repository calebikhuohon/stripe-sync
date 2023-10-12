defmodule Fly do
  @moduledoc """
  Fly keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Fly.Billing
  alias Fly.Organizations
  alias Fly.Stripe.Invoice, as: StripeInvoice
  alias Fly.Stripe.InvoiceItem, as: StripeInvoiceItem
  alias Fly.Billing.StripeErrorHandler
  alias Fly.Queue.Producer, as: Queue

  # creates the invoice a day before the due date
  defp generate_invoice_for_organization(organization) do
    case Billing.create_invoice(organization, %{
           invoiced_at: DateTime.utc_now(),
           due_date: Date.utc_today() |> Date.add(1)
         }) do
      {:ok, invoice} ->
        IO.puts("Created invoice #{invoice.id}")

      {:error, changeset} ->
        IO.inspect(changeset, label: "Failed to create invoice")
    end
  end

  # Compile usage data and generate invoices
  def compile_and_generate_invoices do
    organizations = Organizations.list_organizations()

    # start concurrent tasks for each organization
    tasks =
      Enum.map(organizations, fn organization ->
        Task.async(fn ->
          generate_invoice_for_organization(organization)
        end)
      end)

    # wait for all tasks to finish
    Enum.each(tasks, fn task ->
      Task.await(task)
    end)
  end

  def sync_single_invoice(invoice_json) do
    {:ok, invoice} = Jason.decode(invoice_json)

    IO.puts("Syncing invoice #{invoice["id"]}")

    org = Organizations.get_organization!(invoice["organization_id"])
    {:ok, stripe_invoice} = StripeInvoice.create(%{customer: org.stripe_customer_id})


    invoice_items = Billing.list_invoice_items(invoice["id"])

    total = Enum.reduce(invoice_items, 0, fn item, acc ->
      amount = item.amount / 100
      StripeInvoiceItem.create(%{
        invoice: stripe_invoice.id,
        unit_amount_decimal: amount,
        quantity: 1
      })
      acc + amount
    end)


    {:ok, stripe_invoice} = StripeInvoice.update(stripe_invoice, %{total: total})

    invoice_struct = %Fly.Billing.Invoice{} |> Map.merge(invoice)

    Billing.update_invoice(invoice_struct, %{stripe_id: stripe_invoice.id})
  end

  # Fetch invoices due today and queue them
  def fetch_and_queue_due_invoices do
    IO.puts("Fetching invoices due today...")
    # Fetch invoices due today
    invoices_due_today = Billing.get_invoices_due(Date.utc_today())

    # Push each invoice to the queue
    Enum.each(invoices_due_today, fn invoice ->
      Queue.publish(invoice)
    end)

    IO.puts("Invoices due today have been queued.")
  end
end
