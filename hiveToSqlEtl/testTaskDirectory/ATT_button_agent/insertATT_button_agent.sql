--
-- Demo script for inserting some random sessoinIds and visitorIds
--
-- Create the table if needed
USE hiveetl;
--
LOAD DATA LOCAL INFILE 'ATT_button_agent' REPLACE  INTO TABLE ATT_button_agent FIELDS TERMINATED BY '\t';