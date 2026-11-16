PRAGMA foreign_keys = ON;

CREATE TABLE warehouse (
    id INTEGER PRIMARY KEY CHECK (id BETWEEN 1 AND 4),
    name TEXT UNIQUE NOT NULL,
    weekly_capacity INTEGER NOT NULL CHECK (weekly_capacity > 0),
    fixed_weekly_inr INTEGER NOT NULL CHECK (fixed_weekly_inr >= 0)
);
INSERT INTO warehouse VALUES
    (1,'Delhi NCR',11500,220000), (2,'Mumbai',9500,225000),
    (3,'Bengaluru',10000,205000), (4,'Kolkata',7100,174000);

CREATE TABLE zone (
    id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL,
    weekly_orders INTEGER NOT NULL CHECK (weekly_orders > 0),
    current_site INTEGER NOT NULL REFERENCES warehouse
);
INSERT INTO zone VALUES
    (1,'North',6200,1), (2,'West',4700,2), (3,'South',5900,3),
    (4,'East',3300,1), (5,'Central',3200,2), (6,'Northeast',1250,3);

CREATE TABLE lane (
    zone_id INTEGER REFERENCES zone,
    site_id INTEGER REFERENCES warehouse,
    variable_inr INTEGER NOT NULL CHECK (variable_inr > 0),
    delivery_days INTEGER NOT NULL CHECK (delivery_days > 0),
    PRIMARY KEY (zone_id, site_id)
);
-- Variable cost includes outbound freight and picking. Days represent modeled lane promises.
INSERT INTO lane VALUES
    (1,1,30,1),(1,2,65,3),(1,3,86,4),(1,4,61,3),
    (2,1,52,2),(2,2,31,1),(2,3,49,2),(2,4,76,4),
    (3,1,84,4),(3,2,61,3),(3,3,28,1),(3,4,74,4),
    (4,1,71,3),(4,2,78,4),(4,3,72,4),(4,4,29,1),
    (5,1,43,2),(5,2,39,2),(5,3,55,3),(5,4,44,2),
    (6,1,94,5),(6,2,105,6),(6,3,104,6),(6,4,54,2);

CREATE TABLE scenario (
    name TEXT PRIMARY KEY,
    demand_multiplier REAL NOT NULL CHECK (demand_multiplier > 0),
    minimum_2day_share REAL NOT NULL CHECK (minimum_2day_share BETWEEN 0 AND 1),
    blocked_site INTEGER REFERENCES warehouse
);
INSERT INTO scenario VALUES
    ('Base',1.0,0.85,NULL),('Peak +15%',1.15,0.85,NULL),
    ('90% SLA',1.0,0.90,NULL),('Delhi outage',1.0,0.85,1);
