-- sp_GetTotalUsers
CREATE PROCEDURE sp_GetTotalUsers
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calc the total number of users
	SELECT COUNT(UserID) TotalUsers
	FROM SystemUser

    SET @ResultMessage = 'Done';
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

    SET @ResultMessage = 'Done';
END;
---------------------------------------------------------------------------------------
-- sp_GetTotalCourses
CREATE PROCEDURE sp_GetTotalCourses
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calc the total number of courses
	SELECT COUNT(CourseID) TotalCourses
	FROM Course

    SET @ResultMessage = 'Done';
END;
---------------------------------------------------------------------------------------
-- sp_GetTopCourses
CREATE PROCEDURE sp_GetTopCourses
    @NumberToDisplay INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH CoursePopularity AS (
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
	   RowNum <= @NumberToDisplay

    -- Set Message
    SET @ResultMessage = 'Done';
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

    ;WITH CoursePopularity AS (
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

    -- Set Message
    SET @ResultMessage = 'Done';
END;
---------------------------------------------------------------------------------
-- sp_GetRevenueReportByDay
CREATE PROCEDURE sp_GetRevenueReportByDay
    @givenDate DATE,
	@dayForReport VARCHAR(10),
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get the day of the report
	SET @dayForReport = FORMAT(@givenDate, 'dddd')

    -- Get revenue + enrollments
    SELECT
		ISNULL(SUM(c.Price), 0) AS TotalRevenue,
		ISNULL(COUNT(e.EnrollmentID), 0) AS TotalEnrollments
    FROM Enrollment e
    JOIN Course c ON e.CourseID = c.CourseID
    WHERE e.EnrollmentDate = @givenDate;

    SET @ResultMessage = 'Done';
END;
---------------------------------------------------------------------------------
-- sp_GetRevenueReportByWeek
CREATE PROCEDURE sp_GetRevenueReportByWeek
    @givenDate DATE,
    @week_start DATE OUT,
    @week_end DATE OUT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Force Saturday as the start of the week
    SET DATEFIRST 7;

    -- Calculate week range
    SET @week_start = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @givenDate), @givenDate);
    SET @week_end   = DATEADD(DAY, 7 - DATEPART(WEEKDAY, @givenDate), @givenDate);

    -- Get revenue + enrollments
    SELECT
		ISNULL(SUM(c.Price), 0) AS TotalRevenue,
		ISNULL(COUNT(e.EnrollmentID), 0) AS TotalEnrollments
	FROM Enrollment e
    JOIN Course c ON e.CourseID = c.CourseID
    WHERE e.EnrollmentDate BETWEEN @week_start AND @week_end;

    SET @ResultMessage = 'Done';
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

    SET @ResultMessage = 'Done';
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

    -- Extract year
    SET @yearForReport = FORMAT(@givenDate, 'yyyy');

    -- Get revenue + enrollments
    SELECT
        ISNULL(SUM(c.Price), 0) AS TotalRevenue,
        ISNULL(COUNT(e.EnrollmentID), 0) AS TotalEnrollments
    FROM Enrollment e
    JOIN Course c ON e.CourseID = c.CourseID
    WHERE YEAR(e.EnrollmentDate) = YEAR(@givenDate);

    SET @ResultMessage = 'Done';
END;

