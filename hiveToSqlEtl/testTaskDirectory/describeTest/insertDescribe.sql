--
-- Demo script for inserting some random sessoinIds and visitorIds
--
-- Create the table if needed
USE hiveetl;
--
LOAD DATA LOCAL INFILE 'testDescribe' REPLACE  INTO TABLE testDescribe FIELDS TERMINATED BY '\t';
