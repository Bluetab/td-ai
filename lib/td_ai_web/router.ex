defmodule TdAiWeb.Router do
  use TdAiWeb, :router

  pipeline :api do
    plug(TdCore.Auth.Pipeline.Unsecure)
    plug(:accepts, ["json"])
  end

  pipeline :api_auth do
    plug(TdCore.Auth.Pipeline.Secure)
  end

  scope "/api", TdAiWeb do
    pipe_through(:api)

    get("/ping", PingController, :ping)
  end

  # Other scopes may use custom stacks.
  scope "/api", TdAiWeb do
    pipe_through([:api, :api_auth])

    resources("/actions", ActionController, except: [:new, :edit]) do
      post "/set_active", ActionController, :set_active
    end

    post "/actions/search", ActionController, :search

    post "/actions/me", ActionController, :actions_by_user

    resources("/indices", IndexController, except: [:new, :edit]) do
      post "/enable", IndexController, :enable
      post "/disable", IndexController, :disable
    end

    resources("/predictions", PredictionController, except: [:new, :edit])

    resources "/resource_mappings", ResourceMappingController, except: [:new, :edit]

    resources "/providers", ProviderController, except: [:new, :edit] do
      post "/chat_completion", ProviderController, :chat_completion
    end

    resources "/prompts", PromptController, except: [:new, :edit] do
      patch "/set_active", PromptController, :set_active
    end

    resources "/suggestions", SuggestionController, except: [:new, :edit]
    post "/suggestions/availability_check", SuggestionController, :availability_check
    post "/suggestions/request", SuggestionController, :request

    resources "/knowledges", KnowledgeController, except: [:new, :edit] do
      put "/file", KnowledgeController, :update_file, as: :file
    end

    resources "/translations", TranslationController, except: [:new, :edit]
    post "/translations/availability_check", TranslationController, :availability_check
    post "/translations/request", TranslationController, :request
  end
end
