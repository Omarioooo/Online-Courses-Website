-- sp_GetTotalUsers
CREATE PROCEDURE sp_GetTotalUsers
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calc the total number of users
    SELECT COUNT(UserID) AS TotalUsers
    FROM SystemUser;

    -- Success / No Data message
    IF @@ROWCOUNT = 0 OR (SELECT COUNT(UserID) FROM SystemUser) = 0
        SET @ResultMessage = 'No users found in the system.';
    ELSE
        SET @ResultMessage = 'Success';
END;
-------------------------------------------------------------------------------------
-- sp_GetTotalUsersByRole
CREATE PROCEDURE sp_GetTotalUsersByRole
    @RoleID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calc the total number of users by role
    SELECT COUNT(UserID) AS TotalUsers
    FROM SystemUser
    WHERE RoleID = @RoleID;

    -- Success / No Data message
    IF @@ROWCOUNT = 0 OR (SELECT COUNT(UserID) FROM SystemUser WHERE RoleID = @RoleID) = 0
        SET @ResultMessage = 'No users found for the given role.';
    ELSE
        SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------------
-- sp_GetTotalCourses
CREATE PROCEDURE sp_GetTotalCourses
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calc the total number of courses
    SELECT COUNT(CourseID) AS TotalCourses
    FROM Course;

    -- Success / No Data message
    IF (SELECT COUNT(CourseID) FROM Course) = 0
        SET @ResultMessage = 'No courses found.';
    ELSE
        SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------------
-- sp_GetTopCourses
CREATE PROCEDURE sp_GetTopCourses
    @NumberToDisplay INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    WITH CoursePopularity AS (
        SELECT
            crs.CourseID,
            crs.Title AS CourseTitle,
            crs.[Description],
            crs.Price,
            ctg.CategoryType,
            usr.FirstName + ' ' + usr.LastName AS InstructorName,
            COUNT(enr.EnrollmentID) AS TotalEnrollments,
            ROW_NUMBER() OVER (ORDER BY COUNT(enr.EnrollmentID) DESC) AS RowNum
        FROM
            Course crs
        JOIN
            Category ctg ON crs.CategoryID = ctg.CategoryID
        JOIN
            CourseCreation cr ON crs.CreationID = cr.CreationID
        JOIN
            SystemUser usr ON usr.UserID = cr.InstructorID
        LEFT JOIN
            Enrollment enr ON enr.CourseID = crs.CourseID
        GROUP BY
            crs.CourseID,
            crs.Title,
            crs.[Description],
            crs.Price,
            ctg.CategoryType,
            usr.FirstName,
            usr.LastName
    )
    SELECT
        CourseID,
        CourseTitle,
        [Description],
        Price,
        CategoryType,
        InstructorName,
        TotalEnrollments
    FROM
        CoursePopularity
    WHERE
        RowNum <= @NumberToDisplay;

    -- Success / No Data message
    IF @@ROWCOUNT = 0
        SET @ResultMessage = 'No courses found.';
    ELSE
        SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------------
-- sp_GetTopCoursesByCategory
CREATE PROCEDURE sp_GetTopCoursesByCategory
    @CategoryID INT,
    @NumberToDisplay INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate input
    IF @NumberToDisplay <= 0
    BEGIN
        SET @ResultMessage = 'Invalid number to display.';
        RETURN;
    END;

    WITH CoursePopularity AS (
        SELECT
            crs.CourseID,
            crs.Title AS CourseTitle,
            crs.[Description],
            crs.Price,
            ctg.CategoryType,
            usr.FirstName + ' ' + usr.LastName AS InstructorName,
            COUNT(enr.EnrollmentID) AS TotalEnrollments,
            ROW_NUMBER() OVER (ORDER BY COUNT(enr.EnrollmentID) DESC) AS RowNum
        FROM
            Course crs
        JOIN
            Category ctg ON crs.CategoryID = ctg.CategoryID
        JOIN
            CourseCreation cr ON crs.CreationID = cr.CreationID
        JOIN
            SystemUser usr ON usr.UserID = cr.InstructorID
        LEFT JOIN
            Enrollment enr ON enr.CourseID = crs.CourseID
        WHERE
            ctg.CategoryID = @CategoryID
        GROUP BY
            crs.CourseID,
            crs.Title,
            crs.[Description],
            crs.Price,
            ctg.CategoryType,
            usr.FirstName,
            usr.LastName
    )
    SELECT
        CourseID,
        CourseTitle,
        [Description],
        Price,
        CategoryType,
        InstructorName,
        TotalEnrollments
    FROM
        CoursePopularity
    WHERE
        RowNum <= @NumberToDisplay;

    -- Success / No Data message
    IF @@ROWCOUNT = 0
        SET @ResultMessage = 'No courses found for this category.';
    ELSE
        SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------
-- sp_GetRevenueReportByDay
CREATE PROCEDURE sp_GetRevenueReportByDay
    @givenDate DATE,
    @dayForReport VARCHAR(10) OUTPUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get the day of the report
    SET @dayForReport = FORMAT(@givenDate, 'dddd');

    -- Get revenue + enrollments
    SELECT
        ISNULL(SUM(c.Price), 0) AS TotalRevenue,
        ISNULL(COUNT(e.EnrollmentID), 0) AS TotalEnrollments
    FROM Enrollment e
    JOIN Course c ON e.CourseID = c.CourseID
    WHERE e.EnrollmentDate = @givenDate;

    -- Success / No Data message
    IF @@ROWCOUNT = 0 OR NOT EXISTS (
        SELECT 1 FROM Enrollment e WHERE e.EnrollmentDate = @givenDate
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

    -- Force Saturday as the start of the week
    SET DATEFIRST 7;

    -- Calculate week range (Sat - Fri)
    SET @week_start = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @givenDate), @givenDate);
    SET @week_end   = DATEADD(DAY, 7 - DATEPART(WEEKDAY, @givenDate), @givenDate);

    -- Get revenue + enrollments
    SELECT
        ISNULL(SUM(c.Price), 0) AS TotalRevenue,
        ISNULL(COUNT(e.EnrollmentID), 0) AS TotalEnrollments
    FROM Enrollment e
    JOIN Course c ON e.CourseID = c.CourseID
    WHERE e.EnrollmentDate BETWEEN @week_start AND @week_end;

    -- Success / No Data message
    IF @@ROWCOUNT = 0 OR NOT EXISTS (
        SELECT 1 FROM Enrollment e
        WHERE e.EnrollmentDate BETWEEN @week_start AND @week_end
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

    -- Get first and last day of the month
    DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@givenDate), MONTH(@givenDate), 1);
    DECLARE @MonthEnd   DATE = EOMONTH(@givenDate);

    -- Format month/year
    SET @MonthForReport = FORMAT(@givenDate, 'MMMM - yy');

    -- Get revenue + enrollments for that month
    SELECT
        ISNULL(SUM(c.Price), 0) AS TotalRevenue,
        ISNULL(COUNT(e.EnrollmentID), 0) AS TotalEnrollments
    FROM Enrollment e
    JOIN Course c ON e.CourseID = c.CourseID
    WHERE e.EnrollmentDate BETWEEN @MonthStart AND @MonthEnd;

    -- Success / No Data message
    IF @@ROWCOUNT = 0 OR NOT EXISTS (
        SELECT 1
        FROM Enrollment e
        WHERE e.EnrollmentDate BETWEEN @MonthStart AND @MonthEnd
    )
        SET @ResultMessage = 'No revenue data found for this month.';
    ELSE
        SET @ResultMessage = 'Success';
END;
-------------------------------------------------------------------------------------------
-- sp_GetRevenueReportByYear
CREATE PROCEDURE sp_GetRevenueReportByYear
    @givenDate DATE,
    @yearForReport CHAR(4) OUTPUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Extract year for the report
    SET @yearForReport = FORMAT(@givenDate, 'yyyy');

    -- Get revenue + enrollments for that year
    SELECT
        ISNULL(SUM(c.Price), 0) AS TotalRevenue,
        ISNULL(COUNT(e.EnrollmentID), 0) AS TotalEnrollments
    FROM Enrollment e
    JOIN Course c ON e.CourseID = c.CourseID
    WHERE YEAR(e.EnrollmentDate) = YEAR(@givenDate);

    -- Success / No Data message
    IF @@ROWCOUNT = 0 OR NOT EXISTS (
        SELECT 1
        FROM Enrollment e
        WHERE YEAR(e.EnrollmentDate) = YEAR(@givenDate)
    )
        SET @ResultMessage = 'No revenue data found for this year.';
    ELSE
        SET @ResultMessage = 'Success';
END;