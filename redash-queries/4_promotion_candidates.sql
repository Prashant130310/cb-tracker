-- ============================================================
-- QUERY 4: CB Promotion Candidates (FULL — ready to paste)
-- ============================================================
-- Name in Redash: "CB Promotion Candidates"
-- Shows contributors on track for promotion:
--   PDR < 20%, QMS >= 4, active_rate >= 30%, not disabled
--
-- VISUALIZATION: Default Table is fine.
-- ============================================================

WITH active_l14d AS (
    SELECT DISTINCT attempted_by
    FROM public.taskattempts
    WHERE project IN ('698a1576fba6dc7ca0159579')
      AND attempted_at > DATEADD(DAY, -14, CURRENT_TIMESTAMP)
),
base AS (
    SELECT
        u.email,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        u._id AS contributor_id,
        u.scale_discourse_id AS discourse_id,
        p.name AS direct_assigned_project,
        pp.name AS chose_project,
        tpe.review_level,
        tpe.disabled,
        CASE
            WHEN u.tags ILIKE '%699633c0abe38240bed29c05%' THEN 'skillbench_trusted'
            ELSE 'No Tag'
        END AS tag
    FROM public.users AS u
    LEFT JOIN public.projects AS p ON u.assigned_project_layers[0]:projectId::string = p._id
    LEFT JOIN public.projects AS pp ON u.chosen_project_layer:projectId::string = pp._id
    LEFT JOIN public.taskpermissionentries AS tpe ON u._id = tpe.worker
    WHERE u._id IN (SELECT attempted_by FROM active_l14d)
      AND tpe.permission_group IN ('698a1576fba6dc7ca0159572')
),
call_project AS (
    SELECT DISTINCT
        ta.attempted_by,
        p.name AS project
    FROM public.taskattempts AS ta
    LEFT JOIN public.projects AS p ON p._id = ta.project
    WHERE ta.project IN ('698a1576fba6dc7ca0159579')
      AND ta.attempted_at > DATEADD(DAY, -14, CURRENT_TIMESTAMP)
),
qc_raw AS (
    SELECT
        audited_entity_author_id,
        COALESCE(VALIDATION_RESULT, RESULT_NUMERIC) AS score,
        ROW_NUMBER() OVER (PARTITION BY audited_entity_author_id ORDER BY audit_completed_at_pdt DESC) AS rn
    FROM view.rlhf_quality_control_audit_full
    WHERE is_gqa_audit = TRUE
      AND completed_audit = TRUE
      AND project_id IN ('698a1576fba6dc7ca0159579')
),
qc AS (
    SELECT
        audited_entity_author_id,
        COUNT(*) AS qc_n,
        COUNT(CASE WHEN score < 3 THEN 1 END) * 1.0 / COUNT(score) AS qc_pdr
    FROM qc_raw
    GROUP BY 1
),
recent_qc AS (
    SELECT
        audited_entity_author_id,
        COUNT(CASE WHEN score < 3 THEN 1 END) * 1.0 / COUNT(score) AS last_3_pdr
    FROM qc_raw
    WHERE rn <= 3
    GROUP BY 1
),
qms AS (
    SELECT
        attempt_user_id,
        COUNT(*) AS n_qms,
        AVG(result_number) AS avg_qms
    FROM view.qms_ratings
    WHERE project_id IN ('698a1576fba6dc7ca0159579')
    GROUP BY 1
),
last_qms_raw AS (
    SELECT
        attempt_user_id,
        result_number,
        ROW_NUMBER() OVER (PARTITION BY attempt_user_id ORDER BY qms_created_at DESC) AS rn
    FROM view.qms_ratings
    WHERE project_id IN ('698a1576fba6dc7ca0159579')
),
recent_qms AS (
    SELECT
        attempt_user_id,
        AVG(result_number) AS last_3_qms
    FROM last_qms_raw
    WHERE rn <= 3
    GROUP BY 1
),
tp_base AS (
    SELECT
        attempted_by,
        CONVERT_TIMEZONE('UTC','America/Los_Angeles', attempted_at::timestamp_ntz)::date AS day
    FROM public.taskattempts
    WHERE project IN ('698a1576fba6dc7ca0159579')
      AND CONVERT_TIMEZONE('UTC','America/Los_Angeles', attempted_at::timestamp_ntz) > DATEADD('day', -7, CONVERT_TIMEZONE('America/Los_Angeles', CURRENT_TIMESTAMP()))
),
tz AS (
    SELECT TO_DATE(CONVERT_TIMEZONE('America/Los_Angeles', CURRENT_TIMESTAMP())) AS la_today
),
tp AS (
    SELECT
        b.attempted_by,
        COUNT(*) AS tp_l7d,
        ROUND(COUNT(*) / 7.0, 2) AS avg_tp,
        ROUND(
            (
                IFF(COUNT_IF(b.day = DATEADD('day', -6, t.la_today)) > 0, 1, 0) +
                IFF(COUNT_IF(b.day = DATEADD('day', -5, t.la_today)) > 0, 1, 0) +
                IFF(COUNT_IF(b.day = DATEADD('day', -4, t.la_today)) > 0, 1, 0) +
                IFF(COUNT_IF(b.day = DATEADD('day', -3, t.la_today)) > 0, 1, 0) +
                IFF(COUNT_IF(b.day = DATEADD('day', -2, t.la_today)) > 0, 1, 0) +
                IFF(COUNT_IF(b.day = DATEADD('day', -1, t.la_today)) > 0, 1, 0) +
                IFF(COUNT_IF(b.day = t.la_today) > 0, 1, 0)
            ) / 7.0, 2
        ) AS active_rate
    FROM tp_base b
    CROSS JOIN tz t
    GROUP BY b.attempted_by
)
SELECT
    a.name,
    a.email,
    CONCAT('L', a.review_level) AS level,
    CASE
        WHEN a.review_level = 0  THEN 'Reviewer'
        WHEN a.review_level = 10 THEN 'Reviewer + QM'
        WHEN a.review_level = 12 THEN 'Super-Attempter'
        ELSE 'Attempter'
    END AS role,
    a.tag,
    b.qc_n,
    ROUND(b.qc_pdr * 100, 1)       AS pdr_pct,
    ROUND(c.last_3_pdr * 100, 1)   AS last_3_pdr_pct,
    d.n_qms,
    ROUND(d.avg_qms, 1)            AS avg_qms,
    ROUND(e.last_3_qms, 1)         AS last_3_qms,
    f.tp_l7d,
    f.avg_tp,
    ROUND(f.active_rate * 100, 0)  AS activity_pct
FROM base AS a
LEFT JOIN qc AS b        ON a.contributor_id = b.audited_entity_author_id
LEFT JOIN recent_qc AS c ON a.contributor_id = c.audited_entity_author_id
LEFT JOIN qms AS d       ON a.contributor_id = d.attempt_user_id
LEFT JOIN recent_qms AS e ON a.contributor_id = e.attempt_user_id
LEFT JOIN tp AS f        ON a.contributor_id = f.attempted_by
LEFT JOIN call_project AS g ON a.contributor_id = g.attempted_by
WHERE a.disabled = false
  AND b.qc_pdr IS NOT NULL AND b.qc_pdr < 0.2
  AND d.avg_qms IS NOT NULL AND d.avg_qms >= 4
  AND f.active_rate IS NOT NULL AND f.active_rate >= 0.3
ORDER BY b.qc_pdr ASC, d.avg_qms DESC
