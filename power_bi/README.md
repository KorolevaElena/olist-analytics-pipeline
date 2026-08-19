# Olist E-commerce Executive Dashboard

A public, view-only executive dashboard for the Olist Brazilian
e-commerce marketplace. Four pages, each answering a different business
question: overall business pulse, what sells, who sells it, and who buys
it.

## Executive Summary

The one-glance view of business health for the current month.

- **GMV (Gross Merchandise Value)** — the total value of products sold,
  based on item price only (shipping cost is tracked separately and not
  included, so GMV reflects what the marketplace actually earns commission
  on, not what customers pay at checkout).
- **MoM %** — the change versus the previous month.
- **Orders** — number of completed orders in the period.
- **AOV (Average Order Value)** — GMV divided by number of orders; how
  much a typical order is worth.
- **Active Sellers / Active Clients** — sellers or customers with at least
  one order in the current month.
- **Retention Rate** — the share of customers who bought again within a
  rolling 3-month window, rather than buying only once.
- **On-time Delivery** — the share of orders delivered by the date
  promised to the customer.
- **Cancelled Rate** — the share of orders cancelled before delivery.
- **Top Performers** — the categories, sellers, or regions contributing
  the most (or least) GMV in the current month.

## Product / Category Analysis

What's selling, and how healthy the product catalog is.

- **GMV by Category, with MoM %** — which categories are growing or
  shrinking month over month.
- **Catalog Quality — Error level** — the share of products missing
  something a customer needs to make a purchase decision at all: no
  photo, no name, no description, or no category assigned. These are
  treated as urgent fixes.
- **Catalog Quality — Warning level** — the share of products with a
  weaker listing that likely hurts conversion but doesn't block a sale
  outright: a description under 50 characters, or fewer than 3 photos.
- **Overall Catalog Quality** — a single composite score summarizing
  catalog health across both levels above.

## Seller Performance

Who to recognize, and who needs support — with enough detail to tell
*why*, not just *that*.

- **On-time Rate** — the share of that seller's orders delivered by the
  promised date.
- **Seller Rating** — the average customer review score for that seller,
  calculated only from orders containing a single seller and item, so the
  score reflects that seller specifically rather than being blended with
  someone else's order.
- **Delivery process, broken into three stages, each compared to other
  sellers in the same state:**
  - **Dispatch** — time from order placed to the seller handing it off
    for shipping. This is within the seller's control.
  - **Transit** — time the package spends in the shipping network. This
    is mostly outside the seller's control (carrier-driven).
  - **Delay** — the difference between promised and actual delivery date.
    Negative means delivered early (good); positive means late (bad).
- Comparing each stage to the seller's own regional average (rather than
  a single national number) answers "is this seller slow because of how
  they operate, or because their region is generally slower?"

## Customer Analysis

Who the customers are, and how they're distributed.

- **Customer Status** — **new** (first purchase in the current month),
  **active** (purchased within the last 3 months), or **inactive** (no
  purchase in over 3 months).
- **Customers by State** — geographic distribution of the customer base.
- **Avg Installments** — the average number of instalments customers
  choose when paying.
- **Avg Payment Value** — the average amount paid per order.
- **Payment Mix by Status** — how payment method choice (credit card,
  boleto, debit card, voucher) differs between new, active, and inactive
  customers.

## How to read the colors

- **Green** — better than the relevant benchmark (previous month, region
  average, or expected range).
- **Red** — worse than the relevant benchmark.
- **Amber** — worth attention, not yet critical.
- **Grey** — contextual information, not a judgment call.

---

## What the dashboard tells us about the marketplace

Looking at the current numbers together, a few patterns stand out.

**Growth is softening, not just slowing.** Orders are up 2.9% month over
month, but GMV is down 4.6% and AOV is down 7.2% — customers are placing
more orders, but smaller ones. Order volume alone would suggest a healthy
month; GMV and AOV tell the real story: the marketplace is selling more
often, but for less each time.

**Growth is concentrated in a narrow set of winners.** Health & Beauty is
both the top category by GMV and the fastest-growing (+14% MoM), while
several other major categories are shrinking — Watches & Gifts -25%,
Furniture & Decor -9%, Sports & Leisure -7%. A marketplace whose overall
number is propped up by one or two categories is more exposed than one
growing broadly.

**The customer base is built on one-time buyers.** Roughly 73% of
customers are inactive and only about 20% are active, with an overall
retention rate near 4%. This isn't a data error — it reflects how this
type of marketplace tends to work — but it does mean growth is coming
almost entirely from acquiring new customers rather than repeat purchases,
which is a more expensive and less durable way to grow.

**Catalog quality problems sit exactly where they hurt most.** The
categories flagged for catalog fixes (Bed & Bath Table, Health & Beauty,
Sports & Leisure) overlap with the categories driving the most GMV — this
isn't a neglected long tail issue, it's affecting the products customers
already want to buy. Separately, nearly 70% of the catalog has fewer than
3 photos, which is a much larger gap than the smaller set of products
missing a photo entirely.

**Delivery execution is solid on average but uneven seller-to-seller**,
with on-time rates among top sellers ranging from the high 80s to the
mid 90s. The stage-level breakdown suggests dispatch time (within a
seller's control) is often where the gap to their regional peers is
largest — a more specific, more actionable finding than a single
company-wide on-time percentage would give.
