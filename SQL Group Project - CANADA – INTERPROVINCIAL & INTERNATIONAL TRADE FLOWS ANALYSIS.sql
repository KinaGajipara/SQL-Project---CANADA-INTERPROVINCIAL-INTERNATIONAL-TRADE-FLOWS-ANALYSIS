CREATE TABLE Canada_Trade_Flows
(
    S_No SERIAL PRIMARY KEY,
    Ref_Year INTEGER NOT NULL,
    Geo_ID CHAR(2) NOT NULL,
    Trade_Code VARCHAR(4) NOT NULL,
    Merch_Code VARCHAR(5) NOT NULL,
    CAD_in_Millions MONEY
);

CREATE TABLE Trades
(
    S_no SERIAL,
    Trade_Code VARCHAR(4) NOT NULL PRIMARY KEY,
    Trade_Type VARCHAR(25)
);

CREATE TABLE Merchandize
(
    S_No SERIAL,
    Merch_Code VARCHAR(5) NOT NULL PRIMARY KEY,
    Merchandize_Items VARCHAR(75),
    Category VARCHAR(10),
    Industry_Type VARCHAR(45)
);

CREATE TABLE Geography
(
    Geo_ID CHAR(2) NOT NULL PRIMARY KEY,
    Geo_Name VARCHAR(25),
    DGUID VARCHAR(11)
);

ALTER TABLE Canada_Trade_Flows
    ADD FOREIGN KEY (Merch_Code)
    REFERENCES Merchandize (Merch_Code) MATCH SIMPLE,
	ADD FOREIGN KEY (Trade_Code)
    REFERENCES Trades (Trade_Code) MATCH SIMPLE,
	ADD FOREIGN KEY (Geo_ID)
    REFERENCES Geography (Geo_ID) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;

-- 1. To Display The Trends In Trade Values During The Year 2019 By Region.
SELECT 
    C.Ref_Year AS Year, 
    G.Geo_Name AS Region, 
    SUM(CAST(C.CAD_in_Millions AS NUMERIC)) AS Total_Trade_Value
FROM 
    Canada_Trade_Flows C
INNER JOIN 
    Geography G ON C.Geo_ID = G.Geo_ID
WHERE
	C.Ref_Year = 2019
GROUP BY 
    C.Ref_Year, G.Geo_Name
ORDER BY 
    C.Ref_Year, G.Geo_Name;

-- 2. To Display The Top 10 Products Contributing To The Trade Over The Years.
SELECT 
    M.Merchandize_Items AS Product, 
    SUM(CAST(C.CAD_in_Millions AS NUMERIC)) AS Total_Trade_Value
FROM 
    Canada_Trade_Flows C
INNER JOIN 
    Merchandize M ON C.Merch_Code = M.Merch_Code
GROUP BY 
    M.Merchandize_Items
ORDER BY 
    Total_Trade_Value DESC
LIMIT 10;

-- 3. To Display The Regional Trade Value Differences Over The Years.
SELECT 
    G.Geo_Name AS Region, 
    SUM(CAST(C.CAD_in_Millions AS NUMERIC)) AS Total_Trade_Value
FROM 
    Canada_Trade_Flows C
INNER JOIN 
    Geography G ON C.Geo_ID = G.Geo_ID
GROUP BY 
    G.Geo_Name
ORDER BY 
    Total_Trade_Value DESC;

-- 4. To Display Comparison Of Economic Changes Between Goods & Services Over The Years.
SELECT 
    C.Ref_Year AS Year, 
    SUM(CASE 
        WHEN M.Category = 'Goods' THEN CAST(C.CAD_in_Millions AS NUMERIC)
        ELSE 0 
    END) AS Goods_Trade_Value,
    SUM(CASE 
        WHEN M.Category = 'Services' THEN CAST(C.CAD_in_Millions AS NUMERIC)
        ELSE 0 
    END) AS Services_Trade_Value
FROM 
    Canada_Trade_Flows C
INNER JOIN 
    Merchandize M ON C.Merch_Code = M.Merch_Code
GROUP BY 
    C.Ref_Year
ORDER BY 
    C.Ref_Year;

-- 5. To Display The Total Count, Sum & Average Of Each Trade Type Over The Years.
SELECT 
    T.Trade_Type, 
    COUNT(C.Trade_Code) AS Total_Trade_Transactions, 
    SUM(CAST(C.CAD_in_Millions AS NUMERIC)) AS Trade_Values,
    ROUND(SUM(CAST(C.CAD_in_Millions AS NUMERIC)) / COUNT(C.Trade_Code), 2) AS Average_Trade_Values
FROM 
    Canada_Trade_Flows C
INNER JOIN 
    Trades T ON C.Trade_Code = T.Trade_Code
GROUP BY 
    T.Trade_Type

-- 6. To Display Total Trade Value Variations Over The Years by Region.
SELECT 
    COALESCE(G.Geo_Name, 'Total') AS Region, 
    SUM(CASE WHEN C.Ref_Year = 2017 THEN CAST(C.CAD_in_Millions AS NUMERIC) ELSE 0 END) AS "2017",
    SUM(CASE WHEN C.Ref_Year = 2018 THEN CAST(C.CAD_in_Millions AS NUMERIC) ELSE 0 END) AS "2018",
    SUM(CASE WHEN C.Ref_Year = 2019 THEN CAST(C.CAD_in_Millions AS NUMERIC) ELSE 0 END) AS "2019",
    SUM(CASE WHEN C.Ref_Year = 2020 THEN CAST(C.CAD_in_Millions AS NUMERIC) ELSE 0 END) AS "2020",
    SUM(CASE WHEN C.Ref_Year = 2021 THEN CAST(C.CAD_in_Millions AS NUMERIC) ELSE 0 END) AS "2021"
FROM 
    Canada_Trade_Flows C
INNER JOIN 
    Geography G ON C.Geo_ID = G.Geo_ID
GROUP BY 
    ROLLUP(G.Geo_Name)
ORDER BY 
    G.Geo_Name;

-- 7. To Display The Total Count Of Products Traded by Region
SELECT 
    G.Geo_Name AS Region,
    COUNT(DISTINCT M.Merch_Code) AS Product_Count
FROM 
    Canada_Trade_Flows C
INNER JOIN 
    Geography G ON C.Geo_ID = G.Geo_ID
INNER JOIN 
    Merchandize M ON C.Merch_Code = M.Merch_Code
GROUP BY 
    G.Geo_Name
ORDER BY 
    Product_Count DESC;

-- 8. To Display The Total Trade Values & Its Contribution In Percentage Specifically For British Columbia & Newfoundland and Labrador.
WITH Trade_Type_Percentage AS (
    SELECT 
        G.Geo_Name AS Region,
        T.Trade_Type AS TradeType,
        SUM(CAST(C.CAD_in_Millions AS NUMERIC)) AS Total_Trade_Value,
        ROUND(
            (SUM(CAST(C.CAD_in_Millions AS NUMERIC)) * 100.0) / 
            (SELECT SUM(CAST(CAD_in_Millions AS NUMERIC))
             FROM Canada_Trade_Flows C2
             INNER JOIN Geography G2 ON C2.Geo_ID = G2.Geo_ID
             WHERE G2.Geo_Name = G.Geo_Name),
            2
        ) AS Contribution_Percentage
    FROM 
        Canada_Trade_Flows C
    INNER JOIN 
        Geography G ON C.Geo_ID = G.Geo_ID
    INNER JOIN 
        Trades T ON C.Trade_Code = T.Trade_Code
    WHERE 
        G.Geo_Name IN ('British Columbia', 'Newfoundland and Labrador')
    GROUP BY 
        G.Geo_Name, T.Trade_Type
)
SELECT 
    Region, TradeType, Total_Trade_Value, Contribution_Percentage
FROM 
    Trade_Type_Percentage
ORDER BY 
    Region, Contribution_Percentage DESC;

-- 9. To Display The Top 3 Provinces for International Exports In Each Year
SELECT 
    Year,
    Province,
    Total_Trade_Value,
    Rank
FROM (
    SELECT 
        C.Ref_Year AS Year,
        G.Geo_Name AS Province,
        SUM(CAST(C.CAD_in_Millions AS NUMERIC)) AS Total_Trade_Value,
        RANK() OVER (PARTITION BY C.Ref_Year ORDER BY SUM(CAST(C.CAD_in_Millions AS NUMERIC)) DESC) AS Rank
    FROM 
        Canada_Trade_Flows C
    INNER JOIN 
        Geography G ON C.Geo_ID = G.Geo_ID
    INNER JOIN 
        Trades T ON C.Trade_Code = T.Trade_Code
    WHERE 
        T.Trade_Type = 'International Exports'  -- Filter for International Exports only
    GROUP BY 
        C.Ref_Year, G.Geo_Name
) AS ranked_trades
WHERE 
    Rank <= 3  -- Only top 3 provinces
ORDER BY 
    Year, Rank;

-- 10. To Display The Total Trade Value of Each Provinces Over The Years Into A Categorical Trade Bins (Low, Medium, High)
WITH Cumulative_Trade AS (
    SELECT 
        G.Geo_Name AS Province, 
        SUM(CAST(C.CAD_in_Millions AS NUMERIC)) AS Total_Trade_Value
    FROM 
        Canada_Trade_Flows C
    INNER JOIN 
        Geography G ON C.Geo_ID = G.Geo_ID
    GROUP BY 
        G.Geo_Name
)
SELECT 
    Province, 
    Total_Trade_Value,
    WIDTH_BUCKET(Total_Trade_Value, 0, 10000000, 3) AS Trade_Bin,
    CASE 
        WHEN WIDTH_BUCKET(Total_Trade_Value, 0, 10000000, 3) = 1 THEN 'Low Trade'
        WHEN WIDTH_BUCKET(Total_Trade_Value, 0, 10000000, 3) = 2 THEN 'Medium Trade'
        WHEN WIDTH_BUCKET(Total_Trade_Value, 0, 10000000, 3) = 3 THEN 'High Trade'
    END AS Trade_Category
FROM 
    Cumulative_Trade
ORDER BY 
    Total_Trade_Value DESC;

-- 11. To Display The Total Trade Value For Each Industry Type For International Exports In The Alberta Province Over The Years.
SELECT 
    M.Industry_Type AS Industry,
    SUM(CAST(C.CAD_in_Millions AS NUMERIC)) AS Total_Trade_Value
FROM 
    Canada_Trade_Flows C
INNER JOIN 
    Geography G ON C.Geo_ID = G.Geo_ID
INNER JOIN 
    Trades T ON C.Trade_Code = T.Trade_Code
INNER JOIN 
    Merchandize M ON C.Merch_Code = M.Merch_Code
WHERE 
    G.Geo_Name = 'Alberta' 
    AND T.Trade_Type = 'International Exports'
GROUP BY 
    M.Industry_Type
