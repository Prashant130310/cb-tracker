-- ============================================================
-- QUERY 1: CB Summary Counters
-- ============================================================
-- Name in Redash: "CB Summary Counters"
-- Returns a single row with all summary numbers.
-- Create 6 Counter visualizations from this one query.
--
-- COUNTER CONFIGS (after saving & executing):
--
--   Counter A: "Total CBs"
--     Counter Label:            Total Contributors
--     Counter Value Column:     total_cbs
--     Counter Value Row Number: 1
--     Count Rows:               OFF
--
--   Counter B: "Avg PDR"
--     Counter Label:            Avg QC Defect Rate
--     Counter Value Column:     avg_pdr_pct
--     Counter Value Row Number: 1
--     Count Rows:               OFF
--     Format tab > suffix:      %
--
--   Counter C: "Avg QMS"
--     Counter Label:            Avg QMS Score
--     Counter Value Column:     avg_qms_score
--     Counter Value Row Number: 1
--     Count Rows:               OFF
--
--   Counter D: "Avg Throughput"
--     Counter Label:            Avg Tasks/Day
--     Counter Value Column:     avg_throughput
--     Counter Value Row Number: 1
--     Count Rows:               OFF
--
--   Counter E: "Active"
--     Counter Label:            Active Contributors
--     Counter Value Column:     active_count
--     Counter Value Row Number: 1
--     Count Rows:               OFF
--
--   Counter F: "Disabled"
--     Counter Label:            Disabled
--     Counter Value Column:     disabled_count
--     Counter Value Row Number: 1
--     Count Rows:               OFF
-- ============================================================

WITH active_l30d AS (
    SELECT DISTINCT attempted_by
    FROM public.taskattempts
    WHERE project IN ('698a1576fba6dc7ca0159579')
      AND attempted_at > DATEADD(DAY, -30, CURRENT_TIMESTAMP)
),
base AS (
    SELECT
        u._id AS contributor_id,
        tpe.review_level,
        tpe.disabled
    FROM public.users AS u
    LEFT JOIN public.taskpermissionentries AS tpe ON u._id = tpe.worker
    WHERE u._id IN (SELECT attempted_by FROM active_l30d)
      AND tpe.permission_group IN ('698a1576fba6dc7ca0159572')
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
),
qms AS (
    SELECT
        attempt_user_id,
        AVG(result_number) AS avg_qms
    FROM view.qms_ratings
    WHERE project_id IN ('698a1576fba6dc7ca0159579')
    GROUP BY 1
),
tp AS (
    SELECT
        attempted_by,
        ROUND(COUNT(*) / 7.0, 2) AS avg_tp,
        ROUND(
            (
                IFF(COUNT_IF(CONVERT_TIMEZONE('UTC','America/Los_Angeles', attempted_at::timestamp_ntz)::date = DATEADD('day', -6, TO_DATE(CONVERT_TIMEZONE('America/Los_Angeles', CURRENT_TIMESTAMP())))) > 0, 1, 0) +
                IFF(COUNT_IF(CONVERT_TIMEZONE('UTC','America/Los_Angeles', attempted_at::timestamp_ntz)::date = DATEADD('day', -5, TO_DATE(CONVERT_TIMEZONE('America/Los_Angeles', CURRENT_TIMESTAMP())))) > 0, 1, 0) +
                IFF(COUNT_IF(CONVERT_TIMEZONE('UTC','America/Los_Angeles', attempted_at::timestamp_ntz)::date = DATEADD('day', -4, TO_DATE(CONVERT_TIMEZONE('America/Los_Angeles', CURRENT_TIMESTAMP())))) > 0, 1, 0) +
                IFF(COUNT_IF(CONVERT_TIMEZONE('UTC','America/Los_Angeles', attempted_at::timestamp_ntz)::date = DATEADD('day', -3, TO_DATE(CONVERT_TIMEZONE('America/Los_Angeles', CURRENT_TIMESTAMP())))) > 0, 1, 0) +
                IFF(COUNT_IF(CONVERT_TIMEZONE('UTC','America/Los_Angeles', attempted_at::timestamp_ntz)::date = DATEADD('day', -2, TO_DATE(CONVERT_TIMEZONE('America/Los_Angeles', CURRENT_TIMESTAMP())))) > 0, 1, 0) +
                IFF(COUNT_IF(CONVERT_TIMEZONE('UTC','America/Los_Angeles', attempted_at::timestamp_ntz)::date = DATEADD('day', -1, TO_DATE(CONVERT_TIMEZONE('America/Los_Angeles', CURRENT_TIMESTAMP())))) > 0, 1, 0) +
                IFF(COUNT_IF(CONVERT_TIMEZONE('UTC','America/Los_Angeles', attempted_at::timestamp_ntz)::date = TO_DATE(CONVERT_TIMEZONE('America/Los_Angeles', CURRENT_TIMESTAMP()))) > 0, 1, 0)
            ) / 7.0, 2
        ) AS active_rate
    FROM public.taskattempts
    WHERE project IN ('698a1576fba6dc7ca0159579')
      AND CONVERT_TIMEZONE('UTC','America/Los_Angeles', attempted_at::timestamp_ntz) > DATEADD('day', -7, CONVERT_TIMEZONE('America/Los_Angeles', CURRENT_TIMESTAMP()))
    GROUP BY 1
)
SELECT
    COUNT(*)                                                                                    AS total_cbs,
    ROUND(AVG(b.qc_pdr) * 100, 1)                                                              AS avg_pdr_pct,
    ROUND(AVG(c.avg_qms), 1)                                                                    AS avg_qms_score,
    ROUND(AVG(d.avg_tp), 1)                                                                      AS avg_throughput,
    COUNT(CASE WHEN a.disabled = false AND (d.active_rate >= 0.3 OR d.active_rate IS NULL) THEN 1 END) AS active_count,
    COUNT(CASE WHEN a.disabled = true THEN 1 END)                                                AS disabled_count,
    COUNT(CASE WHEN d.active_rate < 0.3 AND a.disabled = false THEN 1 END)                       AS low_activity_count
FROM base a
LEFT JOIN qc b ON a.contributor_id = b.audited_entity_author_id
LEFT JOIN qms c ON a.contributor_id = c.attempt_user_id
LEFT JOIN tp d ON a.contributor_id = d.attempted_by
