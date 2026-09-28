"""Embedding generation module using SentenceTransformer all-MiniLM-L6-v2."""

import hashlib
import os
from typing import Any, List, Optional
import numpy as np

# Remove SSLKEYLOGFILE if set by external network tools (e.g. Wireshark) to prevent permission errors
os.environ.pop("SSLKEYLOGFILE", None)

try:
    from sentence_transformers import SentenceTransformer  # noqa: E402
except ImportError:
    SentenceTransformer = None

from .models import MerchantKnowledgeDocument  # noqa: E402

DEFAULT_MODEL_NAME = "all-MiniLM-L6-v2"
EMBEDDING_DIMENSION = 384


class _FallbackEmbeddingModel:
    """Deterministic, lightweight 384-dim text embedder for environments without sentence-transformers."""

    def encode(self, texts, normalize_embeddings: bool = True, show_progress_bar: bool = False):
        is_single = isinstance(texts, str)
        text_list = [texts] if is_single else list(texts)
        results = []
        for t in text_list:
            clean = t.strip().lower()
            tokens = clean.split()
            vec = np.zeros(EMBEDDING_DIMENSION, dtype=np.float32)
            # Bag of character n-grams and tokens hashed into 384 dimensions
            features = list(tokens)
            for tok in tokens:
                for n in range(3, min(6, len(tok) + 1)):
                    for i in range(len(tok) - n + 1):
                        features.append(tok[i:i+n])
            if not features:
                features = ["empty"]
            for f in features:
                h = int(hashlib.md5(f.encode("utf-8")).hexdigest(), 16)
                idx = h % EMBEDDING_DIMENSION
                sign = 1.0 if ((h >> 9) & 1) else -1.0
                vec[idx] += sign
            norm = np.linalg.norm(vec)
            if norm > 0 and normalize_embeddings:
                vec = vec / norm
            results.append(vec)
        arr = np.array(results, dtype=np.float32)
        return arr[0] if is_single else arr


class EmbeddingGenerator:
    """Manages text embedding generation with L2 normalization."""

    _instance: Optional["EmbeddingGenerator"] = None
    _shared_model: Optional[Any] = None
    _shared_model_name: Optional[str] = None

    def __init__(self, model_name: str = DEFAULT_MODEL_NAME, model: Optional[Any] = None):
        self.model_name = model_name
        if model is not None:
            self._model = model
        elif EmbeddingGenerator._shared_model is not None and EmbeddingGenerator._shared_model_name == model_name:
            self._model = EmbeddingGenerator._shared_model
        else:
            if SentenceTransformer is not None:
                try:
                    self._model = SentenceTransformer(model_name)
                except Exception:
                    self._model = _FallbackEmbeddingModel()
            else:
                self._model = _FallbackEmbeddingModel()
            EmbeddingGenerator._shared_model = self._model
            EmbeddingGenerator._shared_model_name = model_name

    @property
    def dimension(self) -> int:
        """Returns the embedding vector dimension."""
        return EMBEDDING_DIMENSION

    def encode_text(self, text: str) -> np.ndarray:
        """Encodes a single text query into a 1D normalized float32 numpy array."""
        clean_text = text.strip() if text else ""
        vec = self._model.encode(clean_text, normalize_embeddings=True, show_progress_bar=False)
        vec = np.asarray(vec, dtype=np.float32)
        norm = np.linalg.norm(vec)
        if norm > 0:
            vec = vec / norm
        return vec

    def encode_texts(self, texts: List[str]) -> np.ndarray:
        """Encodes multiple texts into a 2D normalized float32 numpy array of shape (N, dimension)."""
        if not texts:
            return np.empty((0, self.dimension), dtype=np.float32)
        clean_texts = [t.strip() for t in texts]
        vectors = self._model.encode(clean_texts, normalize_embeddings=True, show_progress_bar=False)
        vectors = np.asarray(vectors, dtype=np.float32)
        # Ensure exact L2 unit length
        norms = np.linalg.norm(vectors, axis=1, keepdims=True)
        norms[norms == 0] = 1.0
        return vectors / norms

    def encode_documents(self, documents: List[MerchantKnowledgeDocument]) -> np.ndarray:
        """Extracts searchable text representation from each document and encodes them."""
        texts = [doc.to_searchable_text() for doc in documents]
        return self.encode_texts(texts)
