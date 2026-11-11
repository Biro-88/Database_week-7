-- Week 7 Assignment: Database Design and Normalization
-- File: answer.sql


CREATE DATABASE IF NOT EXISTS week7_normalization;
USE week7_normalization;

-- Clean up so the script can be re-run safely (child tables first)

DROP TABLE IF EXISTS OrderItems;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS OrderDetails;
DROP TABLE IF EXISTS ProductDetail_1NF;
DROP TABLE IF EXISTS ProductDetail;



-- QUESTION 1: Achieving First Normal Form (1NF)


-- Original table (NOT in 1NF): the Products column holds multiple values
-- in one cell, e.g. "Laptop, Mouse".

CREATE TABLE ProductDetail (
    OrderID      INT          NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    Products     VARCHAR(255) NOT NULL,
    PRIMARY KEY (OrderID)
);

INSERT INTO ProductDetail (OrderID, CustomerName, Products) VALUES
(101, 'John Doe',    'Laptop, Mouse'),
(102, 'Jane Smith',  'Tablet, Keyboard, Mouse'),
(103, 'Emily Clark', 'Phone');

-- 1NF table: one product per row, every column holds a single (atomic)
-- value. The composite primary key (OrderID, Product) uniquely
-- identifies each row.
CREATE TABLE ProductDetail_1NF (
    OrderID      INT          NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    Product      VARCHAR(100) NOT NULL,
    PRIMARY KEY (OrderID, Product)
);

-- Insert the normalized records (one row per product per order)
INSERT INTO ProductDetail_1NF (OrderID, CustomerName, Product) VALUES
(101, 'John Doe',    'Laptop'),
(101, 'John Doe',    'Mouse'),
(102, 'Jane Smith',  'Tablet'),
(102, 'Jane Smith',  'Keyboard'),
(102, 'Jane Smith',  'Mouse'),
(103, 'Emily Clark', 'Phone');

-- Verify Question 1
SELECT * FROM ProductDetail_1NF ORDER BY OrderID, Product;





-- QUESTION 2: Achieving Second Normal Form (2NF)


-- Original table (in 1NF, but has a partial dependency).
-- Composite primary key: (OrderID, Product)
CREATE TABLE OrderDetails (
    OrderID      INT          NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    Product      VARCHAR(100) NOT NULL,
    Quantity     INT          NOT NULL,
    PRIMARY KEY (OrderID, Product)
);

INSERT INTO OrderDetails (OrderID, CustomerName, Product, Quantity) VALUES
(101, 'John Doe',    'Laptop',   2),
(101, 'John Doe',    'Mouse',    1),
(102, 'Jane Smith',  'Tablet',   3),
(102, 'Jane Smith',  'Keyboard', 1),
(102, 'Jane Smith',  'Mouse',    2),
(103, 'Emily Clark', 'Phone',    1);

-- Partial dependency identified:
--   OrderID -> CustomerName
-- CustomerName depends only on OrderID (part of the composite key),
-- not on the full key (OrderID, Product). This causes redundancy
-- (e.g. "John Doe" repeated for every product on order 101) and
-- violates 2NF.
--
-- Fix: move CustomerName into its own Orders table, and keep only
-- the attributes that depend on the full key (Quantity) in OrderItems.

-- Orders table: one row per order (CustomerName depends fully on OrderID)
CREATE TABLE Orders (
    OrderID      INT          NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    PRIMARY KEY (OrderID)
);

-- OrderItems table: products and quantities for each order
-- Quantity depends on the whole key (OrderID, Product).
-- OrderID is a foreign key referencing Orders.
CREATE TABLE OrderItems (
    OrderID  INT          NOT NULL,
    Product  VARCHAR(100) NOT NULL,
    Quantity INT          NOT NULL,
    PRIMARY KEY (OrderID, Product),
    CONSTRAINT fk_orderitems_orders
        FOREIGN KEY (OrderID) REFERENCES Orders (OrderID)
);

-- Insert the normalized records.
-- Orders first (parent table), each customer stored once per order:
INSERT INTO Orders (OrderID, CustomerName)
SELECT DISTINCT OrderID, CustomerName
FROM OrderDetails;

-- Then OrderItems (child table):
INSERT INTO OrderItems (OrderID, Product, Quantity)
SELECT OrderID, Product, Quantity
FROM OrderDetails;

-- Verify Question 2
SELECT * FROM Orders ORDER BY OrderID;
SELECT * FROM OrderItems ORDER BY OrderID, Product;

-- Check that the original data can be rebuilt with a JOIN
SELECT o.OrderID, o.CustomerName, i.Product, i.Quantity
FROM Orders o
JOIN OrderItems i ON o.OrderID = i.OrderID
ORDER BY o.OrderID, i.Product;
