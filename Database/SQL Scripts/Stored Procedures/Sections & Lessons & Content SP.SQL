-- sp_CreateSection
CREATE PROCEDURE sp_CreateSection
    @CourseID INT,
    @SectionTitle VARCHAR(100),
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Check if course exists
        IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID AND [State] = 'Approved')
        BEGIN
            SET @ResultMessage = 'Course not found or not approved.';
            RETURN;
        END;

        -- Insert Section
        INSERT INTO Section (Title, CourseID)
        VALUES (@SectionTitle, @CourseID);

        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
----------------------------------------------------------------------------
-- sp_CreateLesson
CREATE PROCEDURE sp_CreateLesson
    @SectionID INT,
    @LessonTitle VARCHAR(100),
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Check if Section exists
        IF NOT EXISTS (SELECT 1 FROM Section WHERE SectionID = @SectionID)
        BEGIN
            SET @ResultMessage = 'Section not found.';
            RETURN;
        END;

        -- Insert Lesson
        INSERT INTO Lesson (Title, SectionID)
        VALUES (@LessonTitle, @SectionID);

        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
-------------------------------------------------------------------------------
-- sp_AddContentToLesson
CREATE PROCEDURE sp_AddContentToLesson
    @LessonID INT,
    @ContentType VARCHAR(20),  -- 'TXT', 'PDF', or 'Video'
    @ContentPath VARCHAR(255),  -- path of the file on your server/folder
    @ContentID INT OUTPUT,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validate ContentType
        IF @ContentType NOT IN ('TXT', 'PDF', 'Video')
        BEGIN
            SET @ResultMessage = 'Invalid content type. Must be TXT, PDF, or Video.';
            SET @ContentID = NULL;
            RETURN;
        END

        -- Insert content
        INSERT INTO Content (ContentType, ContentData)
        VALUES (@ContentType, @ContentPath);

        -- Get the new ContentID
        SET @ContentID = SCOPE_IDENTITY();

        -- Link to lesson
        INSERT INTO LessonContent (LessonID, ContentID)
        VALUES (@LessonID, @ContentID);

        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ContentID = NULL;
        SET @ResultMessage = 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
------------------------------------------------------------------
-- sp_GetLessonsBySection
CREATE PROCEDURE sp_GetLessonsBySection
    @SectionID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        LessonID,
        Title AS LessonTitle
    FROM Lesson
    WHERE SectionID = @SectionID
    ORDER BY LessonID;
END;
--------------------------------------------------------------------
-- sp_GetSectionsByCourse
CREATE PROCEDURE sp_GetSectionsByCourse
    @CourseID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        SectionID,
        Title AS SectionTitle
    FROM Section
    WHERE CourseID = @CourseID
    ORDER BY SectionID;
END;
-----------------------------------------------------------------------
-- sp_GetContentByLesson
CREATE PROCEDURE sp_GetContentByLesson
    @LessonID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        lc.ContentID,
        c.ContentType,
        c.ContentData
    FROM LessonContent lc
    JOIN Content c ON lc.ContentID = c.ContentID
    WHERE lc.LessonID = @LessonID
    ORDER BY lc.ContentID;
END;
---------------------------------------------------------------------
-- sp_DeleteLessonContent
CREATE PROCEDURE sp_DeleteLessonContent
    @LessonID INT,
    @ContentID INT = NULL -- if want to remove only one content
AS
BEGIN
    SET NOCOUNT ON;

    IF @ContentID IS NULL
    BEGIN
        -- remove all
        DELETE FROM LessonContent
        WHERE LessonID = @LessonID;
    END
    ELSE
    BEGIN
        -- remove one
        DELETE FROM LessonContent
        WHERE LessonID = @LessonID
          AND ContentID = @ContentID;
    END
END;
------------------------------------------------------------------------
-- Update the title of the lesson

-- sp_UpdateLesson
CREATE PROCEDURE sp_UpdateLesson
    @LessonID INT,
    @NewTitle VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Lesson
    SET Title = @NewTitle
    WHERE LessonID = @LessonID;
END;
----------------------------------------------------------------------
-- sp_DeleteLesson
CREATE PROCEDURE sp_DeleteLesson
    @LessonID INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Delete all contents linked to this lesson
        DELETE FROM Content con
        JOIN LessonContent lc ON con.ContentID = lc.ContentID
        WHERE lc.LessonID = @LessonID;

        -- Delete the links between the lesson and its contents
        DELETE FROM LessonContent
        WHERE LessonID = @LessonID;

        -- Delete the lesson itself
        DELETE FROM Lesson
        WHERE LessonID = @LessonID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW; -- Raise the error
    END CATCH
END;
----------------------------------------------------------------------------
-- sp_UpdateCourseProgress
CREATE PROCEDURE sp_UpdateCourseProgress
    @StudentID INT,
    @LessonID INT = NULL,
    @QuizID INT = NULL,
    @IsCompleted BIT = 1,
    @CompletionPercentage DECIMAL(5,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Update lesson progress if LessonID is provided
        IF @LessonID IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM StudentLessonProgress
                       WHERE StudentID = @StudentID AND LessonID = @LessonID)
            BEGIN
                UPDATE StudentLessonProgress
                SET IsCompleted = @IsCompleted
                WHERE StudentID = @StudentID AND LessonID = @LessonID;
            END
            ELSE
            BEGIN
                INSERT INTO StudentLessonProgress (StudentID, LessonID, IsCompleted)
                VALUES (@StudentID, @LessonID, @IsCompleted);
            END
        END

        -- Update quiz progress if QuizID is provided
        IF @QuizID IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM StudentQuizProgress
                       WHERE StudentID = @StudentID AND QuizID = @QuizID)
            BEGIN
                UPDATE StudentQuizProgress
                SET IsPassed = @IsCompleted
                WHERE StudentID = @StudentID AND QuizID = @QuizID;
            END
            ELSE
            BEGIN
                INSERT INTO StudentQuizProgress (StudentID, QuizID, IsPassed)
                VALUES (@StudentID, @QuizID, @IsCompleted);
            END
        END

        -- Determine the course ID
        DECLARE @CourseID INT;

        IF @LessonID IS NOT NULL
            SELECT @CourseID = s.CourseID
            FROM Lesson l
            JOIN Section s ON l.SectionID = s.SectionID
            WHERE l.LessonID = @LessonID;

        IF @QuizID IS NOT NULL
            SELECT @CourseID = s.CourseID
            FROM Quiz q
            JOIN Section s ON q.SectionID = s.SectionID
            WHERE q.QuizID = @QuizID;

        -- Calculate total items (lessons + quizzes)
        DECLARE @TotalItems INT;
        SELECT @TotalItems =
            (SELECT COUNT(*) FROM Lesson l JOIN Section s ON l.SectionID = s.SectionID WHERE s.CourseID = @CourseID) +
            (SELECT COUNT(*) FROM Quiz q JOIN Section s ON q.SectionID = s.SectionID WHERE s.CourseID = @CourseID);

        -- Calculate completed items
        DECLARE @CompletedItems INT;
        SELECT @CompletedItems =
            (SELECT COUNT(*) FROM StudentLessonProgress lp
             JOIN Lesson l ON lp.LessonID = l.LessonID
             JOIN Section s ON l.SectionID = s.SectionID
             WHERE lp.StudentID = @StudentID AND lp.IsCompleted = 1 AND s.CourseID = @CourseID)
            +
            (SELECT COUNT(*) FROM StudentQuizProgress qp
             JOIN Quiz q ON qp.QuizID = q.QuizID
             JOIN Section s ON q.SectionID = s.SectionID
             WHERE qp.StudentID = @StudentID AND qp.IsPassed = 1 AND s.CourseID = @CourseID);

        -- Compute completion percentage
        IF @TotalItems > 0
            SET @CompletionPercentage = CAST(@CompletedItems * 100.0 / @TotalItems AS DECIMAL(5,2));
        ELSE
            SET @CompletionPercentage = 0;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
