DELIMITER $$
DROP PROCEDURE IF EXISTS SP_Cria_DB(
	IN v_data        VARCHAR(70), 
    IN v_Tabelas_TMP VARCHAR(100)
);
BEGIN
    IF NOT EXISTS (SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = v_data) THEN
        SET @sql = CONCAT('CREATE DATABASE `', v_data, '`');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('Banco de dados ', v_data, ' criado com sucesso!') AS status_msg;
    ELSE
        SELECT CONCAT('Banco de dados ', v_data, ' já existe.') AS status_msg;
    END IF;
    
    CALL SP_Cria_DB_Tabelas_Teste( v_data, v_Tabelas_TMP );
END $$
DELIMITER ;