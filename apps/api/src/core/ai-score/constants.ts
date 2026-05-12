// Constants for the AI similarity-score pipeline.
//
// Centralised here so the admin-reports + ask-ai features (and any future
// caller of `searchSimilarReports`) share a single source of truth for the
// retrieval-K and confidence thresholds.

/** Top-K verified reports retrieved per RAG query. */
export const TOP_K = 5;

/** Number of top results averaged into the confidence score (avg of top-N). */
export const AVG_TOP_K = 3;

/** Cosine similarity at or above which confidence is reported as `high`. */
export const THRESHOLD_HIGH = 0.85;

/** Cosine similarity at or above which confidence is reported as `medium`. */
export const THRESHOLD_MEDIUM = 0.7;
