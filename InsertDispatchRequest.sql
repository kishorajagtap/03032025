/****** Object:  StoredProcedure [dbo].[InsertDispatchRequest]    Script Date: 09/03/2025 19:14:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[InsertDispatchRequest]
    @CustomerCode NVARCHAR(50),
    @PricePerKg DECIMAL(18,2),
    @BookingPrice DECIMAL(18,2),
    @BookedQty INT,
    @BookingAmtPaid DECIMAL(18,2),
    @BalanceAmtToPay DECIMAL(18,2),
    @ExpectedDelivery DATE,
    @BalanceQuantity INT,
    @DispatchStatus NVARCHAR(20),
    @RequestForQuantityMT DECIMAL(18,2),
    @AmountRequiredToDispatch DECIMAL(18,2),
    @BookingAmountReceived DECIMAL(18,2),
    @BalanceAmount DECIMAL(18,2),
    @FromDate DATE,
    @ToDate DATE,
    @DispatchAddress NVARCHAR(255),
    @OrderNumber INT,
    @ProductId INT,
	@PriceCardType NVARCHAR(50),

    -- Secondary fields
    @SecondaryPricePerKg DECIMAL(18,2) = NULL,
    @SecondaryBookingPrice DECIMAL(18,2) = NULL,
    @SecondaryBookedQty INT = NULL,
    @SecondaryBookingAmtPaid DECIMAL(18,2) = NULL,
    @SecondaryBalanceAmtToPay DECIMAL(18,2) = NULL,
    @SecondaryRequestForQtyMT DECIMAL(18,2) = NULL,
    @SecondaryBalanceQuantity INT = NULL,
    @SecondaryDispatchStatus NVARCHAR(20) = NULL,
	@SecondaryAmountRequiredToDispatch DECIMAL(18,2) = NULL,
	@SecondaryBookingAmountReceived DECIMAL(18,2) = NULL,
    @SecondaryBalanceAmount DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LatestTotalAvailableBalance DECIMAL(18,2);
	DECLARE @DispatchBalance DECIMAL(18,2);

    -- Get the latest TotalAvailableBalance for the customer
    SELECT TOP 1 @LatestTotalAvailableBalance = TotalAvailableBalance
    FROM TB_CustomerTransaction
    WHERE CustomerCode = @CustomerCode
    ORDER BY LastUpdated DESC;

    -- If no record exists, assume 0 balance
    IF @LatestTotalAvailableBalance IS NULL
        SET @LatestTotalAvailableBalance = 0;

    IF @PriceCardType = 'Single'
        SET @DispatchBalance = @BalanceAmount;
    ELSE IF @PriceCardType = 'Combo'
        SET @DispatchBalance = @BalanceAmount + ISNULL(@SecondaryBalanceAmount, 0);
    ELSE
        SET @DispatchBalance = @BalanceAmount; 

    -- Insert into DispatchRequests table
    INSERT INTO DispatchRequests (
        CustomerCode, PricePerKg, BookingPrice, BookedQty, BookingAmtPaid, BalanceAmtToPay,
        ExpectedDelivery, BalanceQuantity, DispatchStatus, RequestForQuantityMT, AmountRequiredToDispatch,
        BookingAmountReceived, BalanceAmount, FromDate, ToDate, DispatchAddress, CreatedOn, OrderNumber, ProductId,
        SecondaryPricePerKg, SecondaryBookingPrice, SecondaryBookedQty, SecondaryBookingAmtPaid,
        SecondaryBalanceAmtToPay, SecondaryRequestForQtyMT, SecondaryBalanceQuantity, SecondaryDispatchStatus,SecondaryBookingAmountReceived,
        SecondaryAmountRequiredToDispatch, SecondaryBalanceAmount
    )
    VALUES (
        @CustomerCode, @PricePerKg, @BookingPrice, @BookedQty, @BookingAmtPaid, @BalanceAmtToPay,
        @ExpectedDelivery, @BalanceQuantity, @DispatchStatus, @RequestForQuantityMT, @AmountRequiredToDispatch,
        @BookingAmountReceived, @BalanceAmount, @FromDate, @ToDate, @DispatchAddress, GETDATE(), @OrderNumber, @ProductId,
        @SecondaryPricePerKg, @SecondaryBookingPrice, @SecondaryBookedQty, @SecondaryBookingAmtPaid,
        @SecondaryBalanceAmtToPay, @SecondaryRequestForQtyMT, @SecondaryBalanceQuantity, @SecondaryDispatchStatus,@SecondaryBookingAmountReceived,
        @SecondaryAmountRequiredToDispatch,@SecondaryBalanceAmount
    );

    -- Insert transaction into TB_CustomerTransaction
    INSERT INTO TB_CustomerTransaction (
        CustomerCode, AvailableBalance, DepositedBalance, DeductedBalance, DispatchBalance, 
        TotalAvailableBalance, TransactionType, LastUpdated
    )
    VALUES (
        @CustomerCode, @LatestTotalAvailableBalance, 0, 0, @DispatchBalance, 
        @LatestTotalAvailableBalance - @BalanceAmount, 'Dispatch', GETDATE()
    );

    -- Return the inserted DispatchRequest Id
    SELECT SCOPE_IDENTITY() AS InsertedId;
END;

