defmodule LogicSimLiveview.Repo do
  use Ecto.Repo,
    otp_app: :logic_sim_liveview,
    adapter: Ecto.Adapters.Postgres
end
