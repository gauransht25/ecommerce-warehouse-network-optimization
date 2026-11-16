-- Exact enumeration for four candidate sites and six indivisible demand zones.
-- Each search row is one partial assignment. Prune as soon as a site exceeds capacity.
CREATE TEMP VIEW complete_plans AS
WITH RECURSIVE
input AS (
    SELECT s.name, z.id, l.site_id, z.current_site,
           CAST(round(z.weekly_orders * s.demand_multiplier) AS INTEGER) AS orders,
           l.variable_inr, l.delivery_days, w.weekly_capacity, w.fixed_weekly_inr
    FROM scenario s CROSS JOIN zone z
    JOIN lane l ON l.zone_id = z.id
    JOIN warehouse w ON w.id = l.site_id
    WHERE s.blocked_site IS NULL OR s.blocked_site <> l.site_id
),
plans(scenario, step, assignment, active, load1, load2, load3, load4,
      cost, orders, within_2days, weighted_days, is_current) AS (
    SELECT name, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 FROM scenario
    UNION ALL
    SELECT p.scenario, p.step + 1, p.assignment || i.site_id,
           p.active | (1 << (i.site_id - 1)),
           p.load1 + CASE WHEN i.site_id = 1 THEN i.orders ELSE 0 END,
           p.load2 + CASE WHEN i.site_id = 2 THEN i.orders ELSE 0 END,
           p.load3 + CASE WHEN i.site_id = 3 THEN i.orders ELSE 0 END,
           p.load4 + CASE WHEN i.site_id = 4 THEN i.orders ELSE 0 END,
           p.cost + i.orders * i.variable_inr +
               CASE WHEN (p.active & (1 << (i.site_id - 1))) = 0 THEN i.fixed_weekly_inr ELSE 0 END,
           p.orders + i.orders,
           p.within_2days + CASE WHEN i.delivery_days <= 2 THEN i.orders ELSE 0 END,
           p.weighted_days + i.orders * i.delivery_days,
           p.is_current AND i.site_id = i.current_site
    FROM plans p JOIN input i ON i.name = p.scenario AND i.id = p.step + 1
    WHERE i.orders + CASE i.site_id
        WHEN 1 THEN p.load1 WHEN 2 THEN p.load2 WHEN 3 THEN p.load3 ELSE p.load4 END
        <= i.weekly_capacity
)
SELECT p.*, p.within_2days * 1.0 / p.orders AS coverage,
       p.weighted_days * 1.0 / p.orders AS mean_days
FROM plans p WHERE step = (SELECT count(*) FROM zone);

CREATE TEMP VIEW solutions AS
WITH ranked AS (
    SELECT p.*, row_number() OVER (
        PARTITION BY scenario ORDER BY cost, within_2days DESC, weighted_days, assignment
    ) AS preference
    FROM complete_plans p JOIN scenario s ON s.name = p.scenario
    WHERE p.coverage >= s.minimum_2day_share
)
SELECT s.name, p.assignment, p.cost, p.orders, p.coverage, p.mean_days
FROM scenario s LEFT JOIN ranked p ON s.name = p.scenario AND p.preference = 1;
