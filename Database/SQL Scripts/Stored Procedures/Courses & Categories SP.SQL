-- Return all data about courses and also the total enrollments for the course
-- Use LINQ to get all courses OR all courses related (Instractor, Category, State)

-- sp_GetAllCourses
CREATE PROCEDURE sp_GetAllCourses
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
            crs.[State],
            ctg.CategoryType,
            usr.UserID AS InstructorID,
            ISNULL(usr.FirstName, '') + ' ' + ISNULL(usr.LastName, '') AS InstructorName,
            COUNT(enr.EnrollmentID) AS TotalEnrollments
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
            crs.[State],
            ctg.CategoryType,
            usr.UserID,
            usr.FirstName,
            usr.LastName
    )
    SELECT
        CourseID,
        CourseTitle,
        [Description],
        Price,
        [State],
        CategoryType,
        InstructorID,
        InstructorName,
        TotalEnrollments
    FROM
        CoursePopularity

    -- Success / No Data message
    IF @@ROWCOUNT = 0
        SET @ResultMessage = 'No courses found.';
    ELSE
        SET @ResultMessage = 'Success';
END;
--------------------------------------------------------------------------------
-- Used for filltering the the Course by price
-- Use it while searching for courses

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
    WHERE crs.Title LIKE '%' + @CourseName + '%'

    -- Success / No Data message
    IF NOT EXISTS (
        SELECT 1
        FROM Course
        WHERE Title LIKE '%' + @CourseName + '%'
          AND [State] <> 'REMOVED'
    )
        SET @ResultMessage = 'Failed: No courses found matching the given name.';
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

        -- Validate instructor
        IF NOT EXISTS (
            SELECT 1
            FROM SystemUser usr
            INNER JOIN Role r ON usr.RoleID = r.RoleID
            WHERE usr.UserID = @InstructorID
              AND r.RoleName = 'INSTRUCTOR'
              AND usr.[State] = 'AVAILABLE'
        )
        BEGIN
            SET @ResultMessage = 'Failed: Invalid or unavailable instructor.';
            SET @NewCourseID = NULL;
            RETURN;
        END;

        -- Create record in CourseCreation
        INSERT INTO CourseCreation (CreationDate, LastUpdateDate, InstructorID)
        VALUES (GETDATE(), GETDATE(), @InstructorID);

        SET @CreationID = SCOPE_IDENTITY();

        -- Insert new course with default state = PENDING
        INSERT INTO Course (Title, [Description], Price, CourseLevel, CategoryID, CreationID, [State])
        VALUES (@Title, @Description, @Price, @CourseLevel, @CategoryID, @CreationID, 'PENDING');

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
    @Title VARCHAR(100) = NULL,
    @Description VARCHAR(MAX) = NULL,
    @Price DECIMAL(10, 2) = NULL,
    @CourseLevel VARCHAR(50) = NULL,
    @CategoryID INT = NULL,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the course exists and not removed
    IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID AND [State] <> 'REMOVED')
    BEGIN
        SET @ResultMessage = 'Failed: Course not found or removed';
        RETURN;
    END

    BEGIN TRY
        -- Update only the provided fields
        UPDATE Course
        SET
            Title = ISNULL(@Title, Title),
            [Description] = ISNULL(@Description, [Description]),
            Price = ISNULL(@Price, Price),
            CourseLevel = ISNULL(@CourseLevel, CourseLevel),
            CategoryID = ISNULL(@CategoryID, CategoryID)
        WHERE CourseID = @CourseID;

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
    IF EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID AND [State] = 'REMOVED')
    BEGIN
        SET @ResultMessage = 'Failed: Course already removed';
        RETURN;
    END

    BEGIN TRY
        -- Soft delete course
        UPDATE Course
        SET [State] = 'REMOVED'
        WHERE CourseID = @CourseID;

        -- Success
        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Failed: ' + ERROR_MESSAGE();
    END CATCH
END;