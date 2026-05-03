import { getPrisma } from '../db/client';
import { embed } from '../gemini/client';

export type SimilarReport = {
  reportId: string;
  similarity: number;
};

/**
 * Embeds `text` with Gemini then queries report_embeddings for the
 * top-K cosine-similar verified reports.
 *
 * Returns [] when Gemini returns an empty vector or no embeddings exist.
 * JOIN on reports ensures de-verified reports whose embeddings linger are excluded.
 */
export async function searchSimilarReports(
  text: string,
  topK = 5,
): Promise<SimilarReport[]> {
  const vector = await embed(text);
  if (vector.length === 0) return [];

  const vectorLiteral = `[${vector.join(',')}]`;
  const prisma = getPrisma();

  const rows = await prisma.$queryRaw<{ report_id: string; similarity: number }[]>`
    SELECT re.report_id::text,
           1 - (re.embedding <=> ${vectorLiteral}::vector) AS similarity
    FROM report_embeddings re
    JOIN reports r ON r.id = re.report_id AND r.status = 'verified'
    ORDER BY re.embedding <=> ${vectorLiteral}::vector
    LIMIT ${topK}
  `;

  return rows.map((r) => ({ reportId: r.report_id, similarity: r.similarity }));
}
