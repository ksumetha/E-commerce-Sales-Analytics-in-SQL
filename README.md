[README.md](https://github.com/user-attachments/files/35175497/README.md)
# E-commerce Sales Analytics (SQL, MySQL 8.0+)

End-to-end SQL project: schema design, sample data, and analytics using joins, CTEs, window functions,
RFM segmentation, cohort retention and market-basket analysis.

## Run order
1. `01_schema.sql`   - creates database `ecommerce_db` and tables
2. `02_seed_data.sql` - loads sample data
3. `05_views.sql`    - creates reporting views
4. `03_basic_queries.sql`, `04_advanced_analytics.sql` - run the analysis

### MySQL Workbench
File > Open SQL Script > run each file with the lightning button, in the order above.

### Command line
```bash
mysql -u root -p < 01_schema.sql
mysql -u root -p < 02_seed_data.sql
mysql -u root -p < 05_views.sql
mysql -u root -p < 03_basic_queries.sql
mysql -u root -p < 04_advanced_analytics.sql
```
Requires MySQL 8.0+ (window functions and CTEs).
