"""Run the SQLite model and write the result tables used in the spreadsheet."""
import csv
import math
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def write_csv(name, headers, rows):
    with (ROOT / name).open("w", newline="", encoding="utf-8") as output:
        writer = csv.writer(output)
        writer.writerow(headers)
        writer.writerows(rows)


def main():
    with sqlite3.connect(":memory:") as db:
        for script in ("inputs.sql", "optimize.sql"):
            db.executescript((ROOT / script).read_text(encoding="utf-8"))
        zone_ids = [row[0] for row in db.execute("SELECT id FROM zone ORDER BY id")]
        assert zone_ids == list(range(1, len(zone_ids) + 1)), "Zone IDs must be consecutive."
        assert db.execute("SELECT count(*) FROM lane").fetchone()[0] == len(zone_ids) * 4

        scenarios = db.execute("""
            SELECT name, assignment, cost, orders, coverage, mean_days FROM solutions
        """).fetchall()
        baseline = db.execute("""
            SELECT 'Current network', assignment, cost, orders, coverage, mean_days
            FROM complete_plans WHERE scenario = 'Base' AND is_current
        """).fetchone()
        plans = [baseline, *scenarios]
        write_csv("scenarios.csv", ("Scenario", "Assignment", "Weekly cost INR",
                  "Orders", "Two-day coverage", "Mean days"), plans)
        detail = []
        for name, assignment, cost, orders, coverage, _ in plans:
            if assignment is None:
                continue
            multiplier = 1 if name == "Current network" else db.execute(
                "SELECT demand_multiplier FROM scenario WHERE name = ?", (name,)
            ).fetchone()[0]
            zone_orders = 0
            fast_orders = 0
            variable_cost = 0
            used_sites = set()
            site_loads = {}
            for zone, site in enumerate(assignment, start=1):
                demand, zone_name, site_name, unit_cost, days, capacity = db.execute("""
                    SELECT z.weekly_orders, z.name, w.name, l.variable_inr,
                           l.delivery_days, w.weekly_capacity
                    FROM lane l JOIN zone z ON z.id = l.zone_id
                    JOIN warehouse w ON w.id = l.site_id
                    WHERE l.zone_id = ? AND l.site_id = ?
                """, (zone, site)).fetchone()
                demand = math.floor(demand * multiplier + 0.5)
                site_loads[site] = site_loads.get(site, 0) + demand
                assert site_loads[site] <= capacity
                used_sites.add(site)
                zone_orders += demand
                fast_orders += demand if days <= 2 else 0
                variable_cost += unit_cost * demand
                detail.append((name, zone_name, site_name, demand, unit_cost, days))
            fixed_cost = sum(db.execute(
                "SELECT fixed_weekly_inr FROM warehouse WHERE id = ?", (site,)
            ).fetchone()[0] for site in used_sites)
            assert (zone_orders, fast_orders / zone_orders, variable_cost + fixed_cost) == (
                orders, coverage, cost
            )
        write_csv("assignments.csv", ("Scenario", "Zone", "Warehouse", "Weekly orders",
                  "Variable INR per order", "Modeled delivery days"), detail)
        print(Path(ROOT / "scenarios.csv").read_text(encoding="utf-8"))


if __name__ == "__main__":
    main()
