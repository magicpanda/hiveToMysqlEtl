--
-- Demo script for inserting some random sessoinIds and visitorIds
--
-- Create the table if needed
USE hiveetl;
--
LOAD DATA LOCAL INFILE 'EE_geo' REPLACE  INTO TABLE EE_geo FIELDS TERMINATED BY '\t';