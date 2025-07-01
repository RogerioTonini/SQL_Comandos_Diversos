
-- Procedure: SP_Tabs_Tmp_Indices_Moedas
DELIMITER $$
DROP PROCEDURE IF EXISTS SP_Tabs_Tmp_Indices_Moedas;
CREATE PROCEDURE SP_Tabs_Tmp_Indices_Moedas()
BEGIN
    DROP TEMPORARY TABLE IF EXISTS LST_TABELAS;
    DROP TEMPORARY TABLE IF EXISTS LST_CAMPOS;

    CREATE TEMPORARY TABLE LST_TABELAS (
        ID_Tabela INT PRIMARY KEY,
        Nome_Tabela VARCHAR(255),
        Nome_PK VARCHAR(255)
    );

    INSERT INTO LST_TABELAS VALUES
        (1, 'T_Consultas', 'NUM_INDEX'),
        (2, 'T_Moedas', 'NUM_INDEX'),
        (3, 'T_CotacaoMoedas', 'NUM_INDEX');

    CREATE TEMPORARY TABLE LST_CAMPOS (
        ID_TabelaCampo INT PRIMARY KEY,
        Nome_DefCampo TEXT,
        Nome_FN_Key TEXT
    );

    INSERT INTO LST_CAMPOS VALUES
        (1, '`NUM_INDEX` INT AUTO_INCREMENT NOT NULL,
             `NomeConsulta` VARCHAR(50) NOT NULL,
             `Complemento_URL` VARCHAR(100) NOT NULL,
             `Colunas` VARCHAR(100) NOT NULL', ''),

        (2, '`NUM_INDEX` INT AUTO_INCREMENT NOT NULL,
             `Sigla` VARCHAR(3) NOT NULL,
             `NomeMoeda` VARCHAR(40) NOT NULL,
             `TipoMoeda` VARCHAR(1) NOT NULL', ''),

        (3, '`NUM_INDEX` INT AUTO_INCREMENT NOT NULL,
             `DataCotacao` DATE NOT NULL,
             `VlrCompra` DECIMAL(8, 2),
             `VlrVenda` DECIMAL(8, 2),
             `FK_ID_Moeda` INT',
             'FOREIGN KEY (`FK_ID_Moeda`) REFERENCES T_Moedas(`NUM_INDEX`)');
END $$
DELIMITER ;

-- Procedure: SP_Cria_DB_Indices_Moedas
DELIMITER $$
DROP PROCEDURE IF EXISTS SP_Cria_DB_Indices_Moedas;
CREATE PROCEDURE SP_Cria_DB_Indices_Moedas()
BEGIN
    DECLARE v_DATABASE    VARCHAR(50);
    DECLARE v_SQL_Def     TEXT;
    DECLARE v_NomeTabela  VARCHAR(255);
    DECLARE v_NomePrimKey VARCHAR(255); 
    DECLARE v_ID_Tabela   INT;
    DECLARE v_Def_Coluna  TEXT;
    DECLARE v_Def_FN_Key  TEXT;

    SET v_DATABASE = 'DB_Indice_Moedas';

    IF NOT EXISTS (SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = v_DATABASE) THEN
        SET @sql := CONCAT('CREATE DATABASE `', v_DATABASE, '`');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('Banco de dados ', v_DATABASE, ' criado com sucesso!') AS status_msg;
    ELSE
        SELECT CONCAT('Banco de dados ', v_DATABASE, ' já existe.') AS status_msg;
    END IF;

    USE `DB_Indice_Moedas`;

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

        SET v_SQL_Def = CONCAT(
            'CREATE TABLE IF NOT EXISTS `', v_NomeTabela, '` (',
            v_Def_Coluna, ', PRIMARY KEY (`', v_NomePrimKey, '`)'
        );

        IF v_Def_FN_Key IS NOT NULL AND v_Def_FN_Key <> '' THEN
            SET v_SQL_Def = CONCAT(v_SQL_Def, ', ', v_Def_FN_Key);
        END IF;

        SET v_SQL_Def = CONCAT(v_SQL_Def, ');');

        PREPARE stmt FROM v_SQL_Def;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP table_loop;
    CLOSE v_Tabelas;

    DROP TEMPORARY TABLE IF EXISTS LST_TABELAS;
    DROP TEMPORARY TABLE IF EXISTS LST_CAMPOS;
END $$
DELIMITER ;
