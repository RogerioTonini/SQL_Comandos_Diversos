USE [Conectcar]
GO
/****** Object:  UserDefinedFunction [dbo].[VerificarValorLimiteAtualRevendedor]    Script Date: 15/03/2022 14:18:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GERADOR_CPF](@Quantidade INT = 1)
AS
    BEGIN 

	 IF (OBJECT_ID('tempdb..#Tabela_Final') IS NOT NULL) 
		DROP TABLE #Tabela_Final

    CREATE TABLE #Tabela_Final (Nr_Documento VARCHAR(18))
 
    DECLARE
        @n INT,
        @n1 INT,
        @n2 INT,
        @n3 INT,
        @n4 INT,
        @n5 INT,
        @n6 INT,
        @n7 INT,
        @n8 INT,
        @n9 INT,
        @n10 INT,
        @n11 INT,
        @n12 INT,
    
        @d1 INT,
        @d2 INT
 
		--CPF    
        WHILE (@Quantidade > 0)
			BEGIN
        
				SET @n = 9
				SET @n1 = CAST(( @n + 1 ) * RAND(CAST(NEWID() AS VARBINARY )) AS INT)
				SET @n2 = CAST(( @n + 1 ) * RAND(CAST(NEWID() AS VARBINARY )) AS INT)
				SET @n3 = CAST(( @n + 1 ) * RAND(CAST(NEWID() AS VARBINARY )) AS INT)
				SET @n4 = CAST(( @n + 1 ) * RAND(CAST(NEWID() AS VARBINARY )) AS INT)
				SET @n5 = CAST(( @n + 1 ) * RAND(CAST(NEWID() AS VARBINARY )) AS INT)
				SET @n6 = CAST(( @n + 1 ) * RAND(CAST(NEWID() AS VARBINARY )) AS INT)
				SET @n7 = CAST(( @n + 1 ) * RAND(CAST(NEWID() AS VARBINARY )) AS INT)
				SET @n8 = CAST(( @n + 1 ) * RAND(CAST(NEWID() AS VARBINARY )) AS INT)
				SET @n9 = CAST(( @n + 1 ) * RAND(CAST(NEWID() AS VARBINARY )) AS INT)
				SET @d1 = @n9 * 2 + @n8 * 3 + @n7 * 4 + @n6 * 5 + @n5 * 6 + @n4 * 7 + @n3 * 8 + @n2 * 9 + @n1 * 10
				SET @d1 = 11 - ( @d1 % 11 )
 
				IF ( @d1 >= 10 )
					SET @d1 = 0
 
				SET @d2 = @d1 * 2 + @n9 * 3 + @n8 * 4 + @n7 * 5 + @n6 * 6 + @n5 * 7 + @n4 * 8 + @n3 * 9 + @n2 * 10 + @n1 * 11
				SET @d2 = 11 - ( @d2 % 11 )
 
				IF ( @d2 >= 10 )
					SET @d2 = 0
 
 
				INSERT INTO #Tabela_Final
				SELECT CAST(@n1 AS VARCHAR) + 
				CAST(@n2 AS VARCHAR) + 
				CAST(@n3 AS VARCHAR) + /*'.' + */
				CAST(@n4 AS VARCHAR) + 
				CAST(@n5 AS VARCHAR) + 
				CAST(@n6 AS VARCHAR) + /*'.' + */
				CAST(@n7 AS VARCHAR) + 
				CAST(@n8 AS VARCHAR) + 
				CAST(@n9 AS VARCHAR) + /*'-' + */
				CAST(@d1 AS VARCHAR) + 
				CAST(@d2 AS VARCHAR)
 
				SET @Quantidade = @Quantidade - 1 
 
			END
	SELECT * FROM #Tabela_Final
END;

exec [dbo].[GERADOR_CPF] 1
