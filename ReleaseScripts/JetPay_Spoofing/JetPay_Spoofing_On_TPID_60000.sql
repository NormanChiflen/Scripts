SET NOCOUNT ON
DECLARE @CRLF        CHAR(2)
DECLARE @TPID        INTEGER
DECLARE @componentID INTEGER
DECLARE @itemName    VARCHAR(50)
DECLARE @machineName VARCHAR(50)
DECLARE @itemValue   VARCHAR(1000)
DECLARE @newValue    CHAR(1)
DECLARE @TPIDList    VARCHAR(255)
DECLARE @curse       CURSOR
DECLARE @cmd         VARCHAR(2047)

SELECT @CRLF        = CHAR(13) + CHAR(10)
     , @TPIDList    = '60000'
     , @componentID = 28
     , @itemName    = 'JetpaySpoofOn'
     , @newValue    = '1'

CREATE TABLE ##curseList(
    TPID        INTEGER       NOT NULL,
    ComponentID INTEGER       NOT NULL,
    ItemName    VARCHAR(50)   NOT NULL,
    MachineName VARCHAR(50)   NOT NULL,
    ItemValue   VARCHAR(1000) NOT NULL
)
SELECT @cmd = 'INSERT INTO ##curseList'                                              + @CRLF
            + '    SELECT ProductId'                                                 + @CRLF
            + '         , ComponentID'                                               + @CRLF
            + '         , ItemName'                                                  + @CRLF
            + '         , MachineName'                                               + @CRLF
            + '         , ItemValue'                                                 + @CRLF
            + '            FROM dtTravelServerConfiguration'                         + @CRLF
            + '            WHERE ComponentId = ' + CONVERT(VARCHAR(4), @componentID) + @CRLF
            + '              AND ItemName = ''' + @itemName + ''''                   + @CRLF
            + '              AND ProductID IN (' + @TPIDList + ')'                   + @CRLF
EXEC(@cmd)

SET @curse = CURSOR READ_ONLY STATIC FORWARD_ONLY FOR SELECT * FROM ##curseList
OPEN @curse
FETCH NEXT FROM @curse INTO @TPID, @componentID, @itemName, @machineName, @itemValue

WHILE @@FETCH_STATUS = 0
    BEGIN
    PRINT 'For TPID=' + CONVERT(CHAR(6), @TPID) + 'ComponentID=' + CONVERT(CHAR(3), @componentID)
        + 'ItemName=''' + @itemName + ''' MachineName=''' + @machineName 
        + ''' changing ItemValue=''' + @itemValue + ''' to ''' + @newValue + ''''
    UPDATE dtTravelServerConfiguration
        SET ItemValue = @newValue
        WHERE ProductID   = @TPID
          AND ComponentID = @componentID
          AND ItemName    = @itemName
          AND MachineName = @machineName
    FETCH NEXT FROM @curse INTO @TPID, @componentID, @itemName, @machineName, @itemValue
    END

CLOSE @curse
DEALLOCATE @curse
DROP TABLE ##curseList
