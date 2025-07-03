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
        ( 1, 'T_Alteracoes_LOG', 'NUM_INDEX' ),
        ( 2, 'T_Consultas',      'NUM_INDEX' ),
        ( 3, 'T_Moedas',         'NUM_INDEX' ),
        ( 4, 'T_CotacaoMoedas',  'NUM_INDEX' ),
        ( 5, 'T_MoedasBrasil',   'NUM_INDEX' );

    CREATE TEMPORARY TABLE LST_CAMPOS (
        ID_TabelaCampo INT PRIMARY KEY,
        Nome_DefCampo  TEXT,           
        Nome_FN_Key    TEXT            
    );

    INSERT INTO LST_CAMPOS VALUES
		( 1,
		  '`NUM_INDEX`       INT AUTO_INCREMENT NOT NULL,
		  `DATA_HORA`        DATETIME NOT NULL,
      `NOME_TABELA`      VARCHAR(255),
      `NOME_COLUNA`      VARCHAR(255),
      `TP_TAM_EXISTENTE` VARCHAR(100),
      `TP_TAM_SUGERIDO`  VARCHAR(100),
      `DESCR_ERRO`       VARCHAR(255)',
      '' ),

    ( 2,
      '`NUM_INDEX`      INT AUTO_INCREMENT NOT NULL,
      `NomeConsulta`    VARCHAR(50) NOT NULL,
      `Complemento_URL` VARCHAR(100) NOT NULL, 
      `Colunas`         VARCHAR(100) NOT NULL',
      '' ),

    ( 3,
      '`NUM_INDEX` INT AUTO_INCREMENT NOT NULL, 
      `Sigla`      VARCHAR(3) NOT NULL, 
      `NomeMoeda`  VARCHAR(40) NOT NULL, 
      `TipoMoeda`  VARCHAR(1) NOT NULL',
      '' ),

    ( 4,
      '`NUM_INDEX`  INT AUTO_INCREMENT NOT NULL, 
      `DataCotacao` DATE NOT NULL, 
      `VlrCompra`   DECIMAL(8, 2), 
      `VlrVenda`    DECIMAL(8, 2), 
      `FK_ID_Moeda` INT',
      'FOREIGN KEY (`FK_ID_Moeda`) REFERENCES T_Moedas(`NUM_INDEX`)' );

		( 5,
		  '`NUM_INDEX`  INT AUTO_INCREMENT NOT NULL, 
          `NomeMoeda` 	VARCHAR(25), 
          `Simbolo`     VARCHAR(4), 
          `DataInicio`  DATE NOT NULL, 
          `DataFim`     DATE',
          '' );

      -- 'FOREIGN KEY (`FK_ID_Moeda`) REFERENCES T_Moedas(`NUM_INDEX`)|FOREIGN KEY (`FK_ID_MoedaBrasil`) REFERENCES T_MoedasBrasil(`NUM_INDEX`)' 
END $$
DELIMITER ;