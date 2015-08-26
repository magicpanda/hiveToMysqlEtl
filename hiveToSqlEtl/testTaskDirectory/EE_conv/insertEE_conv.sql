--
-- Demo script for inserting some random sessoinIds and visitorIds
--
-- Create the table if needed
USE hiveetl;
--
LOAD DATA LOCAL INFILE 'EE_conv' REPLACE  INTO TABLE EE_conv FIELDS TERMINATED BY '\t';