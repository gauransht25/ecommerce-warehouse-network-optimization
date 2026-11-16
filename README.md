# E-commerce warehouse network optimization

An operations case for a fictional Indian e-commerce retailer. Use SQLite to choose the least-cost feasible warehouse network and use the workbook to review service, allocation and replenishment. All costs, demand and lane promises are synthetic.

| Weekly case | Modeled cost (INR) | Orders within two days | Mean delivery promise |
|---|---:|---:|---:|
| Current network | 1,636,000 | 81.5% | 1.65 days |
| Minimum cost at 85% target | 1,533,800 | 87.0% | 1.50 days |
| Minimum cost at 90% target | 1,561,100 | 94.9% | 1.58 days |
| Peak demand +15% | 1,726,662 | 100.0% | 1.18 days |
| Delhi outage | Infeasible | — | — |

The base solution saves **INR 102,200 per modeled week (6.2%)** and raises two-day coverage by **5.5 percentage points**. It consolidates North and West in Delhi NCR, keeps South and Central in Bengaluru, and opens Kolkata for East and Northeast. Mumbai is inactive in this solution. Under peak demand, West returns to Mumbai and Central moves there, illustrating the cost of a fourth site and the potential value of flex capacity. The 90% target costs INR 27,300 more than the base plan. Because zones are assigned as whole blocks, coverage jumps above the minimum target.

## Run and inspect

1. Run `python run.py` from this folder with Python 3.10+. It loads `inputs.sql` into in-memory SQLite, runs `optimize.sql`, and writes `scenarios.csv` and `assignments.csv`.
2. Open [Network review.xlsx](Network%20review.xlsx) or import it into Google Sheets using **File → Import → Upload**. The **Network** tab compares the shipped SQL scenario results. Use **Allocation** to inspect the site serving each zone.
3. In **Replenishment**, edit the sample SKU-site demand, lead time, variability and service factor. The workbook recalculates safety stock, reorder point, inventory position and review status. After editing SQL inputs and rerunning, replace the workbook's SQL result rows with the regenerated CSVs to refresh the scenario review.

## Model

For each scenario the optimizer enumerates whole-zone assignments across four candidate sites, pruning as soon as a site would exceed its weekly order capacity. The objective sums active site fixed costs and order-weighted lane costs. Every zone is served once, a blocked site has zero available capacity, and demand-weighted two-day coverage must meet the scenario floor. Ties prefer higher coverage, lower average days and then the assignment key. The Python runner independently reconciles demand, service, site capacity and costs for every reported plan.

Assignment keys are in zone-ID order. Site digits map to Delhi NCR (1), Mumbai (2), Bengaluru (3) and Kolkata (4). Cost is steady-state operating cost. A rollout business case needs inbound cost, transition cost, carrier commitments, lease terms and a SKU-level capacity model. The Delhi outage tests a full blocked-site scenario and points to the need to evaluate surge capacity or temporary SLA rules.

## Inventory and process plan

The replenishment tab uses a continuous-review policy at one SKU and fulfillment site. Safety stock is the service factor times daily demand standard deviation times the square root of replenishment lead time, rounded up. The reorder point adds expected lead-time demand. Inventory position includes inbound units and subtracts backorders. The worksheet assumes independent daily demand and constant lead time. Its illustrative SKU inputs are independent of the order-zone allocation and need recalibration after any routing change.

Pilot East and Northeast inventory in Kolkata before switching routing. Receive and scan stock into assigned pick faces, release work against the dispatch cutoff, confirm order scans at the carrier handoff and route stock discrepancies to cycle count. Track pick-to-ship time, first-pass pick accuracy, and two-day delivered share by zone. Keep these observed measures distinct from lane-based forecasts.
