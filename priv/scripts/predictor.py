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

def predict(params, config):
    params = translate(params)
    config = translate(config)

    collection_name = params["collection_name"]
    embedding = params["embedding"]
    mapping = params["mapping"]
    data_structure_id = params["data_structure_id"]

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
    dd = api.get_service("dd")


    print("Loading model")
    model = SentenceTransformer(embedding)
    embedding_dim = model.get_sentence_embedding_dimension()


    collection = Collection(collection_name)
    collection.load()


    print("Fetching structure")
    item = dd.get_structure(data_structure_id)

    document = {key: item[key] for key in mapping}

    search_param = {
        "anns_field": "embedding_vector",
        "param": {
            "metric_type": "L2",
            "params": {"nprobe": 10},
            "offset": 0
        },
        "limit": 10,
        #"expr": "word_count <= 11000",
    }
            
    query_embedding = model.encode(str(document))
    search_param["data"] = [query_embedding]

    res = collection.search(**search_param)

    results=[]
    for rec in res[0]:
        results.append({
            'id': rec.id,
            'distance': rec.distance
        })

    connections.disconnect(config['milvus']['alias'])

    return results

    
# load("test", None, None, {'milvus': {
#     "alias": "default",
#     "user": "username",
#     "password": "password",
#     "host": "localhost",
#     "port": "19530"
# }})