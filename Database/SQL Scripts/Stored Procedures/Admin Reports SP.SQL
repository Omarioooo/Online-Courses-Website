--  This part is about the Revenue Reports based on Date (Day, Week, Month, Year)
-- Used to get some states in admin dashboard
-- The plat form takes 20% of each course

-- sp_GetRevenueReportByDay
ALTER PROCEDURE sp_GetRevenueReportByDay
    @givenDate DATE,
    @dayForReport VARCHAR(10) OUTPUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Day Name
    SET @dayForReport = FORMAT(@givenDate, 'dddd');

    -- Revenue + Enrollments
    SELECT
        ISNULL(SUM(p.PlatformCut), 0) AS TotalRevenue,
        ISNULL(COUNT(DISTINCT p.EnrollmentID), 0) AS TotalEnrollments
    FROM Payment p
    WHERE CAST(p.PaymentDate AS DATE) = @givenDate
      AND p.Status = 'Completed';

    -- Success / No Data
    IF NOT EXISTS (
        SELECT 1 FROM Payment p
        WHERE CAST(p.PaymentDate AS DATE) = @givenDate
          AND p.Status = 'Completed'
    )
        SET @ResultMessage = 'No revenue data found for this date.';
    ELSE
        SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------
-- sp_GetRevenueReportByWeek
CREATE PROCEDURE sp_GetRevenueReportByWeek
    @givenDate DATE,
    @week_start DATE OUTPUT,
    @week_end DATE OUTPUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Saturday as start of the week
    SET DATEFIRST 7;

    -- Week Range (Sat - Fri)
    SET @week_start = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @givenDate), @givenDate);
    SET @week_end   = DATEADD(DAY, 7 - DATEPART(WEEKDAY, @givenDate), @givenDate);

    -- Revenue + Enrollments
    SELECT
        ISNULL(SUM(p.PlatformCut), 0) AS TotalRevenue,
        ISNULL(COUNT(DISTINCT p.EnrollmentID), 0) AS TotalEnrollments
    FROM Payment p
    WHERE CAST(p.PaymentDate AS DATE) BETWEEN @week_start AND @week_end
      AND p.Status = 'Completed';

    -- Success / No Data
    IF NOT EXISTS (
        SELECT 1 FROM Payment p
        WHERE CAST(p.PaymentDate AS DATE) BETWEEN @week_start AND @week_end
          AND p.Status = 'Completed'
    )
        SET @ResultMessage = 'No revenue data found for this week.';
    ELSE
        SET @ResultMessage = 'Success';
END;
-----------------------------------------------------------------------------------------
-- sp_GetRevenueReportByMonth
CREATE PROCEDURE sp_GetRevenueReportByMonth
    @givenDate DATE,
    @MonthForReport VARCHAR(20) OUTPUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Month Range
    DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@givenDate), MONTH(@givenDate), 1);
    DECLARE @MonthEnd   DATE = EOMONTH(@givenDate);

    -- Month Label
    SET @MonthForReport = FORMAT(@givenDate, 'MMMM - yy');

    -- Revenue + Enrollments
    SELECT
        ISNULL(SUM(p.PlatformCut), 0) AS TotalRevenue,
        ISNULL(COUNT(DISTINCT p.EnrollmentID), 0) AS TotalEnrollments
    FROM Payment p
    WHERE CAST(p.PaymentDate AS DATE) BETWEEN @MonthStart AND @MonthEnd
      AND p.Status = 'Completed';

    -- Success / No Data
    IF NOT EXISTS (
        SELECT 1 FROM Payment p
        WHERE CAST(p.PaymentDate AS DATE) BETWEEN @MonthStart AND @MonthEnd
          AND p.Status = 'Completed'
    )
        SET @ResultMessage = 'No revenue data found for this month.';
    ELSE
        SET @ResultMessage = 'Success';
END;
-------------------------------------------------------------------------------------------
CREATE PROCEDURE sp_GetRevenueReportByYear
    @givenDate DATE,
    @yearForReport CHAR(4) OUTPUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Year Label
    SET @yearForReport = FORMAT(@givenDate, 'yyyy');

    -- Revenue + Enrollments
    SELECT
        ISNULL(SUM(p.PlatformCut), 0) AS TotalRevenue,
        ISNULL(COUNT(DISTINCT p.EnrollmentID), 0) AS TotalEnrollments
    FROM Payment p
    WHERE YEAR(p.PaymentDate) = YEAR(@givenDate)
      AND p.Status = 'Completed';

    -- Success / No Data
    IF NOT EXISTS (
        SELECT 1 FROM Payment p
        WHERE YEAR(p.PaymentDate) = YEAR(@givenDate)
          AND p.Status = 'Completed'
    )
        SET @ResultMessage = 'No revenue data found for this year.';
    ELSE
        SET @ResultMessage = 'Success';
END;