--
-- Demo script for inserting some random sessoinIds and visitorIds
--
-- Create the table if needed
USE hiveetl;
--
LOAD DATA LOCAL INFILE 'EE_order' REPLACE  INTO TABLE EE_order FIELDS TERMINATED BY '\t';