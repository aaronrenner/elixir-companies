defmodule Companies.Companies do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Companies.{PendingChanges, Repo}
  alias Companies.Schema.Company

  @doc """
  Returns the list of paginated companies.

  ## Examples

  iex> all()
  [%Company{}, ...]

  """

  def all(params \\ %{}) do
    page = Map.get(params, "page", "1")
    order = Map.get(params, :order, :name)

    (c in Company)
    |> from()
    |> predicates(params)
    |> order_by(^order)
    |> preload([:industry, :jobs])
    |> Repo.paginate(page: page)
  end

  @doc """
  Simply calls `all/1` with a two level order, so that even in the slight chance we have
  two companies with the exact same time of insertion, they will be ordered with
  id next.
  """
  def recent do
    all(%{order: [desc: :inserted_at, desc: :id]})
  end

  def predicates(query, %{"search" => search_params}) do
    Enum.reduce(search_params, query, &query_predicates/2)
  end

  def predicates(query, _) do
    query
  end

  defp query_predicates({_, ""}, query), do: query

  defp query_predicates({"industry_id", industry_id}, query) when not is_nil(industry_id) do
    from c in query, where: c.industry_id == ^industry_id
  end

  defp query_predicates({"text", text}, query) do
    from c in query, where: ilike(c.name, ^"%#{text}%")
  end

  defp query_predicates(nil, query), do: query

  @doc """
  Returns the total company count

  ## Examples

  iex> count()
  23

  """
  def count do
    query = from c in Company, select: count(c.id)

    Repo.one(query)
  end

  @doc """
  Gets a single company.

  Raises `Ecto.NoResultsError` if the Company does not exist.

  ## Examples

  iex> get!(123)
  %Company{}

  iex> get!(456)
  ** (Ecto.NoResultsError)

  """
  def get!(id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    Company
    |> preload(^preloads)
    |> Repo.get!(id)
  end

  @doc """
  Submits a new company for approval.

  ## Examples

  iex> create(%{field: value}, current_user())
  :ok

  iex> create(%{field: bad_value}, current_user())
  {:error, %Ecto.Changeset{}}

  """
  @spec create(map(), map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, user) do
    %Company{}
    |> Company.changeset(attrs)
    |> PendingChanges.create(:create, user)
  end

  @doc """
  Updates a company.

  ## Examples

  iex> update(company, %{field: new_value})
  {:ok, %Company{}}

  iex> update(company, %{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def update(%Company{} = company, attrs, user) do
    company
    |> Company.changeset(attrs)
    |> PendingChanges.create(:update, user)
  end

  @doc """
  Deletes a Company.

  ## Examples

  iex> delete(company)
  {:ok, %Company{}}

  iex> delete(company)
  {:error, %Ecto.Changeset{}}

  """
  def delete(%Company{} = company, user) do
    PendingChanges.create(company, :delete, user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking company changes.

  ## Examples

  iex> change(company)
  %Ecto.Changeset{source: %Company{}}

  """
  def change(%Company{} = company) do
    Company.changeset(company, %{})
  end
end
