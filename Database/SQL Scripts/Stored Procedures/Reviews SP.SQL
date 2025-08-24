-- sp_AddReview
CREATE PROCEDURE sp_AddReview
    @StudentID INT,
    @CourseID INT,
    @Rating INT,
    @Comment NVARCHAR(MAX) = NULL,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Check Rating
        IF @Rating NOT BETWEEN 1 AND 5
        BEGIN
            SET @ResultMessage = 'Failed: Rating must be between 1 and 5.';
            RETURN;
        END

        -- Prevent multiple reviews by the same student for the same course
        IF EXISTS (SELECT 1 FROM Review WHERE StudentID = @StudentID AND CourseID = @CourseID)
        BEGIN
            SET @ResultMessage = 'Failed: You have already reviewed this course.';
            RETURN;
        END

        -- Insert review
        INSERT INTO Review (StudentID, CourseID, Rating, Comment, CreatedAt)
        VALUES (@StudentID, @CourseID, @Rating, @Comment, GETDATE());

        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
-----------------------------------------------------------------------------
-- sp_GetReviewsByCourse
CREATE PROCEDURE sp_GetReviewsByCourse
    @CourseID INT,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.ReviewID,
        r.StudentID,
        su.FirstName + ' ' + su.LastName AS StudentName,
        r.Rating,
        r.Comment,
        r.CreatedAt
    FROM Review r
    JOIN SystemUser su ON r.StudentID = su.UserID
    WHERE r.CourseID = @CourseID
    ORDER BY r.CreatedAt DESC;

    SET @ResultMessage = 'Success';
END;
---------------------------------------------------------------------------
-- sp_DeleteReview
CREATE PROCEDURE sp_DeleteReview
    @ReviewID INT,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Review WHERE ReviewID = @ReviewID)
        BEGIN
            SET @ResultMessage = 'Failed: Review does not exist.';
            RETURN;
        END

        DELETE FROM Review
        WHERE ReviewID = @ReviewID;

        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
--------------------------------------------------------------------------------------------------
-- sp_UpdateReview
CREATE PROCEDURE sp_UpdateReview
    @ReviewID INT,
    @Rating INT = NULL,
    @Comment NVARCHAR(MAX) = NULL,
    @ResultMessage VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Check if review exists
        IF NOT EXISTS (SELECT 1 FROM Review WHERE ReviewID = @ReviewID)
        BEGIN
            SET @ResultMessage = 'Failed: Review does not exist.';
            RETURN;
        END

        -- Validate rating if provided
        IF @Rating IS NOT NULL AND (@Rating < 1 OR @Rating > 5)
        BEGIN
            SET @ResultMessage = 'Failed: Rating must be between 1 and 5.';
            RETURN;
        END

        -- Update the review
        UPDATE Review
        SET
            Rating = COALESCE(@Rating, Rating),
            Comment = COALESCE(@Comment, Comment)
        WHERE ReviewID = @ReviewID;

        SET @ResultMessage = 'Success';
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;