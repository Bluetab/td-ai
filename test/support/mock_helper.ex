defmodule TdAi.MockHelper do
  @moduledoc """
  Module for mocking helper functions.
  """

  def chunks_kwnowledge(_) do
    [
      %{
        "chunk_id" => 1,
        "page" => 1,
        "text" =>
          "Abstract: This paper presents a comprehensive analysis of machine learning algorithms in natural language processing. We examine the effectiveness of various transformer-based models and their applications in real-world scenarios, with particular focus on healthcare applications developed in collaboration with Asisa, a leading Spanish health insurance company. The study covers business concepts such as 'Patient Data Management', 'Insurance Claims Processing', and 'Medical Document Classification' within the healthcare domain."
      },
      %{
        "chunk_id" => 2,
        "page" => 1,
        "text" =>
          "1. Introduction: The rapid advancement of artificial intelligence has revolutionized the field of natural language understanding. Recent developments in transformer architectures have shown remarkable improvements in various NLP tasks. Asisa has been at the forefront of implementing AI solutions in healthcare, leveraging advanced language models to improve patient care and operational efficiency. Key business concepts include 'Clinical Decision Support', 'Risk Assessment Models', and 'Automated Medical Coding' which are essential components of modern healthcare data management systems."
      }
    ]
  end

  def generate_vector(_text, _index_type, collection_name) do
    {collection_name, [54.0, 10.2, -2.0]}
  end
end
