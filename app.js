
const express = require('express');
const { Pool } = require('pg'); // Postgresql
const app = express();
const PORT = 3000;

const pool = new Pool({
  user: 'postgres',       
  host: 'localhost',      
  database: 'stock',  
  password: '8905502534',   
  port: 5432            
});


app.get('/api/companies/:company_id/alerts/low-stock', async (req, res) => {
  const client = await pool.connect();
  try {
    const { company_id } = req.params;

    const companyResult = await client.query(
      'SELECT * FROM companies WHERE company_id = $1',
      [company_id]
    );
    if (companyResult.rowCount === 0) {
      return res.status(404).json({ error: 'Company not found' });
    }

    const warehouseResult = await client.query(
      'SELECT * FROM warehouses WHERE company_id = $1',
      [company_id]
    );
    if (warehouseResult.rowCount === 0) {
      return res.json({ alerts: [], total_alerts: 0 });
    }
    const warehouseIds = warehouseResult.rows.map(w => w.warehouse_id);

    const recentSalesResult = await client.query(
      `SELECT DISTINCT product_id 
       FROM sales 
       WHERE sale_date >= CURRENT_DATE - INTERVAL '30 days'`
    );
    const activeProductIds = recentSalesResult.rows.map(s => s.product_id);

    //  Get inventory with product and supplier info
    const inventoryQuery = `
      SELECT 
        p.product_id, p.product_name, p.sku, p.product_type,
        w.warehouse_id, w.warehouse_name,
        i.current_stock,
        s.supplier_id, s.supplier_name, s.contact_email,
        st.threshold
      FROM inventory i
      JOIN products p ON i.product_id = p.product_id
      JOIN warehouses w ON i.warehouse_id = w.warehouse_id
      LEFT JOIN product_suppliers ps ON p.product_id = ps.product_id
      LEFT JOIN suppliers s ON ps.supplier_id = s.supplier_id
      LEFT JOIN stock_thresholds st ON p.product_type = st.product_type
      WHERE i.warehouse_id = ANY($1)
    `;
    const inventoryResult = await client.query(inventoryQuery, [warehouseIds]);

    //  Build alert list
    const alerts = [];
    for (let row of inventoryResult.rows) {
      // Skip if product had no recent sales
      if (!activeProductIds.includes(row.product_id)) continue;

      const threshold = row.threshold || 10; // default = 10

      if (row.current_stock < threshold) {
        // Find avg daily sales
        const salesResult = await client.query(
          `SELECT COALESCE(SUM(quantity), 0) AS total_sales
           FROM sales
           WHERE product_id = $1
           AND sale_date >= CURRENT_DATE - INTERVAL '30 days'`,
          [row.product_id]
        );
        const totalSales = parseInt(salesResult.rows[0].total_sales);
        const avgDailySales = totalSales / 30 || 1;
        const daysUntilStockout = Math.ceil(row.current_stock / avgDailySales);

        alerts.push({
          product_id: row.product_id,
          product_name: row.product_name,
          sku: row.sku,
          warehouse_id: row.warehouse_id,
          warehouse_name: row.warehouse_name,
          current_stock: row.current_stock,
          threshold,
          days_until_stockout,
          supplier: row.supplier_id
            ? {
                id: row.supplier_id,
                name: row.supplier_name,
                contact_email: row.contact_email
              }
            : null
        });
      }
    }

  
    return res.json({ alerts, total_alerts: alerts.length });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Server error' });
  } finally {
    client.release(); // release DB connection
  }
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
