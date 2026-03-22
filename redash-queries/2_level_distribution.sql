-- ============================================================
-- QUERY 2: CB Level Distribution
-- ============================================================
-- Name in Redash: "CB Level Distribution"
-- Shows count of contributors per review level (L0, L10, L12).
--
-- VISUALIZATION CONFIG:
--   + New Visualization > Chart
--   Chart Type:  Bar
--   X Column:    level
--   Y Column:    count
-- ============================================================

WITH active_l14d AS (
    SELECT DISTINCT attempted_by
    FROM public.taskattempts
    WHERE project IN ('698a1576fba6dc7ca0159579')
      AND attempted_at > DATEADD(DAY, -14, CURRENT_TIMESTAMP)
)
SELECT
    CONCAT('L', tpe.review_level) AS level,
    COUNT(*) AS count
FROM public.users u
JOIN public.taskpermissionentries tpe ON u._id = tpe.worker
WHERE u._id IN (SELECT attempted_by FROM active_l14d)
  AND tpe.permission_group IN ('698a1576fba6dc7ca0159572')
GROUP BY 1
ORDER BY 1
