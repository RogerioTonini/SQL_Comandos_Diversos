DELIMITER $$

DROP PROCEDURE IF EXISTS SP_Cria_DB_Tabelas_Tst $$

CREATE PROCEDURE SP_Cria_DB_Tabelas_Tst(
    IN v_data VARCHAR(100),           -- Nome do banco de dados alvo
    IN v_Tabelas_TMP VARCHAR(100)     -- Nome da procedure que define as tabelas temporárias
)
BEGIN
    -- Variáveis para controle de loop e dados
    DECLARE v_ID_Tabela   INT;
    DECLARE v_NomeTabela  VARCHAR(255);
    DECLARE v_NomePrimKey VARCHAR(255);
    DECLARE v_Def_Coluna  TEXT;
    DECLARE v_Def_FN_Key  TEXT;
    DECLARE done          INT DEFAULT 0;

    -- Variáveis para análise de colunas
    DECLARE v_colunas        TEXT;
    DECLARE v_Col_Nome       VARCHAR(255);
    DECLARE v_Col_Tipo       VARCHAR(50);
    DECLARE v_Col_Tamanho    INT;
    DECLARE v_Tb_Col_Tipo    VARCHAR(50);
    DECLARE v_Tb_Col_Tamanho INT;
    DECLARE v_is_primary_key INT DEFAULT 0;

    -- Cursor para tabelas
    DECLARE cur_tabelas CURSOR FOR
        SELECT ID_Tabela, Nome_Tabela, Nome_PK
        FROM LST_TABELAS
        ORDER BY ID_Tabela;

    -- Handler para fim do cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Executa a procedure que monta as tabelas temporárias
    SET @sql = CONCAT( 'CALL ', v_Tabelas_TMP, '()' );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    OPEN cur_tabelas;
    tabela_loop: LOOP
        FETCH cur_tabelas INTO v_ID_Tabela, v_NomeTabela, v_NomePrimKey;
        IF done THEN
            LEAVE tabela_loop;
        END IF;

        -- Busca definição de colunas e chave estrangeira
        SELECT Nome_DefCampo, Nome_FN_Key INTO v_Def_Coluna, v_Def_FN_Key
        FROM LST_CAMPOS
        WHERE ID_TabelaCampo = v_ID_Tabela;

        -- Verifica se a tabela já existe no banco informado
        IF NOT EXISTS (
            SELECT 1 
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = v_data AND TABLE_NAME = v_NomeTabela ) THEN
            -- Cria a tabela no banco informado
            SET @sql = CONCAT( 
                            'CREATE TABLE `', v_data, '`.`', v_NomeTabela,
                            '` (', v_Def_Coluna, ', PRIMARY KEY (`', v_NomePrimKey, '`)' );
            IF v_Def_FN_Key IS NOT NULL AND v_Def_FN_Key <> '' THEN
                SET @sql = CONCAT( @sql, ', ', v_Def_FN_Key );
            END IF;
            SET @sql = CONCAT( @sql, ')' );
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            -- Salva o LOG na tabela T_alteracoes_LOG
            SET @mensagem = CONCAT( 'Tabela "', v_data, '`.`', v_NomeTabela, '" criada com sucesso.' );
            SELECT @mensagem AS status_msg;
            CALL SP_Grava_Log_Alt_DB( v_NomeTabela, '', '', '', @mensagem );
        ELSE
            -- Se a tabela existir verifica sua estrutura e compara com a estrutura definida no script
            SET v_colunas = v_Def_Coluna;
            coluna_loop: WHILE LENGTH( TRIM( v_colunas ) ) > 0 DO

                -- Extrai a próxima definição de coluna
                SET @pos = LOCATE( ',', v_colunas );
                IF @pos > 0 THEN
                    SET @linha    = TRIM( SUBSTRING( v_colunas, 1, @pos - 1 ) );
                    SET v_colunas = TRIM( SUBSTRING( v_colunas, @pos + 1 ) );
                ELSE
                    SET @linha    = TRIM( v_colunas );
                    SET v_colunas = '';
                END IF;
                SET v_Col_Nome = SUBSTRING_INDEX( SUBSTRING_INDEX( @linha, '`', 2 ), '`', -1 );     -- Extrai nome da coluna (entre crases)
                SET @resto     = TRIM( SUBSTRING( @linha, LENGTH(v_Col_Nome) + 3 ) );               -- Extrai tipo e tamanho do script
                SET v_Col_Tipo = UPPER( SUBSTRING_INDEX( @resto, '(', 1 ) );

                IF LOCATE( '(', @resto ) > 0 THEN
                    SET v_Col_Tamanho = CAST( SUBSTRING_INDEX( SUBSTRING_INDEX( @resto, ')', 1 ), '(', -1 ) AS UNSIGNED );
                ELSE
                    SET v_Col_Tamanho = NULL;
                END IF;

                -- Verifica se a coluna existe na tabela do banco informado
                IF EXISTS (
                    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_SCHEMA = v_data AND TABLE_NAME = v_NomeTabela AND COLUMN_NAME = v_Col_Nome) THEN

                    -- Checa se é chave primária
                    SELECT COUNT(*) INTO v_is_primary_key
                    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
                    WHERE TABLE_SCHEMA = v_data AND TABLE_NAME = v_NomeTabela AND COLUMN_NAME = v_Col_Nome AND CONSTRAINT_NAME = 'PRIMARY';

                    IF v_is_primary_key > 0 THEN
                        ITERATE coluna_loop;
                    END IF;

                    -- Busca tipo e tamanho atuais da coluna
                    SELECT DATA_TYPE, CHARACTER_MAXIMUM_LENGTH INTO v_Tb_Col_Tipo, v_Tb_Col_Tamanho
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_SCHEMA = v_data AND TABLE_NAME = v_NomeTabela AND COLUMN_NAME = v_Col_Nome;

                    -- Compara tipo
                    IF UPPER( v_Tb_Col_Tipo ) = UPPER( v_Col_Tipo ) THEN
                        IF v_Col_Tamanho IS NOT NULL AND v_Tb_Col_Tamanho IS NOT NULL THEN
                            IF v_Col_Tamanho > v_Tb_Col_Tamanho THEN
                                SET @sql = CONCAT( 'ALTER TABLE `', v_data, '`.`', v_NomeTabela, '` MODIFY COLUMN ', @linha );
                                PREPARE stmt FROM @sql;
                                EXECUTE stmt;
                                DEALLOCATE PREPARE stmt;

                                SET @mensagem = CONCAT( 'Coluna "', v_Col_Nome, '" alterada para tamanho ', v_Col_Tamanho );
                                SELECT @mensagem AS status_msg;
                            	CALL SP_Grava_Log_Alt_DB(
                                    v_NomeTabela, v_Col_Nome, 
                                    CONCAT( v_Tb_Col_Tipo, '(', v_Tb_Col_Tamanho, ')' ),
                                    CONCAT( v_Col_Tipo, '(', v_Col_Tamanho, ')' ), 
                                    @mensagem );

                            ELSEIF v_Col_Tamanho < v_Tb_Col_Tamanho THEN
                                SET @mensagem = CONCAT( 'Coluna "', v_Col_Nome, '" não alterada: tamanho menor que o atual.' );
                                SELECT @mensagem AS status_msg;
                                CALL SP_Grava_Log_Alt_DB(
                                    v_NomeTabela, v_Col_Nome, 
                                    CONCAT( v_Tb_Col_Tipo, '(', v_Tb_Col_Tamanho, ')' ),
                                    CONCAT( v_Col_Tipo, '(', v_Col_Tamanho, ')' ), 
                                    @mensagem );
                            END IF;
                        END IF;
                    -- ELSE
                        -- SET @mensagem = CONCAT( 'Coluna "', v_Col_Nome, '" não alterada: tipo diferente ( ', v_Tb_Col_Tipo, ' <> ', v_Col_Tipo, ' ).' );
                        -- SELECT @mensagem AS status_msg;
                        -- CALL SP_Grava_Log_Alt_DB(
                            -- v_NomeTabela, v_Col_Nome, 
                            -- CONCAT( v_Tb_Col_Tipo, '(', v_Tb_Col_Tamanho, ')' ),
                            -- CONCAT( v_Col_Tipo, '(', v_Col_Tamanho, ')' ), 
                            -- @mensagem );
                    END IF;
                ELSE
                    -- Coluna não existe, adiciona ao banco informado
                    SET @sql = CONCAT('ALTER TABLE `', v_data, '`.`', v_NomeTabela, '` ADD COLUMN ', @linha);
                    PREPARE stmt FROM @sql;
                    EXECUTE stmt;
                    DEALLOCATE PREPARE stmt;

                    SET @mensagem = CONCAT( 'Coluna "', v_Col_Nome, '" adicionada à tabela ', v_NomeTabela );
                    SELECT @mensagem AS status_msg;
                    CALL SP_Grava_Log_Alt_DB(
                        v_NomeTabela, v_Col_Nome, 
                        CONCAT( v_Tb_Col_Tipo, '(', v_Tb_Col_Tamanho, ')' ),
                        CONCAT( v_Col_Tipo, '(', v_Col_Tamanho, ')' ), 
                        @mensagem );
                    -- SELECT CONCAT('Coluna "', v_Col_Nome, '" adicionada à tabela ', v_NomeTabela) AS status_msg;
                END IF;
            END WHILE coluna_loop;
        END IF;
    END LOOP tabela_loop;

    CLOSE cur_tabelas;
    DROP TEMPORARY TABLE IF EXISTS LST_TABELAS;
    DROP TEMPORARY TABLE IF EXISTS LST_CAMPOS;
END $$
DELIMITER ;
