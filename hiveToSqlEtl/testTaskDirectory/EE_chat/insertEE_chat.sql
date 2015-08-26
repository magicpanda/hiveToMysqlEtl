--
-- Demo script for inserting some random sessoinIds and visitorIds
--
-- Create the table if needed
USE hiveetl;
--
LOAD DATA LOCAL INFILE 'EE_chat' REPLACE  INTO TABLE EE_chat FIELDS TERMINATED BY '\t';