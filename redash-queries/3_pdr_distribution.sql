-- ============================================================
-- QUERY 3: CB PDR Distribution
-- ============================================================
-- Name in Redash: "CB PDR Distribution"
-- Buckets contributors by QC defect rate.
--
-- VISUALIZATION CONFIG:
--   + New Visualization > Chart
--   Chart Type:  Pie
--   X Column:    pdr_bucket
--   Y Column:    count
-- ============================================================

WITH active_l14d AS (
    SELECT DISTINCT attempted_by
    FROM public.taskattempts
    WHERE project IN ('698a1576fba6dc7ca0159579')
      AND attempted_at > DATEADD(DAY, -14, CURRENT_TIMESTAMP)
),
qc AS (
    SELECT
        audited_entity_author_id,
        COUNT(*) AS qc_n,
        COUNT(CASE WHEN COALESCE(VALIDATION_RESULT, RESULT_NUMERIC) < 3 THEN 1 END) * 1.0
            / COUNT(COALESCE(VALIDATION_RESULT, RESULT_NUMERIC)) AS qc_pdr
    FROM view.rlhf_quality_control_audit_full
    WHERE is_gqa_audit = TRUE
      AND completed_audit = TRUE
      AND project_id IN ('698a1576fba6dc7ca0159579')
    GROUP BY 1
)
SELECT
    CASE
        WHEN b.qc_pdr IS NULL OR b.qc_n = 0 THEN 'No QC Data'
        WHEN b.qc_pdr = 0 THEN 'Clean (0%)'
        WHEN b.qc_pdr < 0.2 THEN 'Low (1-19%)'
        WHEN b.qc_pdr < 0.4 THEN 'Moderate (20-39%)'
        ELSE 'High (40%+)'
    END AS pdr_bucket,
    COUNT(*) AS count
FROM active_l14d a
LEFT JOIN qc b ON a.attempted_by = b.audited_entity_author_id
GROUP BY 1
ORDER BY count DESC
