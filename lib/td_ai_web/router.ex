defmodule TdAiWeb.Router do
  use TdAiWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {TdAiWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", TdAiWeb do
    pipe_through(:browser)

    live("/", HomeLive)
  end

  # Other scopes may use custom stacks.
  scope "/api", TdAiWeb do
    pipe_through(:api)

    get "/ping", PingController, :ping

    resources("/indices", IndexController, except: [:new, :edit])
    resources("/predictions", PredictionController, except: [:new, :edit])

    resources "/resource_mappings", ResourceMappingController, except: [:new, :edit]

    resources "/prompts", PromptController, except: [:new, :edit] do
      patch "/set_active", PromptController, :set_active
    end

    resources "/suggestions", SuggestionController, except: [:new, :edit]
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:td_ai, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: TdAiWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
