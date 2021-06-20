CREATE TABLE `storiesTb` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`filename` VARCHAR(150) NOT NULL COLLATE 'utf8mb4_general_ci',
	`score` TINYINT(4) NOT NULL DEFAULT '50',
	`views` INT(11) NOT NULL DEFAULT '1',
	PRIMARY KEY (`id`) USING BTREE,
	UNIQUE INDEX `filename` (`filename`) USING BTREE
)
COMMENT='List of stories used by picker.psgi'
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB
AUTO_INCREMENT=1
;
