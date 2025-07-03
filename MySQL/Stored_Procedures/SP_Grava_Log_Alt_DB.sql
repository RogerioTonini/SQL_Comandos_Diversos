DELIMITER $$
DROP PROCEDURE IF EXISTS SP_Grava_Log_Alt_DB;

CREATE PROCEDURE SP_Grava_Log_Alt_DB(
    IN v_LogDB            VARCHAR(100),
    IN v_NomeTabela       VARCHAR(255),
    IN v_NomeColuna       VARCHAR(255),
    IN v_TipoTamExistente VARCHAR(100),
    IN v_TipoTamSugerido  VARCHAR(100),
    IN v_Mensagem         VARCHAR(255)
)
BEGIN
    SET @sql = CONCAT(
        'INSERT INTO `', v_LogDB, '`.T_Alteracoes_LOG ',
        '( DATA_HORA, NOME_TABELA, NOME_COLUNA, TIPO_TAM_EXISTENTE, TIPO_TAM_SUGERIDO, MENSAGEM ) ',
        '( NOW(), ?, ?, ?, ?, ? )' );

    PREPARE stmt FROM @sql;
    EXECUTE stmt USING v_NomeTabela, v_NomeColuna, v_TipoTamExistente, v_TipoTamSugerido, v_Mensagem;
    DEALLOCATE PREPARE stmt;
END $$
DELIMITER ;