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
        crs.[State],
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
-- sp_GetAllAvailableCourses
CREATE PROCEDURE sp_GetAllAvailableCourses
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if there are approved courses
    IF NOT EXISTS (SELECT 1 FROM Course WHERE [State] = 'Approved')
    BEGIN
        SET @ResultMessage = 'No approved courses found.';
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
    WHERE crs.[State] = 'Approved';

    -- Success message
    SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------------------
-- sp_GetAllUnAvailableCourses
CREATE PROCEDURE sp_GetAllUnAvailableCourses
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if there are unavailable courses
    IF NOT EXISTS (SELECT 1 FROM Course WHERE [State] <> 'Approved')
    BEGIN
        SET @ResultMessage = 'No unavailable courses found.';
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
        crs.[State],
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
    WHERE crs.[State] <> 'Approved';

    -- Success message
    SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------------------
-- sp_GetAllPendingCourses
CREATE PROCEDURE sp_GetAllPendingCourses
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if there are pending courses
    IF NOT EXISTS (SELECT 1 FROM Course WHERE [State] = 'Pending')
    BEGIN
        SET @ResultMessage = 'No pending courses found in the system.';
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
        crs.[State],
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
    WHERE crs.[State] = 'Pending';

    -- Success message
    SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------------------
-- sp_GetAllRejectedCourses
CREATE PROCEDURE sp_GetAllRejectedCourses
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if there are rejected courses
    IF NOT EXISTS (SELECT 1 FROM Course WHERE [State] = 'Rejected')
    BEGIN
        SET @ResultMessage = 'No rejected courses found in the system.';
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
        crs.[State],
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
    WHERE crs.[State] = 'Rejected';

    -- Success message
    SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------------------------
-- sp_GetAllRemovedCourses
CREATE PROCEDURE sp_GetAllRemovedCourses
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if there are removed courses
    IF NOT EXISTS (SELECT 1 FROM Course WHERE [State] = 'Removed')
    BEGIN
        SET @ResultMessage = 'No removed courses found in the system.';
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
        crs.[State],
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
    WHERE crs.[State] = 'Removed';

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
        crs.[State],
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
    IF NOT EXISTS (
        SELECT 1
        FROM CourseCreation
        WHERE InstructorID = @InstructorID
    )
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
        crs.[State],
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
        crs.[State],
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
        crs.[State],
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
-----------------------------------------------------------------------------------------
-- sp_CreateCourse
CREATE PROCEDURE sp_CreateCourse
    @InstructorID INT,
    @Title VARCHAR(100),
    @Description VARCHAR(MAX),
    @Price DECIMAL(10, 2),
    @CourseLevel VARCHAR(50),
    @CategoryID INT,
    @NewCourseID INT OUTPUT,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @CreationID INT;

        -- Create record in CourseCreation
        INSERT INTO CourseCreation (CreationDate, LastUpdateDate, InstructorID)
        VALUES (GETDATE(), GETDATE(), @InstructorID);

        SET @CreationID = SCOPE_IDENTITY();

        -- Insert new course
        INSERT INTO Course (Title, [Description], Price, CourseLevel, CategoryID, CreationID)
        VALUES (@Title, @Description, @Price, @CourseLevel, @CategoryID, @CreationID);

        SET @NewCourseID = SCOPE_IDENTITY();

        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Failed: ' + ERROR_MESSAGE();
        SET @NewCourseID = NULL;
    END CATCH
END;
-----------------------------------------------------------------------------------------
-- sp_UpdateCourse
CREATE PROCEDURE sp_UpdateCourse
    @CourseID INT,
    @Title VARCHAR(100),
    @Description VARCHAR(MAX),
    @Price DECIMAL(10, 2),
    @CourseLevel VARCHAR(50),
    @CategoryID INT,
    @State VARCHAR(50),
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the course exists
    IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID)
    BEGIN
        SET @ResultMessage = 'Failed: Course not found';
        RETURN;
    END

    BEGIN TRY
        -- Update only course info
        UPDATE Course
        SET
            Title = @Title,
            [Description] = @Description,
            Price = @Price,
            CourseLevel = @CourseLevel,
            CategoryID = @CategoryID,
            [State] = @State
        WHERE CourseID = @CourseID;

        -- Success
        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Failed: ' + ERROR_MESSAGE();
    END CATCH
END;
-----------------------------------------------------------------------------------------
-- sp_DeleteCourse
CREATE PROCEDURE sp_DeleteCourse
    @CourseID INT,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the course exists
    IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID)
    BEGIN
        SET @ResultMessage = 'Failed: Course not found';
        RETURN;
    END

    -- Check if already removed
    IF EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID AND [State] = 'Removed')
    BEGIN
        SET @ResultMessage = 'Failed: Course already removed';
        RETURN;
    END

    BEGIN TRY
        -- Update course state to removed
        UPDATE Course
        SET
            [State] = 'Removed'
        WHERE CourseID = @CourseID;

        -- Success
        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Failed: ' + ERROR_MESSAGE();
    END CATCH
END;