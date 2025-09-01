CREATE TABLE IF NOT EXISTS `playtime` (
  `identifier` VARCHAR(64) NOT NULL,
  `seconds` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
