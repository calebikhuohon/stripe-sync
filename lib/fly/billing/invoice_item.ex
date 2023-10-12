defmodule Fly.Billing.InvoiceItem do
  @moduledoc """
  Invoice Line Items
  """
  use Ecto.Schema
  import Ecto.Changeset

  @cast ~w(
    amount
    description
  )a
  @required ~w(
    amount
  )a

  @derive {Jason.Encoder,
           only: [:id, :description, :amount, :invoice_id, :inserted_at, :updated_at]}

  schema "invoice_items" do
    field :description, :string
    field :amount, :integer

    belongs_to :invoice, Fly.Billing.Invoice

    timestamps()
  end

  @doc false
  def invoice_changeset(invoice, invoice_item, attrs) do
    invoice_item
    |> cast(attrs, @cast)
    |> validate_required(@required)
    |> Ecto.Changeset.put_assoc(:invoice, invoice)
  end
end
