-- HNSW (Hierarchical Navigable Small World) index on report_embeddings for
-- sub-millisecond cosine top-K retrieval. Replaces the bare sequential scan
-- the old IVFFLAT index left behind when it was dropped in
-- `20260502172406_update_schema`. HNSW scales to millions of rows without
-- needing periodic re-cluster — better fit than IVFFLAT for an
-- append-mostly corpus.
--
-- Build params (pgvector defaults; sane for our row count):
--   m = 16              — graph node degree
--   ef_construction = 64 — quality of graph at build time
-- Query-time ef_search defaults to 40; raise to 80 if recall@10 dips.

CREATE INDEX IF NOT EXISTS report_embeddings_hnsw_idx
  ON report_embeddings USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);
