CREATE TABLE IF NOT EXISTS `house_plants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `building` varchar(50) DEFAULT NULL,
  `stage` int(11) DEFAULT 1,
  `sort` varchar(50) DEFAULT NULL,
  `gender` varchar(50) DEFAULT NULL,
  `food` int(11) DEFAULT 100,
  `health` int(11) DEFAULT 100,
  `progress` int(11) DEFAULT 0,
  `coords` text DEFAULT NULL,
  `plantid` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `building` (`building`),
  KEY `plantid` (`plantid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Update January 15, 2024
UPDATE `house_plants` SET `stage` = 1 WHERE `stage` = 'stage-a';
UPDATE `house_plants` SET `stage` = 2 WHERE `stage` = 'stage-b';
UPDATE `house_plants` SET `stage` = 3 WHERE `stage` = 'stage-c';
UPDATE `house_plants` SET `stage` = 4 WHERE `stage` = 'stage-d';
UPDATE `house_plants` SET `stage` = 5 WHERE `stage` = 'stage-e';
UPDATE `house_plants` SET `stage` = 6 WHERE `stage` = 'stage-f';
UPDATE `house_plants` SET `stage` = 7 WHERE `stage` = 'stage-g';
ALTER TABLE `house_plants` MODIFY COLUMN `stage` int(11) DEFAULT 1;
