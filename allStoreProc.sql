-- ################################################################################################### 
-- * ######################## AcquirerOriginalDecline_IssuerReversalSuccess ########################## 
-- ################################################################################################### 
DROP PROCEDURE IF EXISTS AcquirerOriginalDecline_IssuerReversalSuccess;
DELIMITER $$
CREATE PROCEDURE AcquirerOriginalDecline_IssuerReversalSuccess()
COMMENT '
# Proc Name :- AcquirerOriginalDecline_IssuerReversalSuccess
# Created By :- Dishant Raut [22Jun2022]
# Updated By :- Tejaswini Somware [22Jun2022]
# Params :- No Params Required
# Desc :- Get Acquirer Side Original Decline & Issuer Side Reversal Success
# Exec :- CALL AcquirerOriginalDecline_IssuerReversalSuccess();
# Drop :- DROP PROCEDURE IF EXISTS AcquirerOriginalDecline_IssuerReversalSuccess;
'
BEGIN
SELECT
    AcqOrgDec.RRN,
    AcqOrgDec.LDate,
    AOD_MT,
    AOD_PC,
    AOD_RC,
    IRS_MT,
    IRS_PC,
    IRS_RC,
    AcqOrgDec.TrxAmt,
    AOD_LTime,
    IRS_LTime
    
FROM
    (
        SELECT
            RetrievalReferenceNumber AS RRN,
            MessageType AS AOD_MT,
            ProcessingCode AS AOD_PC,
            ResponseCode AS AOD_RC,
            TransactionAmount AS TrxAmt,
            LocalTransactionDate AS LDate,
            LocalTransactionTime AS AOD_LTime
        FROM
            iseretailer
        WHERE
            MessageType = "0210"
            AND ResponseCode != "00"
    ) AS AcqOrgDec
    INNER JOIN (
        SELECT
            RetrievalReferenceNumber AS RRN,
            MessageType AS IRS_MT,
            ProcessingCode AS IRS_PC,
            ResponseCode AS IRS_RC,
            TransactionAmount AS TrxAmt,
            LocalTransactionDate AS LDate,
            LocalTransactionTime AS IRS_LTime
        FROM
            issuerextractcopy
        WHERE
            MessageType = "0420"
            AND ResponseCode = "00"
    ) AS IssRevSuc ON AcqOrgDec.RRN = IssRevSuc.RRN
    AND AcqOrgDec.TrxAmt = IssRevSuc.TrxAmt
    AND AcqOrgDec.LDate = IssRevSuc.LDate
ORDER BY
AcqOrgDec.LDate
DESC;
END $$
DELIMITER ;
CALL AcquirerOriginalDecline_IssuerReversalSuccess;
#DROP PROCEDURE IF EXISTS AcquirerOriginalDecline_IssuerReversalSuccess;


-- ################################################################################################### 
-- * ######################## ProdStats ########################## 
-- ################################################################################################### 
DROP PROCEDURE IF EXISTS ProdStats;
DELIMITER $$
CREATE PROCEDURE ProdStats()
COMMENT '
# Proc Name :- ProdStats
# Created By :- Dishant Raut [13Jun2022]
# Updated By :- Tejaswini Somware [22Jun2022]
# Params :- No Params Required
# Desc :- Get Stats Of Prod Data Every Day
            1. Retailer Load Count
            2. Acquirer (IseRetailer) Node Count
            3. Issuer (IssuerExtractCopy) Node Count
            4. Invalid Trnx (AcquirerNotValid) Count
            5. Issuer Side More Acquirer Side Missing -> IssMoreAcqMiss
            6. Acquirer Side More Issuer Side Missing -> AcqMoreIssMiss
# Exec :- CALL ProdStats();
# Drop :- DROP PROCEDURE IF EXISTS ProdStats;
'
BEGIN
    DECLARE acqNode, issNode, retLoad, invalidTrx INT DEFAULT 0;
    SELECT COUNT(RetailerId) INTO retLoad FROM retailerid;
    SELECT COUNT(RetrievalReferenceNumber) INTO acqNode FROM iseretailer;
    SELECT COUNT(RetrievalReferenceNumber) INTO issNode FROM issuerextractcopy;
    SELECT COUNT(RetrievalReferenceNumber) INTO invalidTrx FROM acquirernotvalid WHERE ResponseCode = "00";    
    SELECT retLoad, acqNode, issNode, invalidTrx;
    -- * Issuer Side More Acquirer Side Missing
    (
        SELECT
            LocalTransactionDate AS TrnxDate,
            #RetrievalReferenceNumber AS RRN,
            COUNT(RetrievalReferenceNumber) AS AcqMissCnt
        FROM
            issuerextractcopy
        WHERE
            ResponseCode = "00"
            AND RetrievalReferenceNumber NOT IN (
                SELECT
                    RetrievalReferenceNumber
                FROM
                    iseretailer
                WHERE
                    ResponseCode = "00"
            )
        GROUP BY
            LocalTransactionDate
        ORDER BY
            LocalTransactionDate
    )
    UNION
    (
        SELECT
            "Total Count = ",
            COUNT(RetrievalReferenceNumber)
        FROM
            issuerextractcopy
        WHERE
            ResponseCode = "00"
            AND RetrievalReferenceNumber NOT IN (
                SELECT
                    RetrievalReferenceNumber
                FROM
                    iseretailer
                WHERE
                    ResponseCode = "00"
            )
    );
    -- * Acquirer Side More Issuer Side Missing
    (
        SELECT
            LocalTransactionDate AS TrnxDate,
            #RetrievalReferenceNumber AS RRN,
            COUNT(RetrievalReferenceNumber) AS IssMissCnt
        FROM
            iseretailer
        WHERE
            ResponseCode = "00"
            AND RetrievalReferenceNumber NOT IN (
                SELECT
                    RetrievalReferenceNumber
                FROM
                    issuerextractcopy
                WHERE
                    ResponseCode = "00"
            )
        GROUP BY
            LocalTransactionDate
        ORDER BY
            LocalTransactionDate
    )
    UNION
    (
        SELECT
            "Total Count = ",
            COUNT(RetrievalReferenceNumber)
        FROM
            iseretailer
        WHERE
            ResponseCode = "00"
            AND RetrievalReferenceNumber NOT IN (
                SELECT
                    RetrievalReferenceNumber
                FROM
                    issuerextractcopy
                WHERE
                    ResponseCode = "00"
            )
    );

END$$
DELIMITER ;
CALL ProdStats();
#DROP PROCEDURE IF EXISTS ProdStats;


-- ################################################################################################### 
-- * ######################## PhaseOne_AcqMoreIssMiss ########################## 
-- ################################################################################################### 
DROP PROCEDURE IF EXISTS PhaseOne_AcqMoreIssMiss;
DELIMITER $$
CREATE PROCEDURE PhaseOne_AcqMoreIssMiss()
COMMENT '
# Proc Name :- PhaseOne_AcqMoreIssMiss
# Created By :- Dishant Raut [13Jun2022]
# Updated By :- Tejaswini Somware [22Jun2022]
# Params :- No Params Required
# Desc :- Get All Issuer Side Missing Trnx
            1. Issuer Side Less Trnx
            2. Acquirer Side More Trnx
# Exec :- CALL PhaseOne_AcqMoreIssMiss();
# Drop :- DROP PROCEDURE IF EXISTS PhaseOne_AcqMoreIssMiss;
'
BEGIN
-- * Issuer Side More Acquirer Side Missing
SELECT
    MessageType AS MT,
    ProcessingCode AS PC,
    ResponseCode AS RC,
    ForwardingInstitutionIdentification AS Brand,
    Acquiring InstitutionIdentification AS Switch,
    RetrievalReferenceNumber AS RRN,
    Track2Data AS CardNo,
    CardAcceptorIdentification AS RetId,
    LocalTransactionDate AS TrxDate,
    LocalTransactionTime AS TrxTime,
    SystemsTraceAuditNumber AS TraceId,
    ChannelType AS Channel,
    TransactionAmount AS Amt
FROM
    iseretailer
WHERE
    ResponseCode = "00"
    AND RetrievalReferenceNumber NOT IN (
        SELECT
            RetrievalReferenceNumber
        FROM
            issuerextractcopy
        WHERE
            ResponseCode = "00"
    );
END$$
DELIMITER ;
CALL PhaseOne_AcqMoreIssMiss;
#DROP PROCEDURE IF EXISTS PhaseOne_AcqMoreIssMiss;


-- ################################################################################################### 
-- * ######################## PhaseOne_IssMoreAcqMiss ########################## 
-- ################################################################################################### 
DROP PROCEDURE IF EXISTS PhaseOne_IssMoreAcqMiss;
DELIMITER $$
CREATE PROCEDURE PhaseOne_IssMoreAcqMiss()
COMMENT '
# Proc Name :- PhaseOne_IssMoreAcqMiss
# Created By :- Dishant Raut [13Jun2022]
# Updated By :- Tejaswini Somware [22Jun2022]
# Params :- No Params Required
# Desc :- Get All Acquirer Side Missing Trnx
            1. Issuer Side More Trnx
            2. Acquirer Side Less Trnx
# Exec :- CALL PhaseOne_IssMoreAcqMiss();
# Drop :- DROP PROCEDURE IF EXISTS PhaseOne_IssMoreAcqMiss;
'
BEGIN
-- Issuer Side More Acquirer Side Missing
SELECT
    MessageType AS MT,
    ProcessingCode AS PC,
    ResponseCode AS RC,
    ForwardingInstitutionIdentification AS Brand,
    Acquiring InstitutionIdentification AS Switch,
    RetrievalReferenceNumber AS RRN,
    Track2Data AS CardNo,
    CardAcceptorIdentification AS RetId,
    LocalTransactionDate AS TrxDate,
    LocalTransactionTime AS TrxTime,
    SystemsTraceAuditNumber AS TraceId,
    ChannelType AS Channel,
    TransactionAmount AS Amt
FROM
    issuerextractcopy
WHERE
    ResponseCode = "00"
    AND RetrievalReferenceNumber NOT IN (
        SELECT
            RetrievalReferenceNumber
        FROM
            iseretailer
        WHERE
            ResponseCode = "00"
    );
END$$
DELIMITER ;
CALL PhaseOne_IssMoreAcqMiss;
#DROP PROCEDURE IF EXISTS PhaseOne_IssMoreAcqMiss;


-- ################################################################################################### 
-- * ######################## ProdEachDayDataBKToDev ########################## 
-- ################################################################################################### 
DROP PROCEDURE IF EXISTS ProdEachDayDataBKToDev;
DELIMITER $$
CREATE PROCEDURE ProdEachDayDataBKToDev()
COMMENT '
# Proc Name :- ProdEachDayDataBKToDev
# Created By :- Dishant Raut [13Jun2022]
# Updated By :- Tejaswini Somware [22Jun2022]
# Params :- No Params Required
# Desc :- Take Backup Of Prod Data To Dev After Completion Of Phase One
# Exec :- CALL ProdEachDayDataBKToDev();
# Drop :- DROP PROCEDURE IF EXISTS ProdEachDayDataBKToDev;
'
BEGIN
truncate table OMNICOMP_BECH_Dishant.retailerid;
truncate table OMNICOMP_BECH_Dishant.iseretailer;
truncate table OMNICOMP_BECH_Dishant.issuerextractcopy;
INSERT INTO OMNICOMP_BECH_Dishant.retailerid SELECT * FROM OMNICOMP_BECH_PROD.retailerid;
INSERT INTO OMNICOMP_BECH_Dishant.iseretailer SELECT * FROM OMNICOMP_BECH_PROD.iseretailer;
INSERT INTO OMNICOMP_BECH_Dishant.issuerextractcopy SELECT * FROM OMNICOMP_BECH_PROD.issuerextractcopy;
END$$
DELIMITER ;
CALL ProdEachDayDataBKToDev;
#DROP PROCEDURE IF EXISTS ProdEachDayDataBKToDev;


-- ################################################################################################### 
-- * ######################## ProdEachDayDataBKToBlueProd ########################## 
-- ################################################################################################### 
DROP PROCEDURE IF EXISTS ProdEachDayDataBKToBlueProd;
DELIMITER $$
CREATE PROCEDURE ProdEachDayDataBKToBlueProd()
COMMENT '
# Proc Name :- ProdEachDayDataBKToBlueProd
# Created By :- Dishant Raut [13Jun2022]
# Updated By :- Ankita Harad [05Sep2022]
# Params :- No Params Required
# Desc :- Take Backup Of Prod Data To BlueProd After Completion Of Phase One
# Exec :- CALL ProdEachDayDataBKToBlueProd();
# Drop :- DROP PROCEDURE IF EXISTS ProdEachDayDataBKToBlueProd;
'
BEGIN
truncate table OMNICOMP_BECH_BLUEPROD.retailerid;
truncate table OMNICOMP_BECH_BLUEPROD.iseretailer;
truncate table OMNICOMP_BECH_BLUEPROD.issuerextractcopy;
INSERT INTO OMNICOMP_BECH_BLUEPROD.retailerid SELECT * FROM OMNICOMP_BECH_PROD.retailerid;
INSERT INTO OMNICOMP_BECH_BLUEPROD.iseretailer SELECT * FROM OMNICOMP_BECH_PROD.iseretailer;
INSERT INTO OMNICOMP_BECH_BLUEPROD.issuerextractcopy SELECT * FROM OMNICOMP_BECH_PROD.issuerextractcopy;
END$$
DELIMITER ;
CALL ProdEachDayDataBKToBlueProd;
#DROP PROCEDURE IF EXISTS ProdEachDayDataBKToBlueProd;


-- ################################################################################################### 
-- * ######################## AcquirerSide_OriginalDeclineReversalSuccess ########################## 
-- ################################################################################################### 
DROP PROCEDURE IF EXISTS `AcquirerSide_OriginalDeclineReversalSuccess`;
DELIMITER $$ 
CREATE PROCEDURE `AcquirerSide_OriginalDeclineReversalSuccess`(
    IN vTableName VARCHAR(40),
    IN lTableName VARCHAR(40),
    IN rTableName VARCHAR(40)
) 
COMMENT '
# Proc Name :- AcquirerSide_OriginalDeclineReversalSuccess
# Created By :- Dishant Raut [13Jun2022]
# Updated By :- Tejaswini Somware [22Jun2022]
# Params :- Stored Procs With 3 IN Parameters
            1. vTableName > Table You Want To View
            2. lTableName > Left Table Name For Inner Join
            3. rTableName > Right Table Name For Inner Join
# Desc :- Get Acquirer Side Original Decline Reversal Success
# Exec :- CALL AcquirerSide_OriginalDeclineReversalSuccess();
# Drop :- DROP PROCEDURE IF EXISTS AcquirerSide_OriginalDeclineReversalSuccess;

'
BEGIN
SET @makeSqlQuery_ = CONCAT (
        'SELECT ',
        vTableName,
        '.* FROM
    (
        SELECT
            LocalTransactionDate AS LDate,
            Track2Data AS CardNo,
            RetrievalReferenceNumber AS RRN,
            SystemsTraceAuditNumber AS TraceId,
            LocalTransactionTime AS LTime,
            MessageType AS MT,
            ProcessingCode AS PC,
            ResponseCode AS RC,
            TransactionAmount AS TrxAmt
        FROM
            iseretailer
        WHERE
            ResponseCode != "00"
            AND MessageType = "0210"
            AND ProcessingCode = "000000"
    ) AS ',lTableName,'
    INNER JOIN (
        SELECT
            LocalTransactionDate AS LDate,
            Track2Data AS CardNo,
            RetrievalReferenceNumber AS RRN,
            SystemsTraceAuditNumber AS TraceId,
            LocalTransactionTime AS LTime,
            MessageType AS MT,
            ProcessingCode AS PC,
            ResponseCode AS RC,
            TransactionAmount AS TrxAmt
        FROM
            iseretailer
        WHERE
            ResponseCode = "00"
            AND MessageType = "0420"
            AND ProcessingCode = "000000"
    ) AS ',rTableName,' ON ',
        lTableName,
        '.RRN = ',
        rTableName,
        '.RRN
    AND ',
        lTableName,
        '.LDate = ',
        rTableName,
        '.LDate
    AND ',
        lTableName,
        '.LTime = ',
        rTableName,
        '.LTime
    AND ',
        lTableName,
        '.CardNo = ',
        rTableName,
        '.CardNo
ORDER BY
    ',
        vTableName,
        '.LDate DESC;
'
    );

PREPARE statement_ FROM @makeSqlQuery_;
EXECUTE statement_;
END $$ 
DELIMITER ;
CALL `AcquirerSide_OriginalDeclineReversalSuccess`('AcqRevSuccess', 'AcqOgDecline', 'AcqRevSuccess');
CALL `AcquirerSide_OriginalDeclineReversalSuccess`('AcqOgDecline', 'AcqOgDecline', 'AcqRevSuccess');
#DROP PROCEDURE IF EXISTS `AcquirerSide_OriginalDeclineReversalSuccess`;

