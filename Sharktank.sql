select * from sharktank

truncate  table sharktank

-- Started_in column was having  null values so while cleaning we had replacednull with "Not_Mentioned"
-- so now we have to change the data type of that column
ALTER TABLE sharktank MODIFY COLUMN Started_in VARCHAR(255);


LOAD DATA INFILE "C:\mysql-files\sharktank.csv"
INTO TABLE sharktank
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

/*You Team must promote shark Tank India season 4, The senior come up with the idea to show highest funding domain wise so 
that new startups can be attracted, and you were assigned the task to show the same.
*/
SELECT
    industry,
    MAX(`Total_Deal_Amount(in_lakhs)`) as "Deal"
FROM
    sharktank
GROUP BY
    industry;

-- or

WITH t2 AS (
    SELECT *
    FROM (
        SELECT
            industry,
            `Total_Deal_Amount(in_lakhs)`,
            ROW_NUMBER() OVER (PARTITION BY industry ORDER BY `Total_Deal_Amount(in_lakhs)` DESC) AS rnk
        FROM
            sharktank
    ) AS t
    WHERE rnk = 1
),
t1 AS (
    SELECT
        industry,
        MAX(`Total_Deal_Amount(in_lakhs)`) AS Max_Investment
    FROM
        sharktank
    GROUP BY
        industry
)
SELECT *
FROM t1
INNER JOIN t2
ON t1.industry = t2.industry;

/*You have been assigned the role of finding the domain where female as pitchers have female to male pitcher ratio >70%
*/

SELECT 
    industry, 
    (female / male) * 100 AS "percent"
FROM (
    SELECT
        industry,
        SUM(Female_Presenters) AS female,
        SUM(Male_Presenters) AS male
    FROM
        sharktank
    GROUP BY
        industry
    HAVING
        SUM(Female_Presenters) > 0 AND SUM(Male_Presenters) > 0
) AS t
WHERE 
    (female / male) * 100 > 70;



/* You are working at marketing firm of Shark Tank India, you have got the task to determine volume of per year sale pitch made,
 pitches who received offer and pitches that were converted. Also show the percentage of pitches converted and percentage of pitches received.
 */
select k.season_number , k.total_pitches , m.pitches_received, ((pitches_received/total_pitches)*100) as 'percentage  pitches received',
 l.pitches_converted ,((pitches_converted/pitches_received)*100) as 'Percentage pitches converted' 
 from
(
		(
		select season_number , count(startup_Name) as 'Total_pitches' from sharktank group by season_number
		)k 
		inner join
		(
		select season_number , count(startup_name) as 'Pitches_Received' from sharktank where received_offer='yes' group by season_number
		)m on k.season_number= m.season_number
		inner join
		(
		select season_number , count(Accepted_offer) as 'Pitches_Converted' from sharktank where  Accepted_offer='Yes' group by  season_number 
		)l on m.season_number= l.season_number
)

/*As a venture capital firm specializing in investing in startups featured on a renowned entrepreneurship TV show,
 you are determining the season with the highest average monthly sales and identify the top 5 industries with the highest
 average monthly sales during that season to optimize investment decisions?
*/
select * from sharktank

set @seas = (select season_number from(
select  season_number , round(avg(`Monthly_Sales(in_lakhs)`),2)as 'average' from sharktank where `Monthly_Sales(in_lakhs)` != 'Not_mentioned'
 group by season_number order by average desc limit 1) as t);
 
 select industry , round(avg(`Monthly_Sales(in_lakhs)`),2)as 'average' from sharktank where Season_Number = @seas group by industry
 order by average desc limit 5
 
 /*As a data scientist at our firm, your role involves solving real-world challenges like identifying industries with
 consistent increases in funds raised over multiple seasons. This requires focusing on industries where data is available
 across all three seasons. Once these industries are pinpointed, your task is to delve into the specifics, analyzing the number
 of pitches made, offers received, and offers converted per season within each industry.*/
 
select * from sharktank

with valid_industry as (
SELECT 
    Industry, 
    MAX(CASE WHEN season_number = 1 THEN `Total_Deal_Amount(in_lakhs)` END) AS 'Season_1',
    MAX(CASE WHEN season_number = 2 THEN `Total_Deal_Amount(in_lakhs)` END) AS 'Season_2',
    MAX(CASE WHEN season_number = 3 THEN `Total_Deal_Amount(in_lakhs)` END) AS 'Season_3'
FROM 
    sharktank 
GROUP BY 
    Industry
HAVING 
    Season_3 > Season_2 AND Season_2 > Season_1 AND Season_1 != 0
 ) 
 
 select b.season_number,
 a.industry,
 count(b.startup_name) as 'total',
 count(case when b.Received_Offer='Yes' then b.startup_name end) as 'received',
count(case when b.Accepted_Offer='Yes' then b.startup_name end) as 'accepted'
 from valid_industry as a inner join sharktank as b on a.industry = b.industry group by  a.industry, b.season_number 
 
 /*Every shark wants to know in how much year their investment will be returned, so you must create a system for them,
 where shark will enter the name of the startup’s and the based on the total deal and equity given in how many years their
 principal amount will be returned and make their investment decisions.
 */
 select   * from sharktank
 
 DELIMITER //
CREATE PROCEDURE tot(IN startup VARCHAR(100))
BEGIN
    CASE 
        WHEN (SELECT Accepted_Offer FROM sharktank WHERE Startup_Name = startup) IN ('No', 'No Offer Received')
            THEN SELECT 'TOT can not be calculated as no offer is accepted or no offer received';
        WHEN (SELECT `Yearly_Revenue(in_lakhs)` FROM sharktank WHERE Startup_Name = startup) = 'Not Mentioned'
            THEN SELECT 'TOT cannot be calculated as no data available';
        ELSE 
            SELECT `Startup_Name`,
                   `Yearly_Revenue(in_lakhs)`,
                   `Total_Deal_Amount(in_lakhs)`,
                   `Total_Deal_Equity(%)`,
                  round((`Total_Deal_Amount(in_lakhs)` / ((`Yearly_Revenue(in_lakhs)` * `Total_Deal_Equity(%)`)/100)),2) AS TOT
            FROM sharktank 
            WHERE Startup_Name = startup;
    END CASE;
END //
DELIMITER ;

drop procedure tot

call tot('BluePineFoods')

/*In the world of startup investing, we're curious to know which big-name investor, often referred to as "sharks,"
 tends to put the most money into each deal on average. This comparison helps us see who's the most generous with their
 investments and how they measure up against their fellow investors.
*/

select * from sharktank

select sharkname, round(avg(investment),2)  as 'average' from
(
SELECT `Namita_Investment_Amount(in lakhs)` AS investment, 'Namita' AS sharkname FROM sharktank WHERE `Namita_Investment_Amount(in lakhs)` > 0
union all
SELECT `Vineeta_Investment_Amount(in_lakhs)` AS investment, 'Vineeta' AS sharkname FROM sharktank WHERE `Vineeta_Investment_Amount(in_lakhs)` > 0
union all
SELECT `Anupam_Investment_Amount(in_lakhs)` AS investment, 'Anupam' AS sharkname FROM sharktank WHERE `Anupam_Investment_Amount(in_lakhs)` > 0
union all
SELECT `Aman_Investment_Amount(in_lakhs)` AS investment, 'Aman' AS sharkname FROM sharktank WHERE `Aman_Investment_Amount(in_lakhs)` > 0
union all
SELECT `Peyush_Investment_Amount((in_lakhs)` AS investment, 'peyush' AS sharkname FROM sharktank WHERE `Peyush_Investment_Amount((in_lakhs)` > 0
union all
SELECT `Amit_Investment_Amount(in_lakhs)` AS investment, 'Amit' AS sharkname FROM sharktank WHERE `Amit_Investment_Amount(in_lakhs)` > 0
union all
SELECT `Ashneer_Investment_Amount` AS investment, 'Ashneer' AS sharkname FROM sharktank WHERE `Ashneer_Investment_Amount` > 0
)k group by sharkname


/*Develop a stored procedure that accepts inputs for the season number and the name of a shark. 
The procedure will then provide detailed insights into the total investment made by that specific shark across different 
industries during the specified season. Additionally, it will calculate the percentage of their investment in each sector
 relative to the total investment in that year, giving a comprehensive understanding of the shark's investment distribution
 and impact.*/
 select * from sharktank
 
 DELIMITER //

CREATE PROCEDURE shark_investment_details(IN seas INT, IN shark VARCHAR(100))
BEGIN
    DECLARE total_investment DECIMAL(10, 2);
    
    -- Calculate the total investment made by the specified shark in the given season
    SET total_investment = (
        CASE
            WHEN shark = 'Namita' THEN 
                (SELECT SUM(`Namita_Investment_Amount(in lakhs)`) 
                 FROM sharktank 
                 WHERE Season_Number = seas AND `Namita_Investment_Amount(in lakhs)` > 0)
            WHEN shark = 'Vineeta' THEN 
                (SELECT SUM(`Vineeta_Investment_Amount(in_lakhs)`) 
                 FROM sharktank 
                 WHERE Season_Number = seas AND `Vineeta_Investment_Amount(in_lakhs)` > 0)
            WHEN shark = 'Anupam' THEN 
                (SELECT SUM(`Anupam_Investment_Amount(in_lakhs)`) 
                 FROM sharktank 
                 WHERE Season_Number = seas AND `Anupam_Investment_Amount(in_lakhs)` > 0)
            WHEN shark = 'Aman' THEN 
                (SELECT SUM(`Aman_Investment_Amount(in_lakhs)`) 
                 FROM sharktank 
                 WHERE Season_Number = seas AND `Aman_Investment_Amount(in_lakhs)` > 0)
            WHEN shark = 'Peyush' THEN 
                (SELECT SUM(`Peyush_Investment_Amount((in_lakhs)`) 
                 FROM sharktank 
                 WHERE Season_Number = seas AND `Peyush_Investment_Amount((in_lakhs)` > 0)
            WHEN shark = 'Amit' THEN 
                (SELECT SUM(`Amit_Investment_Amount(in_lakhs)`) 
                 FROM sharktank 
                 WHERE Season_Number = seas AND `Amit_Investment_Amount(in_lakhs)` > 0)
            WHEN shark = 'Ashneer' THEN 
                (SELECT SUM(`Ashneer_Investment_Amount`) 
                 FROM sharktank 
                 WHERE Season_Number = seas AND `Ashneer_Investment_Amount` > 0)
            ELSE 0
        END
    );
    -- Provide detailed insights and calculate the percentage of investment in each sector
    CASE
        WHEN shark = 'Namita' THEN
            SELECT Industry, 
                   SUM(`Namita_Investment_Amount(in lakhs)`) AS investment,
                   ROUND((SUM(`Namita_Investment_Amount(in lakhs)`) / total_investment) * 100, 2) AS investment_percentage
            FROM sharktank 
            WHERE Season_Number = seas AND `Namita_Investment_Amount(in lakhs)` > 0
            GROUP BY Industry;
        WHEN shark = 'Vineeta' THEN
            SELECT Industry, 
                   SUM(`Vineeta_Investment_Amount(in_lakhs)`) AS investment,
                   ROUND((SUM(`Vineeta_Investment_Amount(in_lakhs)`) / total_investment) * 100, 2) AS investment_percentage
            FROM sharktank 
            WHERE Season_Number = seas AND `Vineeta_Investment_Amount(in_lakhs)` > 0
            GROUP BY Industry;
        WHEN shark = 'Anupam' THEN
            SELECT Industry, 
                   SUM(`Anupam_Investment_Amount(in_lakhs)`) AS investment,
                   ROUND((SUM(`Anupam_Investment_Amount(in_lakhs)`) / total_investment) * 100, 2) AS investment_percentage
            FROM sharktank 
            WHERE Season_Number = seas AND `Anupam_Investment_Amount(in_lakhs)` > 0
            GROUP BY Industry;
        WHEN shark = 'Aman' THEN
            SELECT Industry, 
                   SUM(`Aman_Investment_Amount(in_lakhs)`) AS investment,
                   ROUND((SUM(`Aman_Investment_Amount(in_lakhs)`) / total_investment) * 100, 2) AS investment_percentage
            FROM sharktank 
            WHERE Season_Number = seas AND `Aman_Investment_Amount(in_lakhs)` > 0
            GROUP BY Industry;
        WHEN shark = 'Peyush' THEN
            SELECT Industry, 
                   SUM(`Peyush_Investment_Amount((in_lakhs)`) AS investment,
                   ROUND((SUM(`Peyush_Investment_Amount((in_lakhs)`) / total_investment) * 100, 2) AS investment_percentage
            FROM sharktank 
            WHERE Season_Number = seas AND `Peyush_Investment_Amount((in_lakhs)` > 0
            GROUP BY Industry;
        WHEN shark = 'Amit' THEN
            SELECT Industry, 
                   SUM(`Amit_Investment_Amount(in_lakhs)`) AS investment,
                   ROUND((SUM(`Amit_Investment_Amount(in_lakhs)`) / total_investment) * 100, 2) AS investment_percentage
            FROM sharktank 
            WHERE Season_Number= seas AND `Amit_Investment_Amount(in_lakhs)` > 0
            GROUP BY Industry;
        WHEN shark = 'Ashneer' THEN
            SELECT Industry, 
                   SUM(`Ashneer_Investment_Amount`) AS investment,
                   ROUND((SUM(`Ashneer_Investment_Amount`) / total_investment) * 100, 2) AS investment_percentage
            FROM sharktank 
            WHERE Season_Number = seas AND `Ashneer_Investment_Amount` > 0
            GROUP BY Industry;
        ELSE
            SELECT 'Invalid shark name' AS message;
    END CASE;
END //

DELIMITER ;

call shark_investment_details(3,'Amit')

/*In the realm of venture capital, we're exploring which shark possesses the most diversified investment portfolio 
across various industries. By examining their investment patterns and preferences, we aim to uncover any discernible 
trends or strategies that may shed light on their decision-making processes and investment philosophies*/


DELIMITER //

CREATE PROCEDURE calculate_shark_diversity()
BEGIN
    DROP TEMPORARY TABLE IF EXISTS shark_investments;
    
    CREATE TEMPORARY TABLE shark_investments AS
    SELECT 
        'Namita' AS shark, 
        Industry, 
        SUM(`Namita_Investment_Amount(in lakhs)`) AS investment 
    FROM sharktank 
    WHERE `Namita_Investment_Amount(in lakhs)` > 0 
    GROUP BY Industry
    UNION ALL
    SELECT 
        'Vineeta' AS shark, 
        Industry, 
        SUM(`Vineeta_Investment_Amount(in_lakhs)`) AS investment 
    FROM sharktank 
    WHERE `Vineeta_Investment_Amount(in_lakhs)` > 0 
    GROUP BY Industry
    UNION ALL
    SELECT 
        'Anupam' AS shark, 
        Industry, 
        SUM(`Anupam_Investment_Amount(in_lakhs)`) AS investment 
    FROM sharktank 
    WHERE `Anupam_Investment_Amount(in_lakhs)` > 0 
    GROUP BY Industry
    UNION ALL
    SELECT 
        'Aman' AS shark, 
        Industry, 
        SUM(`Aman_Investment_Amount(in_lakhs)`) AS investment 
    FROM sharktank 
    WHERE `Aman_Investment_Amount(in_lakhs)` > 0 
    GROUP BY Industry
    UNION ALL
    SELECT 
        'Peyush' AS shark, 
        Industry, 
        SUM(`Peyush_Investment_Amount((in_lakhs)`) AS investment 
    FROM sharktank 
    WHERE `Peyush_Investment_Amount((in_lakhs)` > 0 
    GROUP BY Industry
    UNION ALL
    SELECT 
        'Amit' AS shark, 
        Industry, 
        SUM(`Amit_Investment_Amount(in_lakhs)`) AS investment 
    FROM sharktank 
    WHERE `Amit_Investment_Amount(in_lakhs)` > 0 
    GROUP BY Industry
    UNION ALL
    SELECT 
        'Ashneer' AS shark, 
        Industry, 
        SUM(`Ashneer_Investment_Amount`) AS investment 
    FROM sharktank 
    WHERE `Ashneer_Investment_Amount` > 0 
    GROUP BY Industry;
    
    DROP TEMPORARY TABLE IF EXISTS shark_diversity;
    
    CREATE TEMPORARY TABLE shark_diversity AS
    SELECT 
        shark, 
        SUM(investment) AS total_investment,
        SUM(investment * investment) / (SUM(investment) * SUM(investment)) AS hhi
    FROM shark_investments
    GROUP BY shark;
    
    SELECT 
        shark,
        ROUND(1 - hhi, 4) AS diversity_score
    FROM shark_diversity
    ORDER BY diversity_score DESC;
    
END //

DELIMITER ;

CALL calculate_shark_diversity();


/*Explain the concept of indexes in MySQL. How do indexes improve query performance, and what factors should be 
considered when deciding which columns to index in a database table*/

-- Indexes are query optimizers which optimize searching in dataset directly for the index no searching in whole dataset