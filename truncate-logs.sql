CREATE EVENT PurgeLogTable
ON SCHEDULE EVERY 1 WEEK
DO
BEGIN
     DELETE FROM `logs` WHERE `LogTime` <= DATE_SUB(CURRENT_TIMESTAMP, 1 WEEK;
     INSERT INTO `audit` (`AuditDate`, `Message`) VALUES(NOW(), "Log table purged successfully!");
END
