// Constants for the AI similarity-score pipeline.
//
// Centralised here so the admin-reports + ask-ai features (and any future
// caller of `searchSimilarReports`) share a single source of truth for the
// retrieval-K and confidence thresholds.

/** Top-K verified reports retrieved per RAG query. */
export const TOP_K = 5;

/**
 * Number of top results averaged into the secondary `topKAvg` signal used
 * as a tie-breaker when the top-1 similarity falls below the high threshold.
 */
export const AVG_TOP_K = 3;

/** Top-1 cosine similarity at or above which confidence is `high`. */
export const THRESHOLD_HIGH = 0.85;

/** Top-1 cosine similarity at or above which confidence is `medium`. */
export const THRESHOLD_MEDIUM = 0.7;

/**
 * Top-3 average similarity at or above which confidence is bumped to
 * `medium` even when the top-1 is below `THRESHOLD_MEDIUM`. Catches the
 * cluster case where several mid-similarity neighbours collectively
 * indicate a likely scam family.
 */
export const THRESHOLD_TOPK_MEDIUM = 0.75;

/**
 * Minimum number of top-K verified reports sharing the same non-null
 * `scammerId` that triggers a "known offender cluster" bump on the
 * confidence tier (and a score floor). One report sharing a scammer is
 * coincidence; two+ is signal.
 */
export const THRESHOLD_SCAMMER_CLUSTER = 2;

/**
 * Floor applied to `aiScore` when the scammer-cluster rule fires, so the
 * admin queue always shows a triage-worthy number even if the raw cosine
 * happened to be moderate. The dominant signal (top-1 / top-3 avg) still
 * wins when it's higher.
 */
export const SCAMMER_CLUSTER_SCORE_FLOOR = 75;
