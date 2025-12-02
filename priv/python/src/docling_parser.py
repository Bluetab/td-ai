import json
import sys
from docling.document_converter import DocumentConverter
from docling.chunking import HybridChunker
import logging

logging.basicConfig(stream=sys.stderr, level=logging.INFO)


def chunk_doc(doc):
    chunker = HybridChunker()
    chunk_iter = chunker.chunk(dl_doc=doc)

    chunks = []
    for i, chunk in enumerate(chunk_iter):
        text = chunker.contextualize(chunk=chunk)
        page = chunk.meta.doc_items[0].prov[0].page_no
        chunks.append(
            {
                "chunk_id": i,
                "page": page,
                "text": text
            }
        )
    return chunks


def process(file_path: str):
    converter = DocumentConverter()
    doc = converter.convert(file_path).document

    return chunk_doc(doc)


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: docling_parser.py <file_path>")

    file_path = sys.argv[1]
    chunks = process(file_path)
    json.dump(chunks, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
