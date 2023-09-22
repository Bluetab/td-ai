defmodule TdAi.NxServings do
  @moduledoc """
    Server to handle requests to Milvus Database
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def new_model(model_name, opts \\ []),
    do: %{
      model_name: model_name,
      opts: opts
    }

  def calculate_vectors(%{model_name: model_name} = model, texts) do
    {_, tokenizer} = load_serving(model)

    text_inputs =
      for text <- texts do
        Bumblebee.apply_tokenizer(tokenizer, [text], length: 128)
      end

    text_batch = Nx.Batch.concatenate(text_inputs)

    text_results = Nx.Serving.batched_run(String.to_atom(model_name), text_batch)

    for {text_input, i} <- Enum.with_index(text_inputs) do
      text_attention_mask = text_input["attention_mask"]
      text_input_mask_expanded = Nx.new_axis(text_attention_mask, -1)

      text_results.hidden_state[i]
      |> Nx.multiply(text_input_mask_expanded)
      |> Nx.sum(axes: [1])
      |> Nx.divide(Nx.sum(text_input_mask_expanded, axes: [1]))
      |> Scholar.Preprocessing.normalize(norm: :euclidean)
      |> Nx.to_flat_list()
    end
  end

  def model_vector_size(model) do
    {size, _tokenizer} = load_serving(model)
    size
  end

  def load_serving(model),
    do: GenServer.call(__MODULE__, {:load_serving, model}, 600_000)

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:load_serving, %{model_name: model_name} = model}, _, loaded_servings) do
    case Map.get(loaded_servings, model_name) do
      nil ->
        serving = start_serving(model)
        {:reply, serving, Map.put(loaded_servings, model_name, serving)}

      serving ->
        {:reply, serving, loaded_servings}
    end
  end

  defp start_serving(%{model_name: model_name, opts: opts}) do
    batch_size = 10
    defn_options = [compiler: EXLA]

    serving =
      Nx.Serving.new(
        fn _opts ->
          {:ok, model_info} = Bumblebee.load_model({:hf, model_name}, opts)

          {_init_fun, predict_fun} = Axon.build(model_info.model, defn_options)

          inputs_template = %{
            "attention_mask" => Nx.template({batch_size, 128}, :u32),
            "input_ids" => Nx.template({batch_size, 128}, :u32),
            "token_type_ids" => Nx.template({batch_size, 128}, :u32)
          }

          template_args = [Nx.to_template(model_info.params), inputs_template]

          predict_fun = Nx.Defn.compile(predict_fun, template_args, defn_options)

          fn incoming_inputs ->
            inputs = Nx.Batch.pad(incoming_inputs, batch_size - incoming_inputs.size)
            predict_fun.(model_info.params, inputs)
          end
        end,
        batch_size: batch_size
      )

    {:ok, _pid} =
      Supervisor.start_link(
        [
          {Nx.Serving,
           serving: serving,
           name: String.to_atom(model_name),
           batch_timeout: 100,
           batch_size: batch_size}
        ],
        strategy: :one_for_one
      )

    {:ok, %{spec: %{hidden_size: hidden_size}}} = Bumblebee.load_model({:hf, model_name}, opts)
    tokenizer_opts = Keyword.take(opts, [:module])
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_name}, tokenizer_opts)
    {hidden_size, tokenizer}
  end
end

# import TdAi.NxServings

# iex(2)> model_vector_size("all-MiniLM-L6-v2")
# 384
# iex(3)> model_vector_size("paraphrase-MiniLM-L6-v2")
# 384
# iex(4)> model_vector_size("paraphrase-multilingual-mpnet-base-v2")
# 768
# iex(5)> model_vector_size("msmarco-distilbert-base-tas-b")
# 768
# model_vector_size(new_model("all-mpnet-base-v2", module: Bumblebee.Text.Bert, architecture: :base))
# 768
# model_vector_size(new_model("all-MiniLM-L12-v2", module: Bumblebee.Text.Bert, architecture: :base))
# 384
# model_vector_size(new_model("msmarco-distilbert-base-tas-b", module: Bumblebee.Text.Bert, architecture: :base))
# ?
