DELIMITER $
DROP PROCEDURE IF EXISTS SP_Cria_DB_Indices_Moedas;

CREATE PROCEDURE SP_Cria_DB_Indices_Moedas()
BEGIN
    DECLARE v_data        VARCHAR(50);
    -- DECLARE @sql           VARCHAR(255);
    DECLARE v_NomeTabela  VARCHAR(50);
    DECLARE v_NomePrimKey VARCHAR(20); 
    DECLARE v_ID_Tabela   INT;
    DECLARE v_Def_Coluna  TEXT;
    DECLARE v_Def_FN_Key  TEXT;

    SET v_data = 'DB_Indice_Moedas';
    
    IF NOT EXISTS (SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = v_data) THEN
        SET @sql = CONCAT('CREATE DATABASE `', v_data, '`');
        
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('Banco de dados ', v_data, ' criado com sucesso!') AS status_msg;
    ELSE
        SELECT CONCAT('Banco de dados ', v_data, ' já existe.') AS status_msg;
    END IF;

    CALL SP_Tabs_Tmp_Indices_Moedas();
    
    DECLARE v_Tabelas CURSOR FOR
        SELECT ID_Tabela, Nome_Tabela, Nome_PK
        FROM LST_TABELAS
        ORDER BY ID_Tabela;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_NomeTabela = NULL;

    OPEN v_Tabelas;
    table_loop: LOOP
        FETCH v_Tabelas INTO v_ID_Tabela, v_NomeTabela, v_NomePrimKey;
        IF v_NomeTabela IS NULL THEN
            LEAVE table_loop;
        END IF;

        SELECT Nome_DefCampo, Nome_FN_Key INTO v_Def_Coluna, v_Def_FN_Key
        FROM LST_CAMPOS
        WHERE ID_TabelaCampo = v_ID_Tabela;

        SET @sql = CONCAT(
            'CREATE TABLE IF NOT EXISTS `', v_NomeTabela, '` (',
            v_Def_Coluna, ', PRIMARY KEY (`', v_NomePrimKey, '`)'
        );

        IF v_Def_FN_Key IS NOT NULL AND v_Def_FN_Key <> '' THEN
            SET @sql = CONCAT(@sql, ', ', v_Def_FN_Key);
        END IF;

        SET @sql = CONCAT(@sql, ');');

        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP table_loop;

    CLOSE v_Tabelas;
    DROP TEMPORARY TABLE IF EXISTS LST_TABELAS;
    DROP TEMPORARY TABLE IF EXISTS LST_CAMPOS;
END
$
DELIMITER ;