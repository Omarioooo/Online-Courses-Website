-- sp_GetAllCourses
CREATE PROCEDURE sp_GetAllCourses
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Course)
    BEGIN
        SET @ResultMessage = 'No courses found in the system.';
        RETURN;
    END;

    WITH CourseStats AS (
        SELECT
            crs.CourseID,
            COUNT(enr.EnrollmentID) AS TotalEnrollments
        FROM Course crs
        LEFT JOIN Enrollment enr
            ON crs.CourseID = enr.CourseID
        GROUP BY crs.CourseID
    )
    SELECT
        crs.CourseID,
        crs.Title,
        crs.[Description],
        crs.Price,
        crs.CourseLevel,
        ctg.CategoryType,
        cc.CreationDate,
        cc.LastUpdateDate,
        usr.FirstName + ' ' + usr.LastName AS InstructorName,
        ISNULL(cs.TotalEnrollments, 0) AS TotalEnrollments
    FROM Course crs
    JOIN Category ctg
        ON crs.CategoryID = ctg.CategoryID
    JOIN CourseCreation cc
        ON crs.CreationID = cc.CreationID
    JOIN SystemUser usr
        ON cc.InstructorID = usr.UserID
    LEFT JOIN CourseStats cs
        ON crs.CourseID = cs.CourseID;

    -- Success message
    SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------------------
-- sp_GetAllCoursesByCategory
CREATE PROCEDURE sp_GetAllCoursesByCategory
    @CategoryID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if category exists
    IF NOT EXISTS (SELECT 1 FROM Category WHERE CategoryID = @CategoryID)
    BEGIN
        SET @ResultMessage = 'Category not found.';
        RETURN;
    END;

    -- Check if category has courses
    IF NOT EXISTS (SELECT 1 FROM Course WHERE CategoryID = @CategoryID)
    BEGIN
        SET @ResultMessage = 'No courses found for the given category.';
        RETURN;
    END;

    WITH CourseStats AS (
        SELECT
            crs.CourseID,
            COUNT(enr.EnrollmentID) AS TotalEnrollments
        FROM Course crs
        LEFT JOIN Enrollment enr
            ON crs.CourseID = enr.CourseID
        GROUP BY crs.CourseID
    )
    SELECT
        crs.CourseID,
        crs.Title,
        crs.[Description],
        crs.Price,
        crs.CourseLevel,
        ctg.CategoryType,
        cc.CreationDate,
        cc.LastUpdateDate,
        usr.FirstName + ' ' + usr.LastName AS InstructorName,
        ISNULL(cs.TotalEnrollments, 0) AS TotalEnrollments
    FROM Course crs
    JOIN Category ctg
        ON crs.CategoryID = ctg.CategoryID
    JOIN CourseCreation cc
        ON crs.CreationID = cc.CreationID
    JOIN SystemUser usr
        ON cc.InstructorID = usr.UserID
    LEFT JOIN CourseStats cs
        ON crs.CourseID = cs.CourseID
    WHERE
        crs.CategoryID = @CategoryID;

    -- Success message
    SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------------------
-- sp_GetAllCoursesByInstructor
CREATE PROCEDURE sp_GetAllCoursesByInstructor
    @InstructorID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- If instructor doesn't exist
    IF NOT EXISTS (SELECT 1 FROM SystemUser WHERE UserID = @InstructorID)
    BEGIN
        SET @ResultMessage = 'Instructor not found.';
        RETURN;
    END;

    -- If instructor exists but has no courses
    IF NOT EXISTS (SELECT 1 FROM CourseCreation WHERE InstructorID = @InstructorID)
    BEGIN
        SET @ResultMessage = 'No courses found for the given instructor.';
        RETURN;
    END;

    WITH CourseStats AS (
        SELECT
            crs.CourseID,
            COUNT(enr.EnrollmentID) AS TotalEnrollments
        FROM Course crs
        LEFT JOIN Enrollment enr
            ON crs.CourseID = enr.CourseID
        GROUP BY crs.CourseID
    )
    SELECT
        crs.CourseID,
        crs.Title,
        crs.[Description],
        crs.Price,
        crs.CourseLevel,
        ctg.CategoryType,
        cc.CreationDate,
        cc.LastUpdateDate,
        usr.FirstName + ' ' + usr.LastName AS InstructorName,
        ISNULL(cs.TotalEnrollments, 0) AS TotalEnrollments
    FROM Course crs
    JOIN Category ctg
        ON crs.CategoryID = ctg.CategoryID
    JOIN CourseCreation cc
        ON crs.CreationID = cc.CreationID
    JOIN SystemUser usr
        ON cc.InstructorID = usr.UserID
    LEFT JOIN CourseStats cs
        ON crs.CourseID = cs.CourseID
    WHERE
        cc.InstructorID = @InstructorID;

    -- Success message
    SET @ResultMessage = 'Success';
END;
-------------------------------------------------------------------------------------------
-- sp_GetAllCoursesByPriceRange
CREATE PROCEDURE sp_GetAllCoursesByPriceRange
    @StartRange DECIMAL(10, 2),
    @EndRange DECIMAL(10, 2),
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate input ranges
    IF @StartRange > @EndRange
    BEGIN
        SET @ResultMessage = 'Invalid price range.';
        RETURN;
    END;

    WITH CourseStats AS (
        SELECT
            crs.CourseID,
            COUNT(enr.EnrollmentID) AS TotalEnrollments
        FROM Course crs
        LEFT JOIN Enrollment enr
            ON crs.CourseID = enr.CourseID
        GROUP BY crs.CourseID
    )
    SELECT
        crs.CourseID,
        crs.Title,
        crs.[Description],
        crs.Price,
        crs.CourseLevel,
        ctg.CategoryType,
        cc.CreationDate,
        cc.LastUpdateDate,
        usr.FirstName + ' ' + usr.LastName AS InstructorName,
        ISNULL(cs.TotalEnrollments, 0) AS TotalEnrollments
    FROM Course crs
    JOIN Category ctg
        ON crs.CategoryID = ctg.CategoryID
    JOIN CourseCreation cc
        ON crs.CreationID = cc.CreationID
    JOIN SystemUser usr
        ON cc.InstructorID = usr.UserID
    LEFT JOIN CourseStats cs
        ON crs.CourseID = cs.CourseID
    WHERE
        crs.Price BETWEEN @StartRange AND @EndRange;

    -- Check if rows returned
    IF @@ROWCOUNT = 0
        SET @ResultMessage = 'No courses found in the given price range.';
    ELSE
        SET @ResultMessage = 'Success';
END;
--------------------------------------------------------------------------------------------------
-- sp_GetCoursesByName
CREATE PROCEDURE sp_GetCoursesByName
    @CourseName VARCHAR(50),
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    WITH CourseStats AS (
        SELECT
            crs.CourseID,
            COUNT(enr.EnrollmentID) AS TotalEnrollments
        FROM Course crs
        LEFT JOIN Enrollment enr
            ON crs.CourseID = enr.CourseID
        GROUP BY crs.CourseID
    )
    SELECT
        crs.CourseID,
        crs.Title,
        crs.[Description],
        crs.Price,
        crs.CourseLevel,
        ctg.CategoryType,
        cc.CreationDate,
        cc.LastUpdateDate,
        usr.FirstName + ' ' + usr.LastName AS InstructorName,
        ISNULL(cs.TotalEnrollments, 0) AS TotalEnrollments
    FROM Course crs
    JOIN Category ctg
        ON crs.CategoryID = ctg.CategoryID
    JOIN CourseCreation cc
        ON crs.CreationID = cc.CreationID
    JOIN SystemUser usr
        ON cc.InstructorID = usr.UserID
    LEFT JOIN CourseStats cs
        ON crs.CourseID = cs.CourseID
    WHERE crs.Title LIKE '%' + @CourseName + '%';

    -- Success / No Data message
    IF @@ROWCOUNT = 0
        SET @ResultMessage = 'No courses found matching the given name.';
    ELSE
        SET @ResultMessage = 'Success';
END;