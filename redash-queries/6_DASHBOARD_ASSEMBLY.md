# Redash Dashboard Assembly Cheat Sheet

Follow this order. Check off each step as you go.

---

## A. Create Each Query in Redash

For each SQL file, do: **Create > Query > paste SQL > Execute > Save**

| File | Redash Query Name | Then Add Visualizations |
|------|------------------|------------------------|
| `1_summary_counters.sql` | CB Summary Counters | 6 Counters (see config in SQL comments) |
| `2_level_distribution.sql` | CB Level Distribution | 1 Bar Chart (X=level, Y=count) |
| `3_pdr_distribution.sql` | CB PDR Distribution | 1 Pie Chart (X=pdr_bucket, Y=count) |
| `4_promotion_candidates.sql` | CB Promotion Candidates | Default Table (no extra config) |
| `5_needs_attention.sql` | CB Needs Attention | Default Table (no extra config) |

**For queries 4 and 5**: Copy your boss's full original query, then replace ONLY the final `SELECT ... FROM base ...` block with the SELECT from the SQL file.

---

## B. Create the Dashboard

1. Click **Create > Dashboard**
2. Name: `CB Progress Tracker`
3. Click **pencil icon** (top right) to enter edit mode

---

## C. Add Widgets (in this order)

Click **"Add Widget"** for each. Search by query name, pick the visualization.

### Row 1 — Counters (drag side by side, make each narrow)

| Widget | Query to search | Visualization to pick |
|--------|----------------|----------------------|
| 1 | CB Summary Counters | Total CBs |
| 2 | CB Summary Counters | Active |
| 3 | CB Summary Counters | Disabled |
| 4 | CB Summary Counters | Avg PDR |
| 5 | CB Summary Counters | Avg QMS |
| 6 | CB Summary Counters | Avg Throughput |

### Row 2 — Charts (half width each, side by side)

| Widget | Query to search | Visualization to pick |
|--------|----------------|----------------------|
| 7 | CB Level Distribution | Chart (bar) |
| 8 | CB PDR Distribution | Chart (pie) |

### Row 3 — Promotion Candidates (full width)

| Widget | Query to search | Visualization to pick |
|--------|----------------|----------------------|
| 9 | CB Promotion Candidates | Table |

### Row 4 — Needs Attention (full width)

| Widget | Query to search | Visualization to pick |
|--------|----------------|----------------------|
| 10 | CB Needs Attention | Table |

### Row 5 — Full Data (full width, optional)

| Widget | Query to search | Visualization to pick |
|--------|----------------|----------------------|
| 11 | (your boss's original query name) | Table |

---

## D. Resize & Arrange

- Drag counters to be narrow and in one row
- Charts should each take half the width
- Tables should be full width
- Click **"Done Editing"** when finished

---

## E. Set Auto-Refresh

1. Look for the **clock icon** (top right of dashboard)
2. Set to **Every 12 hours** or **Every 24 hours**

---

## Done!

Your dashboard layout should look like this:

```
┌────────┬────────┬──────────┬─────────┬─────────┬──────────────┐
│Total CB│ Active │ Disabled │ Avg PDR │ Avg QMS │ Avg Thruput  │
├────────┴───┬────┴──────────┴─────────┴─────────┴──────────────┤
│ Level Bar  │  PDR Pie Chart                                   │
├────────────┴──────────────────────────────────────────────────┤
│ Promotion Candidates                                          │
├───────────────────────────────────────────────────────────────┤
│ Needs Attention                                               │
├───────────────────────────────────────────────────────────────┤
│ Full Contributor Data (original query)                        │
└───────────────────────────────────────────────────────────────┘
```
