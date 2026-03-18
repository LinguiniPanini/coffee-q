CREATE TABLE IF NOT EXISTS coffee_orders (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    coffee_type VARCHAR(50) NOT NULL,
    order_status VARCHAR(20) NOT NULL DEFAULT 'created'
);