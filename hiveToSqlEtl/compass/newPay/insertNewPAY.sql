--
-- Demo script for inserting some random sessoinIds and visitorIds
--
-- Create the table if needed
USE track_diagon;
--
LOAD DATA LOCAL INFILE 'newpay' REPLACE  INTO TABLE dau FIELDS TERMINATED BY '\t';