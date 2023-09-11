import json

from pymilvus import connections
from pymilvus import CollectionSchema, FieldSchema, DataType, Collection
from pymilvus import  utility
from sentence_transformers import SentenceTransformer

from truedat.connect.api import Api, ApiError

from erlport.erlterms import Atom, Map, List
import codecs

def translate(target):
    if isinstance(target, List):
        res = list(target)
        if len(res) > 0:
            return [translate(i) for i in res]
        return res
    elif isinstance(target, Map):
        res = dict(target)
        new = {}
        for k, v in res.items():
            new[translate(k)] = translate(v)
        return new
    elif isinstance(target, Atom):
        return codecs.decode(target)
    elif isinstance(target, str) or isinstance(target, bytes):
        return codecs.decode(target)
    else:
        return target

def load(collection_name, embedding, mapping, config):
    collection_name = translate(collection_name)
    embedding = translate(embedding)
    mapping = translate(mapping)
    config = translate(config)

    print("Connecting to Milvus")
    connections.connect(
      alias=config['milvus']['alias'],
      user=config['milvus']['user'],
      password=config['milvus']['password'],
      host=config['milvus']['host'],
      port=config['milvus']['port']
    )

    print("Connecting to truedat")
    api = Api(
        host=config['api']['host'],
        username=config['api']['username'],
        password=config['api']['password']
    )
    bg = api.get_service("bg")


    print("Loading model")
    model = SentenceTransformer(embedding)
    embedding_dim = model.get_sentence_embedding_dimension()


    print("Creating collection", collection_name)
    if utility.has_collection(collection_name):
        utility.drop_collection(collection_name)

    fields = [
        FieldSchema(name="external_id", dtype=DataType.INT64, is_primary=True, max_length=20),
        FieldSchema(name="name", dtype=DataType.VARCHAR, max_length=200),
        FieldSchema(name="embedding_vector",dtype=DataType.FLOAT_VECTOR,dim=embedding_dim),
    ]

    schema = CollectionSchema(fields=fields,enable_dynamic_field=True)

    collection = Collection(
        name=collection_name,
        schema=schema,
        using='default',
        shards_num=2
    )

    index_params = {
        "metric_type":"L2",
        "index_type":"IVF_FLAT",
        "params":{"nlist":1024}
    }
    
    collection.create_index(
        field_name="embedding_vector", 
        index_params=index_params
    )
    utility.index_building_progress(collection_name)


    print("Fetching concepts")

    query= {"must":{"status":["published"],"template.subscope":""},"sort":[{"name.raw":"asc"}]}

    documents = []
    names = []
    external_id = []
    page = 0

    results = ['not_empty']
    while len(results) > 0:
        try:
            print("Fetching truedat page", page)
            results = bg.concepts(query=query, page=page, size=20)
            for item in results:
                document = {key: item[key] for key in mapping}
                documents.append(str(document))
                names.append(item['name'])
                external_id.append(item["business_concept_id"])
            page += 1
        except Exception:
            break

    print("Calculating embeds")
    embeddings = model.encode(documents)
    data = [external_id, names, embeddings]
    
    print("Inserting data")
    collection.insert(data)
    collection.flush()
    
    connections.disconnect(config['milvus']['alias'])

    return "ok"

    
# load("test", None, None, {'milvus': {
#     "alias": "default",
#     "user": "username",
#     "password": "password",
#     "host": "localhost",
#     "port": "19530"
# }})