import pool from "./db.js";

import express from "express";
const app = express();

app.use(express.json());

app.get("/api/templates", async (req, res, next) => {
    const templates = await pool.query(`
        SELECT
            p.title AS parent_title,
            c.title,
            c.hyp_description
        FROM hypothesis_template c
        LEFT JOIN hypothesis_template p
            ON c.parent_id = p.id
        ORDER BY c.domain, c.parent_id NULLS FIRST, c.id;
    `);

    res.status(200).json(templates.rows);
});

app.listen(3000, () => {
    console.log("Server is listening on port: 3000");
});